#!/usr/bin/env python3
"""Refresh reference data explicitly; tests only read the checked-in output."""
import argparse, calendar, datetime as dt, hashlib, html, json, re, time, urllib.parse, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'SunriseSunsetTests/Fixtures/Solar'
PLACES = [
 ('Vancouver',49.2827,-123.1207,'America/Vancouver'),('Toronto',43.6532,-79.3832,'America/Toronto'),
 ('New_York',40.7128,-74.006,'America/New_York'),('London',51.5074,-.1278,'Europe/London'),
 ('Quito',-.1807,-78.4678,'America/Guayaquil'),('Equator',0,0,'UTC'),
 ('Sydney',-33.8688,151.2093,'Australia/Sydney'),('Cape_Town',-33.9249,18.4241,'Africa/Johannesburg'),
 ('Tokyo',35.6762,139.6503,'Asia/Tokyo'),('Kathmandu',27.7172,85.324,'Asia/Kathmandu'),
 ('Reykjavik',64.1466,-21.9426,'Atlantic/Reykjavik'),('Tromso',69.6492,18.9553,'Europe/Oslo'),
 ('Longyearbyen',78.2232,15.6267,'Europe/Oslo'),('Utqiagvik',71.2906,-156.7886,'America/Anchorage'),
 ('McMurdo',-77.8419,166.6863,'Antarctica/McMurdo'),('Kiritimati',1.8721,-157.4278,'Pacific/Kiritimati'),
 ('Apia',-13.8333,-171.75,'Pacific/Apia'),('Chatham',-43.95,-176.55,'Pacific/Chatham'),
 ('North_Pole',90,0,'UTC'),('South_Pole',-90,0,'UTC')]
TASKS = [(0,-50/60),(2,-6),(3,-12),(4,-18)]

def parse_table(content, year):
    match = re.search(r'<pre[^>]*>(.*?)</pre>',content,re.S)
    if not match: raise ValueError('USNO response has no table')
    table = html.unescape(match[1])
    if str(year) not in table: raise ValueError('Unexpected reference year')
    result = {}
    for line in table.splitlines():
        if not re.match(r'^\d\d  ',line): continue
        day=int(line[:2]); line=line.ljust(134)
        for month in range(1,13):
            if day>calendar.monthrange(year,month)[1]: continue
            # Fixed-width fields retain blank (no crossing today) cells.
            cell=line[4+(month-1)*11:4+(month-1)*11+9]
            pair=[cell[:4],cell[5:9]]
            for value in pair:
                if value.strip() not in ('','****','----','////','====') and not re.fullmatch(r'\d{4}',value):
                    raise ValueError(f'Unrecognised USNO value {value!r}')
            result.setdefault((month,day), []).append(pair)
    if len(result)!=365+calendar.isleap(year): raise ValueError('Incomplete reference table')
    return result

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--fetch',action='store_true');args=parser.parse_args()
    DEST.joinpath('raw').mkdir(parents=True,exist_ok=True)
    records=[];sources=[]
    for name,lat,lon,zone in PLACES:
        tables=[]
        for task,alt in TASKS:
            query=urllib.parse.urlencode(dict(year=2026,task=task,lat=lat,lon=lon,tz=0,tz_sign=1,label=name))
            url='https://aa.usno.navy.mil/calculated/rstt/year?'+query
            path=DEST/'raw'/f'{name}-2026-{task}.html'
            if args.fetch and not path.exists():
                for attempt in range(3):
                    try:
                        raw=urllib.request.urlopen(url,timeout=60).read();parse_table(raw.decode(),2026);path.write_bytes(raw);break
                    except Exception:
                        if attempt==2:raise
                        time.sleep(1)
                print(path.name,flush=True)
            raw=path.read_bytes(); tables.append((alt,parse_table(raw.decode(),2026)))
            sources.append(dict(file='raw/'+path.name,url=url,sha256=hashlib.sha256(raw).hexdigest()))
        for n in range(365):
            date=dt.datetime(2026,1,1,tzinfo=dt.timezone.utc)+dt.timedelta(days=n)
            events=[];states=[]
            for alt,table in tables:
                pairs=table[(date.month,date.day)]
                for pair in pairs:
                    for direction,value in zip([1,-1],pair):
                        if value.isdigit():
                            minutes=int(value[:2])*60+int(value[2:]);assert minutes<=1440
                            events.append(dict(altitude=alt,direction=direction,timestamp=date.timestamp()+minutes*60))
                states.append(dict(altitude=alt,above=any(p in [['****','****'],['////','////']] for p in pairs),below=any(p in [['----','----'],['====','====']] for p in pairs)))
            records.append(dict(id=f'USNO/{name}/{date:%Y-%m-%d}',latitude=round(lat*60)/60,longitude=round(lon*60)/60,timeZone='UTC',start=date.timestamp(),end=date.timestamp()+86400,events=sorted(events,key=lambda e:e['timestamp']),states=states))
    (DEST/'usno.json').write_text(json.dumps(records,separators=(',',':'))+'\n')
    (DEST/'sources.json').write_text(json.dumps(dict(retrieved='2026-09-26',timeToleranceSeconds=60,sources=sources,places=PLACES),indent=2)+'\n')
    print(f'{len(records)} independent USNO day fixtures')
if __name__=='__main__':main()
