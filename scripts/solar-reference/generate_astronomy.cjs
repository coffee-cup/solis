// Independent development-only oracle. Never linked into the app or run by CI.
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const A = require('./astronomy.cjs');
const dir = path.resolve(__dirname, '../../SunriseSunsetTests/Fixtures/Solar');
const inputs = JSON.parse(fs.readFileSync(path.join(dir, 'inputs.json')));
const thresholds = [-18, -12, -6, -4, -50 / 60, 6];
function altitude(timestamp, place) {
  const time = new Date(timestamp * 1000);
  const observer = new A.Observer(place.latitude, place.longitude, 0);
  const equator = A.Equator(A.Body.Sun, time, observer, true, true);
  return A.Horizon(time, observer, equator.ra, equator.dec).altitude;
}
function reference(place) {
  const values = new Map();
  function at(t) { if (!values.has(t)) values.set(t, altitude(t, place)); return values.get(t); }
  let points=[];
  for(let t=place.start;t<place.end;t+=600)points.push(t);
  points.push(place.end);
  const extrema=[];
  for(let i=1;i<points.length-1;i++){
    const a=at(points[i-1]), b=at(points[i]), c=at(points[i+1]);
    if ((b-a)*(c-b)>=0) continue;
    const sign=b>a?1:-1;let lo=points[i-1],hi=points[i+1];
    while(hi-lo>.02){let x=lo+(hi-lo)/3,y=hi-(hi-lo)/3;if(sign*at(x)<sign*at(y))lo=x;else hi=y;}
    extrema.push((lo+hi)/2);
  }
  points=[...points,...extrema].sort((a,b)=>a-b);
  let events=[];
  for(const alt of thresholds)for(let i=1;i<points.length;i++){
    let lo=points[i-1],hi=points[i],v=at(lo)-alt,w=at(hi)-alt;
    if((v>=0)===(w>=0))continue;
    const direction=w>v?1:-1;
    while(hi-lo>.02){const mid=(lo+hi)/2;if((at(mid)-alt>=0)===(v>=0))lo=mid;else hi=mid;}
    const timestamp=(lo+hi)/2;
    if(timestamp>=place.start&&timestamp<place.end)events.push({altitude:alt,direction,timestamp});
  }
  const heights=points.map(at),low=Math.min(...heights),high=Math.max(...heights);
  return {...place,events:events.sort((a,b)=>a.timestamp-b.timestamp),states:thresholds.map(alt=>({altitude:alt,above:low>alt,below:high<alt}))};
}
const results=inputs.map((x,i)=>{if(i%1000===0)process.stderr.write(`${i}/${inputs.length}\n`);return reference(x);});
fs.writeFileSync(path.join(dir,'astronomy.json'),JSON.stringify(results)+'\n');
const metadata={source:'https://github.com/cosinekitty/astronomy',sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,'astronomy.cjs'))).digest('hex'),convention:'Topocentric apparent solar centre at sea level, fixed geometric thresholds, no refraction correction',timeToleranceSeconds:60,caseCount:results.length};
fs.writeFileSync(path.join(dir,'astronomy-source.json'),JSON.stringify(metadata,null,2)+'\n');
console.log(metadata);
