#!/usr/bin/env python3
"""Adjudicate sensitive oracle cases with Skyfield 1.54 and JPL DE440s.
Development only: pass the path to a separately downloaded de440s.bsp.
Selection is based on reference sensitivity, never the production solver output.
"""
import datetime as dt, hashlib, json, sys
from pathlib import Path
import numpy as np
from scipy.optimize import brentq, minimize_scalar
from skyfield.api import load, load_file, wgs84
root=Path(__file__).resolve().parents[2]/'SunriseSunsetTests/Fixtures/Solar'
eph=load_file(sys.argv[1]);ts=load.timescale(builtin=True)
rows=json.loads((root/'astronomy.json').read_text())
disagreed={r['id'].replace('USNO/','Crosscheck/') for r in json.loads((root/'reference-disagreements.json').read_text())}
# Every polar crossing, all table disagreements, and all crossings near midnight.
selected=[r for r in rows if (r['id'] in disagreed or
    any(abs(e['timestamp']-r['start'])<60 or abs(e['timestamp']-r['end'])<60 for e in r['events']) or
    (abs(r['latitude'])>=89 and len(r['events'])>0)) and dt.datetime.fromtimestamp(r['start'],dt.timezone.utc).year>=1850]
# Include neighbouring civil days so a sub-second midnight shift is adjudicated
# on both sides of the boundary, not just the day containing the original root.
keys={(r['latitude'],r['longitude'],r['timeZone'],r['start']) for r in selected}
ends={(r['latitude'],r['longitude'],r['timeZone'],r['end']) for r in selected}
ids={r['id'] for r in selected}
selected=[r for r in rows if r['id'] in ids or
          (r['latitude'],r['longitude'],r['timeZone'],r['end']) in keys or
          (r['latitude'],r['longitude'],r['timeZone'],r['start']) in ends]
results=[]
for n,r in enumerate(selected):
    observer=eph['earth']+wgs84.latlon(r['latitude'],r['longitude'])
    def altitude(t):
        times=ts.ut1_jd(np.atleast_1d(t)/86400+2440587.5)
        v=observer.at(times).observe(eph['sun']).apparent().altaz()[0].degrees
        return v if np.ndim(t) else float(v[0])
    grid=np.arange(r['start']-1800,r['end']+3600,1800);heights=altitude(grid)
    points=[r['start'],r['end']]+[t for t in grid if r['start']<t<r['end']]
    for i in range(1,len(grid)-1):
        if (heights[i]-heights[i-1])*(heights[i+1]-heights[i])<0:
            sign=1 if heights[i]>heights[i-1] else -1
            base=grid[i-1]
            x=minimize_scalar(lambda offset:-sign*altitude(base+offset),bounds=(0,grid[i+1]-base),method='bounded',options={'xatol':.01}).x+base
            if r['start']<x<r['end']:points.append(x)
    points=sorted(set(points));heights=altitude(points);events=[];states=[]
    for threshold in [-18,-12,-6,-4,-50/60,6]:
        states.append(dict(altitude=threshold,above=bool(min(heights)>threshold),below=bool(max(heights)<threshold)))
        for left,right,a,b in zip(points,points[1:],heights,heights[1:]):
            if (a>=threshold)==(b>=threshold):continue
            rootTime=brentq(lambda offset:altitude(left+offset)-threshold,0,right-left,xtol=.01)+left
            if r['start']<=rootTime<r['end']:events.append(dict(altitude=threshold,direction=1 if b>a else -1,timestamp=rootTime))
    result={**r,'events':sorted(events,key=lambda e:e['timestamp']),'states':states};results.append(result)
    if n%20==0:print(n,len(selected),flush=True)
(root/'adjudicated.json').write_text(json.dumps(results,separators=(',',':'))+'\n')
(root/'adjudication-source.json').write_text(json.dumps(dict(source='https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/de440s.bsp',sha256=hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest(),skyfield='1.54',scipy='1.17.1',caseCount=len(results),selection='USNO disagreement, crossing within 60 seconds of civil midnight, or crossing at either pole; includes adjacent days',convention='Apparent topocentric solar centre, sea level, no atmospheric refraction, UT1 approximated by input UTC, built-in Skyfield delta-T'),indent=2)+'\n')
