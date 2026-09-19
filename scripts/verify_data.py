"""Check available input snapshots against data-manifest.json using the stdlib."""
import argparse
import hashlib
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-all', action='store_true',
                        help='Also fail when an externally supplied dataset is absent.')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root / 'data-manifest.json').read_text())
    checked = missing = failed = 0
    for entry in manifest['files']:
        path = root / entry['path']
        if not path.is_file():
            missing += 1
            required = entry['versioned'] or args.require_all
            failed += required
            print(f"{'FAIL' if required else 'ABSENT (external)'}: {entry['path']}")
            continue
        with path.open('rb') as handle:
            digest = hashlib.file_digest(handle, 'sha256').hexdigest()
        if path.stat().st_size != entry['bytes'] or digest != entry['sha256']:
            failed += 1
            print(f"FAIL: snapshot differs: {entry['path']}")
        else:
            checked += 1
            print(f"PASS: {entry['path']}")
    print(f'{checked} matching snapshots; {missing} absent; {failed} failures.')
    raise SystemExit(bool(failed))


if __name__ == '__main__':
    main()
