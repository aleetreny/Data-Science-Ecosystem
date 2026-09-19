# Spotify Audio Analytics: Evolution & Prediction

[Portfolio](../README.md) · [Execution guide](../RUNNING.md)

Two separate studies explore playlist metadata and lyric-derived features,
and predict release decades from a Spotify/Kaggle audio-feature snapshot.
The EDA does not use Spotify audio features.

## Music Evolution

Run [Music_evolution/music_evolution.ipynb](Music_evolution/music_evolution.ipynb)
with the shared [Python environment](../RUNNING.md). By default it reads the
three supplied CSV snapshots, requires no credentials and makes no API calls.
The final playlist sample contains 789 tracks labeled from the 1950s through
the 2020s. It is a selected playlist sample, not a representative history of
music production.

The plots describe duration, popularity, explicit status, genre, album-year
discrepancies and lyric-derived metrics. TextBlob polarity is a lexical
sentiment score; type-token ratio depends on text length; words per minute
is word count divided by track duration. None directly measures emotional
intent, compositional complexity or vocal delivery speed. The broad genre
mapping leaves 420 of 789 tracks (53.23%) unclassified.

Derived metrics were checked against the locally recovered original text
snapshots and recomputed with the pinned tokenizer. Raw lyrics are not
redistributed. To regenerate the three derived CSVs from your own copies:

```bash
cd Music_evolution
../../.venv/bin/python -m nltk.downloader punkt_tab
../../.venv/bin/python scripts/recompute_metrics.py /path/to/original/snapshots
```

The source directory must contain the three same-named CSVs with a `Lyrics`
column. Outputs omit raw lyrics; word density uses the stored duration in
minutes. Missing lyrics produce missing sentiment/richness/density values.

Optional live enrichment requires `MUSIC_REFRESH=1`, `SPOTIFY_CLIENT_ID`,
`SPOTIFY_CLIENT_SECRET` and `GENIUS_TOKEN`. Refreshed files go under
`Music_evolution/data/refresh/`. API availability and returned metadata may
change; the checked results use the supplied snapshots.

## Decade prediction

Run [Predict_decades/predict_decades.ipynb](Predict_decades/predict_decades.ipynb).
Obtain `tracks.csv` from version 1 of the
[Spotify Dataset 1921–2020, 600k+ Tracks](https://www.kaggle.com/datasets/yamaerenay/spotify-dataset-19212020-600k-tracks/versions/1).
Put it in `Predict_decades/data/`, or set `SPOTIFY_TRACKS_CSV` to its path.
The source contains 586,672 tracks and 20 columns.

The notebook removes repeated IDs, duplicate model-input vectors and vectors
with conflicting decade labels. It restricts tracks to the 1940s–2020s and
durations of one to ten minutes, then samples 16,036 tracks per decade.
The stratified split contains 115,459 training and 28,865 test tracks. Feature
exploration uses training rows. Eleven numeric audio descriptors, including
duration, enter a 100-tree random forest with maximum depth 20; release dates,
artist identifiers, lyrics, key and mode are excluded from the model.

| Metric | Test result | Uniform-random baseline |
|---|---:|---:|
| Exact decade | 39.85% | 11.11% |
| Exact or adjacent decade | 73.04% | 30.86% |

Acousticness and loudness have the largest impurity-based feature importances
in this fit. This does not establish that technology causes the observed
differences, or that excluded inputs are uninformative. The split is not
grouped by artist, remaster or recording family, and catalog release dates
can describe reissues. Results therefore measure track-level prediction in
this balanced snapshot, not generalization to unseen artists or a complete
future decade.

Author: Alejandro Treny Ortega. Sources: cached Spotify/Genius enrichment
and the separately acquired Kaggle dataset described above.
