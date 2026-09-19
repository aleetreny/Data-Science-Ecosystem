"""Recompute derived CSV metrics from locally held source snapshots containing Lyrics.

Usage: python scripts/recompute_metrics.py /path/to/original/snapshots
Raw lyric text is read locally and is never included in the output CSVs.
"""
import argparse
from pathlib import Path
import numpy as np
import pandas as pd
from textblob import TextBlob


def lyric_metrics(text, duration_minutes):
    if not isinstance(text, str) or not text.strip():
        return {"Total Words": 0, "Polarity": np.nan, "Subjectivity": np.nan,
                "Lexical Richness (%)": np.nan, "Words per Minute": np.nan}
    clean = "\n".join(line for line in text.splitlines()
                      if not line.lstrip().startswith("[") and line.strip())
    blob = TextBlob(clean)
    words = blob.words
    total = len(words)
    if not np.isfinite(duration_minutes) or duration_minutes <= 0:
        raise ValueError("Track duration must be positive and finite")
    return {
        "Total Words": total,
        "Polarity": round(blob.sentiment.polarity, 3),
        "Subjectivity": round(blob.sentiment.subjectivity, 3),
        "Lexical Richness (%)": round(100 * len({w.lower() for w in words}) / total, 2) if total else np.nan,
        "Words per Minute": round(total / duration_minutes, 2),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_directory", type=Path)
    parser.add_argument("--output-directory", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    names = ("dataset_music.csv", "dataset_fixed.csv", "dataset_final_completed.csv")
    prepared = {}
    for name in names:
        source = args.source_directory / name
        target = args.output_directory / name
        if source.resolve() == target.resolve():
            raise ValueError("Source snapshots and derived outputs must be separate")
        data = pd.read_csv(source)
        required = {"Lyrics", "Duration (min)", "Artist", "Song"}
        if not required.issubset(data.columns):
            raise ValueError(f"Missing required columns in {source.name}")
        computed = pd.DataFrame([lyric_metrics(text, duration) for text, duration in
                                 zip(data["Lyrics"], data["Duration (min)"])])
        output = data.drop(columns="Lyrics").copy()
        output[computed.columns] = computed
        prepared[target] = output
    args.output_directory.mkdir(parents=True, exist_ok=True)
    for target, data in prepared.items():
        temporary = target.with_suffix(".csv.tmp")
        data.to_csv(temporary, index=False, encoding="utf-8-sig")
        temporary.replace(target)
        print(f"{target.name}: {len(data)} rows; derived metrics only")


if __name__ == "__main__":
    main()
