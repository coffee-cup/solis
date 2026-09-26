#!/usr/bin/env python3
"""Explicitly freeze independently produced data before changing the solver."""
import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'SunriseSunsetTests/Fixtures/Solar'
files=['astronomy.json','astronomy-source.json','inputs.json','usno.json','sources.json','reference-disagreements.json','adjudicated.json','adjudication-source.json']
(root/'manifest.json').write_text(json.dumps({p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in files},indent=2)+'\n')
