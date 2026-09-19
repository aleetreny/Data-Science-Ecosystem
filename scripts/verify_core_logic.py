#!/usr/bin/env python3
"""Behavioral checks of notebook code, without downloads or full model training.

Run with the Python environment in RUNNING.md. Definitions are compiled from
notebook cells, so these checks exercise the maintained implementations.
"""
from __future__ import annotations

import ast
import contextlib
import csv
import io
import json
import os
import re
import tempfile
import warnings
from pathlib import Path

os.environ.setdefault('MPLBACKEND', 'Agg')
os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '2')
import numpy as np
import pandas as pd
import torch
from torch import nn

ROOT = Path(__file__).resolve().parents[1]
torch.set_num_threads(2)


def cells(project):
    paths = list((ROOT / project).glob('*.ipynb'))
    assert len(paths) == 1, paths
    return json.loads(paths[0].read_text())['cells']


def load_definitions(project, indices, namespace=None):
    ns = {'np': np, 'pd': pd, 'torch': torch, 'nn': nn, 'os': os, 'SEED': 42}
    if namespace:
        ns.update(namespace)
    source_cells = cells(project)
    for i in indices:
        tree = ast.parse(''.join(source_cells[i]['source']))
        tree.body = [n for n in tree.body if isinstance(n, (ast.FunctionDef, ast.ClassDef))]
        exec(compile(tree, f'{project}:cell{i}', 'exec'), ns)
    return ns


def raises(error, function, *args, **kwargs):
    try:
        function(*args, **kwargs)
    except error:
        return
    raise AssertionError(f'{function.__name__} did not raise {error}')


def test_numeric_runtime():
    rng = np.random.default_rng(901)
    # Independent scalar summation catches faulty BLAS/matmul behavior.
    with warnings.catch_warnings():
        warnings.simplefilter('error', RuntimeWarning)
        for size in (40, 128, 784):
            a, b = rng.normal(size=(size, 9)), rng.normal(size=(9, 7))
            expected = np.einsum('ik,kj->ij', a, b, optimize=False)
            np.testing.assert_allclose(a @ b, expected, atol=1e-11, rtol=1e-11)
        weights = np.full(10000, 1/10000)
        np.testing.assert_allclose(np.vecdot(weights, weights), 1/10000)


def test_trading_accounting():
    from gym_anytrading.envs import StocksEnv, Actions, Positions
    from sklearn.preprocessing import StandardScaler
    ns = load_definitions('Deep Q-Trading', [5], locals())
    df = pd.DataFrame({'Close': [100., 100., 100., 110., 99., 99.], 'Volume': [1.] * 6})
    scaler = StandardScaler().fit(df)
    env = ns['CryptoEnv'](df, 2, (2, len(df)), scaler)
    observation, _ = env.reset(seed=7)
    np.testing.assert_allclose(scaler.inverse_transform(observation)[-1, 0], 100)
    total_reward = 0
    # Entry, two-sided reversal, final liquidation: four charged sides.
    for action in (Actions.Buy.value, Actions.Sell.value, Actions.Sell.value):
        _, reward, terminated, truncated, _ = env.step(action)
        total_reward += reward
    expected = 1.1 * 1.1 * 0.999 ** 4
    np.testing.assert_allclose(env._total_profit, expected)
    np.testing.assert_allclose(np.exp(total_reward), expected)
    assert terminated or truncated
    raises(ValueError, env._net_log_return, 2)
    env.prices = env.prices.copy()
    env.prices[env._current_tick] = 3 * env.prices[env._current_tick - 1]
    raises(ValueError, env._net_log_return, Actions.Sell.value)
    env.close()


def test_cellular_simulations():
    from scipy.signal import convolve2d
    class Rolls:
        def __init__(self, values):
            self.values = iter(values)
            self.calls = 0
        def random(self, shape):
            self.calls += 1
            return np.full(shape, next(self.values))
    kernel = np.ones((3, 3), dtype=int)
    kernel[1, 1] = 0
    ns = load_definitions('Epidemic Dynamics Simulation', [12, 32],
        dict(convolve2d=convolve2d, kernel=kernel, HUMAN=0, ZOMBIE=1, DEAD=2,
             ALPHA=1., BETA=1., rng=Rolls([0., 0.])))
    grid = np.zeros((5, 5), dtype=int)
    grid[2, 2] = 1
    grid[0, 0] = 2
    new = ns['simulation_step'](grid)
    assert new[2, 2] == 2 and np.sum(new == 1) == 8 and new[0, 0] == 2
    assert grid[2, 2] == 1 and ns['rng'].calls == 2  # Input not overwritten.
    rolls = Rolls([0.1, 0.9, 0.9])
    new = ns['complex_simulation_step'](grid, 0, np.zeros_like(grid), rolls)
    assert rolls.calls == 3 and np.sum(new == 1) == 9
    assert new.size == sum(np.sum(new == state) for state in (0, 1, 2))

    ns = load_definitions('Physarum Polycephalum Simulation', [5],
        dict(WIDTH=5, HEIGHT=5, NUM_AGENTS=2, SENSOR_ANGLE=0., TURN_ANGLE=0.,
             SENSOR_DIST=1., DECAY_RATE=.95, DIFFUSION_RATE=.2,
             rng=np.random.default_rng(42)))
    trail, x, y, _ = ns['run_step'](np.zeros((5, 5)), np.array([4.2, 4.2]),
                                   np.array([0.2, 0.2]), np.zeros(2))
    np.testing.assert_allclose(trail.sum(), 1.9)  # Both colliding agents deposit.
    assert np.all((x >= 0) & (x < 5)) and trail[0, 4] > 0 and trail[4, 0] > 0
    assert (trail >= 0).all()

    ns = load_definitions('Turing Patterns', [6, 10])
    u, v = np.ones((5, 7)), np.zeros((5, 7))
    np.testing.assert_array_equal(ns['laplacian_periodic'](u, 1.), 0)
    impulse = v.copy(); impulse[0, 0] = 1
    lap = ns['laplacian_periodic'](impulse, 1.)
    assert lap.sum() == 0 and lap[-1, 0] == 1 and lap[0, -1] == 1
    params = dict(Du=.16, Dv=.08, F=.035, k=.065, dx=1., dt=1.)
    un, vn = ns['step_gray_scott'](u, v, **params)
    np.testing.assert_array_equal(un, u); np.testing.assert_array_equal(vn, v)
    raises(ValueError, ns['step_gray_scott'], u*.5, u*.25, **(params | {'dt': 1000.}))


def test_steganography():
    from PIL import Image
    ns = load_definitions('Steganography', [5])
    rng = np.random.default_rng(123)
    cover, secret = [rng.integers(0, 256, (17, 19, 3), dtype=np.uint8) for _ in range(2)]
    originals = (cover.copy(), secret.copy())
    for bits in range(1, 9):
        stego = ns['hide_image'](cover, secret, bits)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'roundtrip.png'
            Image.fromarray(stego).save(path)
            restored = np.asarray(Image.open(path))
            revealed = ns['reveal_image'](restored, bits)
        quantum = 2 ** (8 - bits)
        np.testing.assert_array_equal(revealed, (secret // quantum) * quantum)
        assert np.max(np.abs(stego.astype(int) - cover.astype(int))) <= 2**bits - 1
    np.testing.assert_array_equal(cover, originals[0]); np.testing.assert_array_equal(secret, originals[1])
    for bits in (0, 9, 1.5):
        raises(ValueError, ns['hide_image'], cover, secret, bits)
    raises(ValueError, ns['hide_image'], cover.astype(float), secret)
    raises(ValueError, ns['hide_image'], cover, secret[:1])


def test_neuroevolution():
    from torch.nn.utils import parameters_to_vector, vector_to_parameters
    ns = load_definitions('Stochastic Optimization via Neuroevolution', [3, 5, 7], locals())
    agent = ns['NeuroController'](8, 64, 4)
    original_state = torch.random.get_rng_state().clone()
    first = ns['get_random_genotype'](agent, 3)
    assert torch.equal(torch.random.get_rng_state(), original_state)
    assert torch.equal(first, ns['get_random_genotype'](agent, 3))
    assert not torch.equal(first, ns['get_random_genotype'](agent, 4))
    population = ns['init_population'](5, agent)
    new = ns['create_next_generation'](population, torch.arange(5.), elitism_count=2)
    assert torch.equal(new[0], population[4]) and torch.equal(new[1], population[3])
    child = ns['crossover'](torch.zeros(200), torch.ones(200))
    assert set(child.tolist()) == {0., 1.}
    assert torch.equal(ns['mutate'](first, mutation_power=0), first)
    agent.set_genotype(first)
    assert torch.equal(agent.get_genotype(), first)


def test_flow_density():
    ns = load_definitions('CERN OpenLab/Neural Phase Integration', [7, 9, 17, 19],
                          dict(DOMAIN_LOW=-5., DOMAIN_HIGH=5.))
    torch.manual_seed(33)
    layer = ns['AffineCouplingLayer'](4, [1, 0, 1, 0], hidden_dim=8).double()
    z = torch.randn(4, dtype=torch.double)
    result, logdet = layer(z[None])
    recovered, inverse_logdet = layer.inverse(result)
    torch.testing.assert_close(recovered, z[None])
    torch.testing.assert_close(logdet, -inverse_logdet)
    jacobian = torch.autograd.functional.jacobian(lambda x: layer(x[None])[0][0], z)
    torch.testing.assert_close(torch.linalg.slogdet(jacobian)[1], logdet[0])
    # An exactly known identity-flow density provides an independent integration target.
    from scipy.stats import norm
    class Target:
        dim = 4
        def log_prob(self, x):
            return torch.distributions.Normal(0., 1.).log_prob(x).sum(dim=1)
    base = torch.distributions.MultivariateNormal(torch.zeros(4), torch.eye(4))
    model = ns['NormalizingFlow'](base, [])
    estimate, se, samples, ess = ns['evaluate_balanced_flow'](model, Target(), 30000)
    truth = (norm.cdf(5) - norm.cdf(-5)) ** 4
    assert abs(estimate - truth) < 5 * se and 0 < ess <= 1
    assert np.isfinite(samples).all()
    raises(ValueError, ns['evaluate_balanced_flow'], model, Target(), 1)


def test_gan_inference():
    ns = load_definitions('Generative Adversarial Networks', [6],
                          dict(NOISE_DIM=100, IMAGE_SIZE=32, CHANNELS=1))
    generator, discriminator = ns['Generator'](), ns['Discriminator']()
    generator.apply(ns['weights_init'])
    generator.eval(); discriminator.eval()
    before = {name: tensor.clone() for name, tensor in generator.named_buffers()}
    noise = torch.randn(4, 100, 1, 1)
    with torch.no_grad():
        images = generator(noise)
        scores = discriminator(images)
        torch.testing.assert_close(generator(noise[:1])[0], images[0], atol=1e-6, rtol=1e-5)
    assert images.shape == (4, 1, 32, 32) and scores.shape == (4, 1, 1, 1)
    assert torch.isfinite(images).all() and images.abs().max() <= 1
    assert all(torch.equal(before[name], tensor) for name, tensor in generator.named_buffers())


def test_lyric_metrics():
    import importlib.util
    directory = ROOT / 'Spotify EDA and Random Forest/Music_evolution'
    spec = importlib.util.spec_from_file_location('lyric_metrics', directory / 'scripts/recompute_metrics.py')
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    metrics = module.lyric_metrics('[Chorus]\nlove love happiness', 2.)
    assert metrics['Total Words'] == 3 and metrics['Lexical Richness (%)'] == 66.67
    assert metrics['Words per Minute'] == 1.5
    assert np.isnan(module.lyric_metrics(None, 2.)['Polarity'])
    raises(ValueError, module.lyric_metrics, 'hello', 0.)
    for path in directory.glob('*.csv'):
        data = pd.read_csv(path)
        present = data['Words per Minute'].notna()
        np.testing.assert_allclose(data.loc[present, 'Words per Minute'],
            (data.loc[present, 'Total Words'] / data.loc[present, 'Duration (min)']).round(2))
        assert data['Polarity'].dropna().between(-1, 1).all()
        assert data['Subjectivity'].dropna().between(0, 1).all()
        assert data['Lexical Richness (%)'].dropna().between(0, 100).all()


def test_quantum_edges():
    from torch_geometric.data import Data
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import roc_auc_score, roc_curve
    import torch.optim as optim
    ns = load_definitions('CERN OpenLab/Quantum GNN Tracking', [9, 13, 15], locals())
    hits = pd.DataFrame({'r':[100., 120., 140., 160.], 'phi':[0.] * 4,
                         'z':[0.] * 4, 'particle_id':[0, 0, 7, 7]})
    graph = ns['build_graph_geometric_constraints'](hits)
    assert graph.num_edges == 6 and int(graph.y.sum()) == 1
    src, dst = graph.edge_index[:, graph.y.bool()]
    assert (src.item(), dst.item()) == (2, 3)  # Noise PID 0 never forms truth edges.
    classifier = ns['InteractionGNN'](hidden_dim=8)
    assert classifier(graph).shape == (6,)
    assert classifier(graph, torch.tensor([4])).shape == (1,)
    data = Data(x=torch.zeros(40, 3), edge_index=torch.zeros((2, 40), dtype=torch.long),
                y=torch.tensor([0., 1.] * 20))
    train, test = ns['make_edge_split'](data)
    assert not set(train.tolist()) & set(test.tolist())
    assert len(train) + len(test) == 40
    class Spy(nn.Module):
        def __init__(self):
            super().__init__(); self.weight = nn.Parameter(torch.tensor(0.)); self.calls = []
        def forward(self, data, edge_indices):
            self.calls.append((self.training, edge_indices.clone()))
            return self.weight.sigmoid().expand(len(edge_indices))
    spy = Spy()
    ns['train_and_evaluate'](spy, data, train, test, epochs=2)
    assert all(training and torch.equal(idx, train) for training, idx in spy.calls[:-1])
    assert not spy.calls[-1][0] and torch.equal(spy.calls[-1][1], test)


def test_weight_quantization():
    import tensorflow as tf
    from tensorflow.keras import layers, models
    ns = load_definitions('CERN OpenLab/Extreme-Scale Anomaly Detection', [14, 16], locals())
    model = models.Sequential([layers.Input(shape=(3,)), ns['QuantizedDense'](2, bits=6),
                              ns['QuantizedDense'](1, bits=8)])
    weights = np.array([[-2., -.15], [.01, .25], [.8, 2.]], dtype=np.float32)
    bias = np.array([-2., 2.], dtype=np.float32)
    model.layers[0].set_weights([weights, bias])
    layer = model.layers[0]
    expected_w = np.clip(np.rint(weights * 32), -32, 31) / 32
    expected_b = np.array([-1., 31/32])
    np.testing.assert_allclose(layer(np.ones((1, 3))).numpy(), expected_w.sum(0)[None] + expected_b)
    with tf.GradientTape() as tape:
        result = tf.reduce_sum(layer(tf.ones((1, 3))))
    np.testing.assert_allclose(tape.gradient(result, layer.w).numpy(), 1.)
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / 'parameters.h'
        ns['generate_hls_header'](model, str(path))
        text = path.read_text()
        for index, layer in enumerate(model.layers, 1):
            assert f'ap_fixed<{layer.bits},1> weight_{index}_t' in text
            scale = 2 ** (layer.bits - 1)
            for prefix, values in zip(('w', 'b'), layer.get_weights()):
                match = re.search(r'\b' + prefix + str(index) + r'\[\d+\] = \{([^}]+)', text)
                exported = np.fromstring(match[1].replace('\n', ''), sep=',')
                expected = np.clip(np.rint(values * scale), -scale, scale - 1) / scale
                np.testing.assert_allclose(exported, expected.ravel(), atol=1e-8, rtol=0)
    assert ns['float_to_fixed_point'](-100) == -32
    assert ns['float_to_fixed_point'](100) == 31


def test_optimization_against_independent_solvers():
    import random
    import gurobipy as gp
    from scipy.optimize import linprog
    gp.setParam('OutputFlag', 0)
    ns = {'np': np, 'random': random}
    source = cells('Optimization and Regression Modeling/Linear Programming')
    for i in (0, 11):
        exec(''.join(source[i]['source']), ns)
    independent = linprog(-np.array(ns['r']), A_eq=np.array([ns['a1'], ns['a2']]), b_eq=[30, 50], bounds=(0, None))
    assert independent.success
    np.testing.assert_allclose(-independent.fun, ns['m'].ObjVal)
    exec(''.join(source[16]['source']), ns)
    design, target = ns['design'], np.array(ns['height'])
    n = len(target)
    result = linprog(np.r_[np.zeros(3), np.ones(n)],
                     A_ub=np.vstack([np.c_[design, -np.eye(n)], np.c_[-design, -np.eye(n)]]),
                     b_ub=np.r_[target, -target], bounds=[(None, None)] * 3 + [(0, None)] * n)
    assert result.success
    np.testing.assert_allclose(result.fun, ns['m'].ObjVal)
    np.testing.assert_allclose(result.x[:3], ns['beta_fit'], atol=1e-7)

    source = cells('Optimization and Regression Modeling/Mixed Integer Linear Programming')
    ns = {}
    for i in (2, 4, 6, 8, 10, 12, 14):
        exec(''.join(source[i]['source']), ns)
    quantities = np.stack(np.meshgrid(*([np.arange(61)] * 3), indexing='ij'), axis=-1).reshape(-1, 3)
    capacities = np.array([ns['b'][i] for i in ns['resources']])
    resources = quantities @ np.array([[ns['a'][i][j] for j in ns['products']] for i in ns['resources']]).T
    # Direct piecewise revenue, independent of the MILP's binary segment encoding.
    q1, q2, q3 = quantities.T
    revenue = (4*np.minimum(q1, 10) + 3*np.maximum(q1-10, 0)
               + 6*np.minimum(q2, 8) + 4*np.maximum(q2-8, 0)
               + 5*np.minimum(q3, 10) + 2.5*np.minimum(np.maximum(q3-10, 0), 10)
               + np.maximum(q3-20, 0))
    profit = revenue - (quantities > 0) @ np.array([40, 50, 45])
    for extra in (0, 1, 12, 13, 100):
        cap = capacities.copy(); cap[3] += extra
        feasible = (resources <= cap).all(1) & ((q3 == 0) | (q1 > 0))
        optimum = profit[feasible].max()
        scenario = ns['model'].copy(); scenario.Params.OutputFlag = 0
        scenario.getConstrByName('R2_Resources[4]').RHS = float(cap[3])
        scenario.optimize()
        assert scenario.Status == gp.GRB.OPTIMAL
        np.testing.assert_allclose(scenario.ObjVal, optimum)
        scenario.dispose()
    np.testing.assert_allclose(ns['model'].ObjVal, 284.)


def test_source_artifacts():
    from IPython.core.inputtransformer2 import TransformerManager
    transformer = TransformerManager()
    for path in ROOT.rglob('*.ipynb'):
        if any(p in {'.audit', '.venv', '.ipynb_checkpoints'} for p in path.parts):
            continue
        notebook = json.loads(path.read_text())
        for index, cell in enumerate(notebook['cells']):
            if cell['cell_type'] == 'code':
                ast.parse(transformer.transform_cell(''.join(cell['source'])))
            assert not any(o.get('output_type') == 'error' for o in cell.get('outputs', [])), (path, index)
    for path in (ROOT / 'Spotify EDA and Random Forest/Music_evolution').glob('*.csv'):
        with path.open(encoding='utf-8-sig', newline='') as handle:
            assert 'Lyrics' not in next(csv.reader(handle)), path


def main():
    tests = [test_numeric_runtime, test_trading_accounting, test_cellular_simulations,
             test_steganography, test_neuroevolution, test_flow_density, test_gan_inference,
             test_lyric_metrics,
             test_quantum_edges, test_weight_quantization,
             test_optimization_against_independent_solvers, test_source_artifacts]
    for test in tests:
        with contextlib.redirect_stdout(io.StringIO()):
            test()
        print(f'PASS {test.__name__}', flush=True)
    print(f'{len(tests)} behavioral/artifact check groups passed.')


if __name__ == '__main__':
    main()
