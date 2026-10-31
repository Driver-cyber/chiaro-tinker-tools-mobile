// Regenerate PrimesTests/web-fixture.json from the web game (run: node ios/Primes/tools/make-fixture.js).
const fs=require('fs');
const s=fs.readFileSync(require('path').join(__dirname,'../../../src/index.html'),'utf8');
const src=s.slice(s.indexOf('/* ---- Primes — prime or composite'), s.indexOf('/* ---- Opening — the threshold room'));
const stub={ document:{addEventListener(){},getElementById(){return null},querySelectorAll(){return []},documentElement:{classList:{add(){},remove(){}}}}, window:{addEventListener(){}}, location:{hash:''}, history:{replaceState(){}},
  escapeHtml:s=>String(s), makeCheck(){}, switchMain(){}, db:{primes:{solved:{}}}, save(){}, todayStr:()=>'2026-01-01', matchMedia:()=>({matches:false}) };
const E=new Function(...Object.keys(stub), src+'; return {PC_PRIMES,pcSpf,pcIsPrime,pcApply,pcPrime,PC_TRICKS,PC_CONFIG,PC_BUCKETS};')(...Object.values(stub));
const strip=h=>h.replace(/<[^>]+>/g,'').replace(/&amp;/g,'&').trim();
const numbers={}, apply={};
for(let n=2;n<=999;n++){
  const prime=E.pcIsPrime(n), o={prime, spf:E.pcSpf(n)};
  if(!prime){ const p=E.pcSpf(n); o.eq=n+' = '+p+' × '+(n/p); o.lines=E.pcApply(p,n).lines; }
  else { const h=E.pcPrime(n);
    const list=/<p>([^<]*on the prime list[^<]*)<\/p>/.exec(h); const root=/<div class="pc-math">([^<]*)<\/div>/.exec(h);
    const verdict=/<p>((?:None of|\d+ doesn)[^<]*)<\/p>/.exec(h); const chips=[...h.matchAll(/pcOpenSheet\('trick',(\d+)/g)].map(m=>+m[1]);
    o.list=list?list[1]:null; o.root=root?root[1]:null; o.verdict=verdict?verdict[1]:null; o.checked=chips; }
  numbers[n]=o;
  for(const p of E.PC_PRIMES){ const a=E.pcApply(p,n); apply[p+':'+n]={ok:a.ok, lines:a.lines}; }
}
const tricks={}; for(const p of E.PC_PRIMES) tricks[p]={trick:E.PC_TRICKS[p].trick, example:E.PC_TRICKS[p].ex};
const buckets={}; for(const t in E.PC_BUCKETS){ buckets[t]={}; for(const k in E.PC_BUCKETS[t]) buckets[t][k]=E.PC_BUCKETS[t][k]; }
const out={source:'CTT web engine (src/index.html) — regenerate if the web game changes', numbers, apply, tricks, buckets};
const path=require('path').join(__dirname,'../PrimesTests/web-fixture.json');
fs.writeFileSync(path, JSON.stringify(out));
const primeCount=Object.values(numbers).filter(o=>o.prime).length;
console.log('wrote', path, (fs.statSync(path).size/1024).toFixed(0)+' KB', '| primes', primeCount, '| apply pairs', Object.keys(apply).length);

