#!/usr/bin/env python3
"""Report disagreements before changing the production calculator."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'SunriseSunsetTests/Fixtures/Solar'
usno=json.loads((root/'usno.json').read_text())
astro={r['id'].replace('Crosscheck/','USNO/'):r for r in json.loads((root/'astronomy.json').read_text()) if r['id'].startswith('Crosscheck/')}
differences=[]
for row in usno:
    other=astro[row['id']]
    for alt in [-50/60,-6,-12,-18]:
        for direction in [1,-1]:
            a=[e['timestamp'] for e in row['events'] if e['altitude']==alt and e['direction']==direction]
            b=[e['timestamp'] for e in other['events'] if e['altitude']==alt and e['direction']==direction]
            if len(a)!=len(b) or any(abs(x-y)>60 for x,y in zip(a,b)):
                differences.append(dict(id=row['id'],altitude=alt,direction=direction,usno=a,astronomy=b))
(root/'reference-disagreements.json').write_text(json.dumps(differences,indent=2)+'\n')
print('USNO day fixtures:',len(usno),'disagreeing event fields:',len(differences))
for row in differences[:25]:print(row)
