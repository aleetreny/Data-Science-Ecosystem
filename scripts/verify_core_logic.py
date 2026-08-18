#!/usr/bin/env python3
"""Fast, dependency-light regression checks for review-backed fixes."""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]


def notebook_source(relative_path: str, cell: int) -> str:
    with (ROOT / relative_path).open(encoding="utf-8") as handle:
        return "".join(json.load(handle)["cells"][cell]["source"])


def assert_contains(value: str, expected: str) -> None:
    assert expected in value, f"Missing expected source: {expected!r}"


def test_notebook_fixes() -> None:
    gan = notebook_source("Generative Adversarial Networks/notebook.ipynb", 8)
    assert_contains(gan, "netG.eval()")
    assert_contains(gan, "final_fake_batch")
    gan_imports = notebook_source("Generative Adversarial Networks/notebook.ipynb", 2)
    assert_contains(gan_imports, "from matplotlib import animation")
    assert_contains(gan_imports, "from IPython.display import HTML")

    epidemic = notebook_source("Epidemic Dynamics Simulation/simulation.ipynb", 32)
    assert_contains(epidemic, "rng.random")
    assert_contains(epidemic, "np.clip(current_alpha")
    assert_contains(epidemic, "~infection_trigger")

    physarum = notebook_source("Physarum Polycephalum Simulation/notebook.ipynb", 5)
    assert_contains(physarum, "np.add.at")
    assert_contains(physarum, "% WIDTH")
    assert_contains(physarum, "DIFFUSION_RATE")

    namespace = {
        "np": np,
        "WIDTH": 5,
        "HEIGHT": 5,
        "NUM_AGENTS": 2,
        "SENSOR_ANGLE": np.pi / 4,
        "TURN_ANGLE": np.pi / 4,
        "SENSOR_DIST": 1,
        "DECAY_RATE": 0.95,
        "DIFFUSION_RATE": 0.2,
        "rng": np.random.default_rng(42),
    }
    exec(physarum, namespace)
    trail = np.zeros((5, 5), dtype=float)
    x = np.array([1.1, 1.1])
    y = np.array([1.1, 1.1])
    angles = np.zeros(2)
    trail, *_ = namespace["run_step"](trail, x, y, angles)
    # Diffusion conserves total mass and decay multiplies the two deposits by 0.95.
    assert np.isclose(trail.sum(), 2 * 0.95)

    turing = notebook_source("Turing Patterns/simulation.ipynb", 10)
    assert_contains(turing, "np.clip(U_next, 0.0, None)")

    quantum_loader = notebook_source("CERN OpenLab/Quantum GNN Tracking/notebook.ipynb", 3)
    quantum_notebook = (ROOT / "CERN OpenLab/Quantum GNN Tracking/notebook.ipynb").read_text()
    assert "particles = pd.read_csv" not in quantum_notebook
    assert "hits['pt']" not in quantum_notebook
    assert_contains(quantum_loader, "truth[['hit_id', 'particle_id', 'weight']]")
    quantum_classical = notebook_source("CERN OpenLab/Quantum GNN Tracking/notebook.ipynb", 15)
    assert_contains(quantum_classical, "train_test_split")
    assert_contains(quantum_classical, "out[train_idx]")
    assert_contains(quantum_classical, "data.y[test_idx]")
    quantum_hybrid = notebook_source("CERN OpenLab/Quantum GNN Tracking/notebook.ipynb", 19)
    assert_contains(quantum_hybrid, "out[train_idx]")
    assert_contains(quantum_hybrid, "data.y[test_idx]")


def test_security_and_data_hygiene() -> None:
    spotify = ROOT / "Spotify EDA and Random Forest" / "Music_evolution"
    notebook_text = (spotify / "music_evolution.ipynb").read_text(encoding="utf-8")
    assert "os.getenv(\\\"GENIUS_TOKEN\\\")" in notebook_text
    assert not re.search(r"GENIUS_TOKEN\s*=\s*['\"][^'\"]{20,}", notebook_text)
    for csv_path in spotify.glob("*.csv"):
        with csv_path.open(encoding="utf-8", newline="") as handle:
            assert "Lyrics" not in next(csv.reader(handle)), csv_path


def test_r_and_quarto_fixes() -> None:
    assert 'read.csv("df_koi.csv")' in (ROOT / "MDS and Clustering Kepler Dataset" / "Code.r").read_text()
    assert "as.numeric" not in (ROOT / "MDS and Clustering Kepler Dataset" / "Code.r").read_text().split("X3_cat", 1)[1].split("# Calculate Pearson", 1)[0]
    assert "as.vector(Im[, , 1])" in (ROOT / "Independent Component Analysis" / "Second_Approach.R").read_text()
    monopoly = (ROOT / "Simulación Montecarlo Monopoly" / "Monopoly.R").read_text()
    assert "encarcelado <- FALSE" in monopoly
    assert "n_turnos_max + 1" in monopoly
    matrix_chain = (ROOT / "Matrix Chain Ordering Problem" / "notebook.qmd").read_text()
    assert "Malformed RPN" in matrix_chain
    assert "small_product_penalty" in matrix_chain
    dry_beans = (ROOT / "Classifying Dry Beans with Machine Learning" / "notebook.qmd").read_text()
    assert "Pipeline([('scale', StandardScaler()), ('model', knn)])" in dry_beans
    assert "accs    = [dt_test_accuracy, knn_test_accuracy, rf_test_accuracy," in dry_beans
    assert "n_estimators=best_n" in dry_beans


if __name__ == "__main__":
    test_notebook_fixes()
    test_security_and_data_hygiene()
    test_r_and_quarto_fixes()
    print("core logic checks: passed")
