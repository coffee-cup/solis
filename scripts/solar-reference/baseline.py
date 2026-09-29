#!/usr/bin/env python3
"""Reproduce the unchanged Objective-C baseline from a pinned git revision."""
import datetime as dt, hashlib, json, subprocess, tempfile
from pathlib import Path
from zoneinfo import ZoneInfo
root=Path(__file__).resolve().parents[2]
fixtures=root/'SunriseSunsetTests/Fixtures/Solar'
revision='317a623ffe95a648d2f45779039537857eb76f24'
rows=json.loads((fixtures/'astronomy.json').read_text())
overrides={r['id']:r for r in json.loads((fixtures/'adjudicated.json').read_text())}
rows=[overrides.get(r['id'],r) for r in rows]
with tempfile.TemporaryDirectory(prefix='solis-legacy-') as directory:
    path=Path(directory)
    for name in ['EDSunriseSet.h','EDSunriseSet.m']:
        source=subprocess.check_output(['git','show',f'{revision}:SunriseSunset/EDSunriseSet/{name}'],cwd=root)
        (path/name).write_bytes(source)
    source_hash=hashlib.sha256((path/'EDSunriseSet.m').read_bytes()).hexdigest()
    cases=[]
    for row in rows:
        date=dt.datetime.fromtimestamp((row['start']+row['end'])/2,ZoneInfo(row['timeZone']))
        cases.append(dict(y=date.year,m=date.month,d=date.day,zone=row['timeZone'],lat=row['latitude'],lon=row['longitude']))
    (path/'inputs.json').write_text(json.dumps(cases))
    subprocess.run(['xcrun','clang','-fobjc-arc','-framework','Foundation','-I',str(path),str(Path(__file__).with_name('legacy_probe.m')),str(path/'EDSunriseSet.m'),'-o',str(path/'probe')],check=True)
    results=json.loads(subprocess.check_output([str(path/'probe'),str(path/'inputs.json')]))
counts=dict(cases=len(rows),false_polar_night_pairs=0,missing_or_extra_crossing_fields=0,paired_times_over_60_seconds=0,events_outside_requested_day=0)
for raw,ref in zip(results,rows):
    for pair,alt in zip(raw,[-50/60,-6,-12,-18]):
        if pair['status']==-1 and not pair['never']:counts['false_polar_night_pairs']+=1
        for key,direction in [('rise',1),('set',-1)]:
            expected=[e['timestamp'] for e in ref['events'] if e['altitude']==alt and e['direction']==direction]
            actual=[] if pair['never'] else [pair[key]]
            if len(expected)!=len(actual):counts['missing_or_extra_crossing_fields']+=1
            elif actual and abs(expected[0]-actual[0])>60:counts['paired_times_over_60_seconds']+=1
            if actual and not ref['start']<=actual[0]<ref['end']:counts['events_outside_requested_day']+=1
report=dict(sourceRevision=revision,sourceSHA256=source_hash,**counts)
(fixtures/'legacy-baseline.json').write_text(json.dumps(report,indent=2)+'\n')
print(report)
