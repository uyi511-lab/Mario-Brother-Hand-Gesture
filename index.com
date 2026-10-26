<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Petualangan Pembagian AR</title>
<style>
*{box-sizing:border-box;margin:0}
html,body{height:100%;overflow:hidden;background:#2a6fb0;font-family:"Trebuchet MS","Segoe UI",sans-serif;color:#fff;user-select:none}
#cam{position:fixed;inset:0;width:100%;height:100%;object-fit:cover;transform:scaleX(-1);display:none}
#c{position:fixed;inset:0;width:100%;height:100%}
.ui{position:fixed;pointer-events:none}
#top{top:8px;left:8px;right:8px;display:flex;gap:8px;align-items:flex-start;justify-content:space-between}
.pill{background:rgba(20,30,70,.82);border:3px solid #ffd23f;border-radius:16px;padding:6px 12px;font-weight:700;font-size:clamp(13px,2vw,20px);white-space:nowrap}
#qcard{flex:1;max-width:560px;margin:0 auto;text-align:center;background:#fff;color:#1c2a6b;border:5px solid #ff7a1a;border-radius:22px;padding:4px 12px;box-shadow:0 5px 0 #b34d00}
#qcard small{display:block;font-size:clamp(11px,1.5vw,15px);color:#666;font-weight:700}
#qtext{font-size:clamp(30px,6vw,64px);font-weight:900;line-height:1.05}
#btns{pointer-events:auto;display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end;max-width:260px}
button{font:inherit;font-weight:800;cursor:pointer;border:0;border-radius:14px;padding:8px 14px;background:#ffd23f;color:#3b2500;box-shadow:0 4px 0 #b88a00;font-size:clamp(12px,1.6vw,16px)}
button:active{transform:translateY(3px);box-shadow:0 1px 0 #b88a00}
button:focus-visible{outline:3px solid #fff}
#prog{top:calc(8px + clamp(70px,11vw,120px));left:50%;transform:translateX(-50%);width:min(420px,70vw);height:14px;background:rgba(0,0,0,.45);border-radius:9px;overflow:hidden;border:2px solid #fff}
#bar{height:100%;width:0;background:linear-gradient(90deg,#4cd964,#ffd23f);transition:width .5s}
#msg{top:42%;left:0;right:0;text-align:center;font-size:clamp(30px,6vw,64px);font-weight:900;text-shadow:0 4px 0 #0006,0 0 12px #000;opacity:0;transition:opacity .2s}
#msg.on{opacity:1}
#gest{bottom:10px;left:50%;transform:translateX(-50%);display:flex;gap:8px}
.g{background:rgba(20,30,70,.8);border:3px solid #fff5;border-radius:14px;padding:6px 10px;font-weight:700;font-size:clamp(11px,1.6vw,16px);text-align:center;min-width:74px;transition:.1s}
.g.on{background:#4cd964;border-color:#fff;color:#073b12;transform:scale(1.15)}
#stat{bottom:70px;left:50%;transform:translateX(-50%);background:rgba(0,0,0,.6);padding:5px 14px;border-radius:12px;font-weight:700;font-size:clamp(11px,1.6vw,15px);text-align:center;max-width:90vw}
#warn{top:calc(8px + clamp(100px,15vw,150px));left:8px;max-width:320px;background:#b3261e;border-radius:12px;padding:8px 12px;font-size:14px;display:none}
.ov{position:fixed;inset:0;background:rgba(15,25,70,.86);display:none;align-items:center;justify-content:center;text-align:center;padding:16px;z-index:5}
.ov.show{display:flex}
.box{max-width:640px;background:#fff;color:#1c2a6b;border:6px solid #ff7a1a;border-radius:28px;padding:22px 26px;box-shadow:0 8px 0 #b34d00}
.box h1{font-size:clamp(26px,5vw,46px);color:#e8321e;line-height:1.05;margin-bottom:8px}
.box p,.box li{font-size:clamp(14px,2vw,18px);line-height:1.45;text-align:left}
.box ul{margin:8px 0 12px 22px}
.box button{font-size:22px;padding:12px 30px;margin-top:6px}
.big{font-size:clamp(18px,3vw,30px);font-weight:800;margin:6px 0}
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
</style>
</head>
<body>
<video id="cam" playsinline muted></video>
<canvas id="c"></canvas>

<div class="ui" id="top">
  <div class="pill" id="stats">Soal 1/10<br>⭐ 0 &nbsp; 🪙 0</div>
  <div id="qcard"><small>Berapa hasilnya?</small><div id="qtext">…</div></div>
  <div id="btns">
    <button id="bPause">⏸ Jeda</button>
    <button id="bRetry">🔄 Ulangi</button>
    <button id="bSnd">🔊 Suara</button>
  </div>
</div>
<div class="ui" id="prog"><div id="bar"></div></div>
<div class="ui" id="msg"></div>
<div class="ui" id="warn"></div>
<div class="ui" id="stat">Tekan Mulai</div>
<div class="ui" id="gest">
  <div class="g" id="gL">⬅️<br>Miring kiri</div>
  <div class="g" id="gR">➡️<br>Miring kanan</div>
  <div class="g" id="gJ">🙌<br>Lompat</div>
  <div class="g" id="gS">✋<br>Tembak/Pilih</div>
</div>

<div class="ov show" id="ovStart"><div class="box">
  <h1>Petualangan Pembagian!</h1>
  <p>Bantu petualang kecil mengumpulkan koin dengan menjawab 10 soal pembagian. Kamera dipakai untuk membaca gerak tubuhmu. Mundur sampai bahu dan tanganmu terlihat.</p>
  <ul>
    <li><b>Miring ke kiri / kanan:</b> karakter berjalan</li>
    <li><b>Angkat dua tangan:</b> melompat</li>
    <li><b>Angkat tangan kanan:</b> tembak bola energi ke balok jawaban</li>
    <li><b>Berdiri tegak:</b> berhenti</li>
    <li><b>Keyboard:</b> panah = jalan, Spasi = lompat, Enter = tembak</li>
  </ul>
  <p id="loadTxt" style="text-align:center;font-weight:800;min-height:24px"></p>
  <button id="bStart">▶ Mulai</button>
</div></div>

<div class="ov" id="ovPause"><div class="box"><h1>Permainan dijeda</h1><button id="bResume">▶ Lanjutkan</button></div></div>

<div class="ov" id="ovWin"><div class="box" style="text-align:center">
  <h1>🏆 Hebat!</h1>
  <p class="big" style="text-align:center">Hebat! Kamu berhasil menyelesaikan petualangan matematika!</p>
  <p class="big" style="text-align:center">⭐ Skor: <span id="wScore">0</span> / 100</p>
  <p class="big" style="text-align:center">✅ Jawaban benar: <span id="wOk">0</span> / 10</p>
  <p class="big" style="text-align:center">🪙 Koin terkumpul: <span id="wCoin">0</span></p>
  <button id="bAgain">Main Lagi</button>
</div></div>

<script>
const $=id=>document.getElementById(id);
const cv=$('c'),ctx=cv.getContext('2d'),vid=$('cam');
const H=600,GY=500;
let sc=1,VW=1000,T=0,camOn=false,pose=null;

/* ---------- Soal ---------- */
const Q=[[48,4],[63,3],[84,7],[96,8],[72,6],[56,4],[81,9],[75,5],[68,4],[92,4]];
const shuffle=a=>{for(let i=a.length-1;i>0;i--){const j=Math.random()*(i+1)|0;[a[i],a[j]]=[a[j],a[i]]}return a};
function makeOptions(ans){
  const c=[...new Set([ans+1,ans-1,ans+2,ans-2,ans+10,ans-10,ans+3,ans-3])].filter(v=>v>0&&v!==ans);
  return shuffle([ans,...shuffle(c).slice(0,2)]);
}

/* ---------- Audio ---------- */
let AC=null,snd=true;
function beep(f,d=.12,type='square',v=.07,t0=0){
  if(!snd||!AC)return;
  const o=AC.createOscillator(),g=AC.createGain(),t=AC.currentTime+t0;
  o.type=type;o.frequency.setValueAtTime(f,t);g.gain.setValueAtTime(v,t);
  g.gain.exponentialRampToValueAtTime(.001,t+d);o.connect(g);g.connect(AC.destination);o.start(t);o.stop(t+d);
}
const sfx={
  jump(){beep(380,.1);beep(620,.15,'square',.07,.08)},
  shoot(){beep(900,.12,'sawtooth',.05);beep(500,.12,'sawtooth',.05,.06)},
  coin(){beep(988,.08);beep(1319,.2,'square',.07,.08)},
  ok(){[523,659,784,1047].forEach((f,i)=>beep(f,.18,'triangle',.1,i*.1))},
  bad(){beep(220,.3,'sawtooth',.08);beep(150,.35,'sawtooth',.08,.15)}
};

/* ---------- State ---------- */
const G={state:'menu',q:0,score:0,coins:0,correct:0,cam:0,blocks:[],gl:0,gr:0,sp:250,
  cw:[],rocks:[],balls:[],parts:[],floats:[],auto:false,autoTo:0,lockT:0,msgT:0};
const P={x:0,y:GY,vy:0,face:1,onGround:true,moving:false,celebrate:false,shootT:0,hopT:0};
const keys={};let pend={jump:false,shoot:false};
let poseDir=0,poseSpd=1;

function spawnGroup(first){
  const [a,b]=Q[G.q],ans=a/b;
  const opts=makeOptions(ans);
  const sp=Math.max(170,Math.min(300,(VW-280)/3));
  const prevR=G.gr;
  G.sp=sp;G.gl=first?420:G.gr+950;G.gr=G.gl+2*sp;
  G.blocks=opts.map((v,i)=>({v,x:G.gl+i*sp,state:0,shake:0,ok:v===ans}));
  G.cw=G.cw.filter(c=>!c.got&&c.x>G.cam-300);
  for(let i=0;i<2;i++)G.cw.push({x:G.gl+sp*(i+.5),y:GY-250,got:false});
  G.rocks=[];
  if(!first){
    for(let x=prevR+250;x<G.gl-250;x+=120)G.cw.push({x,y:GY-60,got:false});
    G.rocks.push({x:prevR+420},{x:prevR+720});
    G.auto=true;G.autoTo=G.gl-200;
  }
  $('qtext').textContent=a+' ÷ '+b+' = ?';
  G.balls=[];updateHUD();
}
function updateHUD(){
  $('stats').innerHTML='Soal '+Math.min(G.q+1,10)+'/10<br>⭐ '+G.score+' &nbsp; 🪙 '+G.coins;
  $('bar').style.width=(G.correct/10*100)+'%';
}
function showMsg(t,ms=1200){const m=$('msg');m.textContent=t;m.classList.add('on');G.msgT=ms/1000}
function burst(x,y,cols,n=24){for(let i=0;i<n;i++){const a=Math.random()*6.28,s=100+Math.random()*320;
  G.parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-150,life:.9,c:cols[i%cols.length],r:3+Math.random()*5})}}

function newGame(){
  G.q=0;G.score=0;G.coins=0;G.correct=0;G.cw=[];G.parts=[];G.floats=[];G.balls=[];
  G.auto=false;G.lockT=0;G.gr=0;P.celebrate=false;P.vy=0;P.y=GY;P.shootT=0;
  spawnGroup(true);
  P.x=G.gl-120;P.face=1;G.cam=G.gl+G.sp-VW/2;
  calib.length=0;stable='none';
  G.state='play';updateHUD();
  ['ovStart','ovPause','ovWin'].forEach(i=>$(i).classList.remove('show'));
  $('bPause').textContent='⏸ Jeda';
}

/* ---------- Aksi ---------- */
function doJump(){
  if(G.state!=='play'||!P.onGround||P.celebrate)return;
  P.vy=-800;P.onGround=false;sfx.jump();
}
function doShoot(){
  if(G.state!=='play'||P.celebrate||G.auto)return;
  G.balls.push({x:P.x+P.face*34,y:P.y-55,vx:P.face*900,life:1});
  P.shootT=.25;sfx.shoot();
}
function answer(b){
  if(b.ok){
    b.state=1;G.correct++;G.score+=10;G.coins+=3;
    burst(b.x,GY-115,['#ffd23f','#ff7a1a','#fff','#4cd964'],40);
    G.floats.push({x:b.x,y:GY-180,t:'+10',life:1.2});
    sfx.ok();setTimeout(sfx.coin,350);
    showMsg('Benar! Hebat! 🎉',1300);
    P.celebrate=true;P.vy=-520;P.onGround=false;P.hopT=.55;G.lockT=1.5;
    updateHUD();
  }else{
    b.state=2;b.shake=.5;sfx.bad();
    burst(b.x,GY-115,['#ff5252','#888'],14);
    showMsg('Ups! Coba lagi!',1100);
  }
}

/* ---------- Update ---------- */
function update(dt){
  T+=dt;
  if(G.msgT>0){G.msgT-=dt;if(G.msgT<=0)$('msg').classList.remove('on')}
  // input
  const kd=(keys.ArrowRight?1:0)-(keys.ArrowLeft?1:0);
  const dir=kd||poseDir, spd=kd?1:poseSpd;
  if(pend.jump){doJump();pend.jump=false}
  if(pend.shoot){doShoot();pend.shoot=false}
  P.moving=false;
  if(G.auto){
    P.x+=300*dt;P.face=1;P.moving=true;
    if(P.x>=G.autoTo)G.auto=false;
    for(const r of G.rocks)if(P.onGround&&Math.abs(P.x-r.x)<34){P.vy=-560;P.onGround=false}
  }else if(!P.celebrate&&dir){
    P.x+=dir*260*spd*dt;P.face=dir;P.moving=true;
    P.x=Math.max(G.gl-200,Math.min(G.gr+200,P.x));
  }
  // fisika
  if(P.celebrate){P.hopT-=dt;if(P.hopT<=0&&P.onGround){P.vy=-450;P.onGround=false;P.hopT=.55}}
  P.vy+=2200*dt;P.y+=P.vy*dt;
  if(P.y>=GY){P.y=GY;P.vy=0;P.onGround=true}
  if(P.shootT>0)P.shootT-=dt;
  // lock / lanjut soal
  if(G.lockT>0){G.lockT-=dt;if(G.lockT<=0){
    P.celebrate=false;G.q++;
    if(G.q>=10)winGame();else spawnGroup(false);
  }}
  // kamera
  const want=G.auto?P.x-VW*.3:G.gl+G.sp-VW/2;
  G.cam+=(want-G.cam)*Math.min(1,dt*4);
  // bola
  for(const b of G.balls){
    b.x+=b.vx*dt;b.life-=dt;b.y+=((GY-115)-b.y)*Math.min(1,dt*10);
    for(const k of G.blocks){
      if(k.state===0&&b.life>0&&Math.abs(b.x-k.x)<56&&Math.abs(b.y-(GY-115))<60){b.life=0;answer(k);break}
    }
  }
  G.balls=G.balls.filter(b=>b.life>0);
  for(const k of G.blocks)if(k.shake>0)k.shake-=dt;
  // koin
  for(const c of G.cw)if(!c.got&&Math.hypot(c.x-P.x,c.y-(P.y-45))<44){c.got=true;G.coins++;sfx.coin();
    burst(c.x,c.y,['#ffd23f','#fff'],8);updateHUD()}
  // partikel
  for(const p of G.parts){p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=900*dt;p.life-=dt}
  G.parts=G.parts.filter(p=>p.life>0);
  for(const f of G.floats){f.y-=60*dt;f.life-=dt}
  G.floats=G.floats.filter(f=>f.life>0);
  // indikator
  $('gL').classList.toggle('on',dir<0&&P.moving);
  $('gR').classList.toggle('on',dir>0&&P.moving);
  $('gJ').classList.toggle('on',!P.onGround||stable==='both');
  $('gS').classList.toggle('on',P.shootT>0||stable==='right');
}
function winGame(){
  G.state='win';
  $('wScore').textContent=G.score;$('wOk').textContent=G.correct;$('wCoin').textContent=G.coins;
  $('ovWin').classList.add('show');updateHUD();
  sfx.ok();setTimeout(sfx.ok,600);
}

/* ---------- Pose ---------- */
let lm=null,lastVT=-1,calib=[],base=0,lean=0,cand='none',cc=0,stable='none',lastRep=0;
function setStat(t){$('stat').textContent=t}
function poseStep(){
  if(!pose||!camOn||vid.readyState<2||vid.currentTime===lastVT)return;
  lastVT=vid.currentTime;
  let r;try{r=pose.detectForVideo(vid,performance.now())}catch(e){return}
  lm=r.landmarks&&r.landmarks[0];
  if(!lm||lm[11].visibility<.5||lm[12].visibility<.5){poseDir=0;lm=null;setStat('👀 Aku belum melihat bahumu. Mundur sedikit ya.');return}
  const X=i=>1-lm[i].x;
  const sh=(X(11)+X(12))/2,shY=(lm[11].y+lm[12].y)/2,sw=Math.max(.05,Math.abs(X(11)-X(12)));
  const hips=lm[23].visibility>.5&&lm[24].visibility>.5;
  const raw=(X(0)-sh)/sw*.8+(hips?(sh-(X(23)+X(24))/2)/sw:0);
  if(calib.length<25){
    calib.push(raw);base=calib.reduce((a,b)=>a+b,0)/calib.length;lean=0;poseDir=0;
    setStat('🧍 Berdiri tegak sebentar… ('+calib.length+'/25)');
  }else{
    lean+=(raw-base-lean)*.35;
    const a=Math.abs(lean);
    if(a>.2)poseDir=lean>0?1:-1;else if(a<.1)poseDir=0;
    poseSpd=.6+Math.min(.4,Math.max(0,a-.2)*1.5);
    setStat(poseDir<0?'⬅️ Miring kiri':poseDir>0?'➡️ Miring kanan':'✅ Tegak. Siap!');
  }
  // tangan
  const up=i=>lm[i].visibility>.4&&lm[i].y<shY-.03;
  const L=up(15),R=up(16);
  const c=L&&R?'both':R?'right':'none';
  if(c===cand)cc++;else{cand=c;cc=1}
  const now=performance.now();
  if(cc>=4&&stable!==cand){
    stable=cand;lastRep=now;
    if(stable==='both')pend.jump=true;
    if(stable==='right')pend.shoot=true;
  }else if(stable==='right'&&now-lastRep>900){lastRep=now;pend.shoot=true}
}

/* ---------- Gambar ---------- */
function rr(x,y,w,h,r){ctx.beginPath();ctx.roundRect(x,y,w,h,r);ctx.fill()}
function cloud(x,y,s){ctx.fillStyle='rgba(255,255,255,.92)';
  [[0,0,30],[28,-10,36],[62,0,28],[30,8,32]].forEach(([a,b,r])=>{ctx.beginPath();ctx.arc(x+a*s,y+b*s,r*s,0,6.3);ctx.fill()})}
function coinDraw(x,y,r=15){
  const w=Math.abs(Math.cos(T*4+x*.01))*r+2;
  ctx.fillStyle='#b88a00';ctx.beginPath();ctx.ellipse(x,y,w+2,r+2,0,0,6.3);ctx.fill();
  ctx.fillStyle='#ffd23f';ctx.beginPath();ctx.ellipse(x,y,w,r,0,0,6.3);ctx.fill();
  ctx.fillStyle='#fff6b0';ctx.beginPath();ctx.ellipse(x-w*.2,y-r*.2,w*.3,r*.5,0,0,6.3);ctx.fill();
}
const hash=i=>Math.abs(Math.sin(i*127.1)*43758.5)%1;
function drawBg(){
  const cam=G.cam,a=camOn?.38:1;
  const g=ctx.createLinearGradient(0,0,0,GY);
  g.addColorStop(0,`rgba(70,170,255,${a})`);g.addColorStop(1,`rgba(205,240,255,${a})`);
  ctx.fillStyle=g;ctx.fillRect(0,0,VW,H);
  ctx.fillStyle='#ffe66d';ctx.beginPath();ctx.arc(VW-110,90,46,0,6.3);ctx.fill();
  const cw=VW+320;
  for(let i=0;i<6;i++){const x=(((i*330-cam*.15)%cw)+cw)%cw-160;cloud(x,70+(i*53%110),.9+(i%3)*.25)}
  [[.3,150,60,0,'#7bd88f'],[.5,100,40,2,'#4caf50']].forEach(([f,base0,amp,ph,col])=>{
    ctx.fillStyle=col;ctx.beginPath();ctx.moveTo(0,GY);
    for(let x=0;x<=VW+20;x+=20){const wx=x+cam*f;ctx.lineTo(x,GY-base0-Math.sin(wx*.006+ph)*amp-Math.sin(wx*.017)*14)}
    ctx.lineTo(VW,GY);ctx.fill()});
  // pohon
  for(let i=Math.floor(cam*.7/230)-1;i<Math.floor((cam*.7+VW)/230)+2;i++){
    const x=i*230+hash(i)*120-cam*.7,s=.8+hash(i+9)*.5;
    ctx.fillStyle='#8a5a2b';ctx.fillRect(x-7*s,GY-70*s,14*s,70*s);
    ctx.fillStyle='#2e9e4a';ctx.beginPath();ctx.arc(x,GY-90*s,38*s,0,6.3);ctx.arc(x-26*s,GY-65*s,28*s,0,6.3);ctx.arc(x+26*s,GY-65*s,28*s,0,6.3);ctx.fill();
  }
  // pipa (dekorasi)
  for(let i=Math.floor(cam/700)-1;i<Math.floor((cam+VW)/700)+2;i++){
    const x=i*700+300+hash(i+3)*200-cam,h=60+hash(i+5)*60;
    ctx.fillStyle='#1fa34a';ctx.fillRect(x,GY-h,60,h);ctx.fillStyle='#2ecc71';rr(x-6,GY-h-4,72,24,6);
    ctx.fillStyle='#0d6b2d';ctx.fillRect(x+44,GY-h+20,8,h-20);
  }
  // tanah
  ctx.fillStyle='#b5651d';ctx.fillRect(0,GY,VW,H-GY);
  ctx.fillStyle='#8f4c12';
  for(let x=-((cam%80)+80);x<VW;x+=80){ctx.fillRect(x,GY+40,2,H);}
  for(let y=GY+40;y<H;y+=40)ctx.fillRect(0,y,VW,2);
  ctx.fillStyle='#4cc04f';ctx.fillRect(0,GY,VW,20);ctx.fillStyle='#2e9e3a';ctx.fillRect(0,GY+16,VW,5);
}
function drawBlocks(){
  G.blocks.forEach((k,i)=>{
    if(k.state===1)return;
    const sx=k.x-G.cam;if(sx<-100||sx>VW+100)return;
    const bob=k.state===0?Math.sin(T*3+i)*4:0,shk=k.shake>0?Math.sin(T*60)*6:0;
    const x=sx-50+shk,y=GY-165+bob;
    ctx.fillStyle=k.state===2?'#a9a9a9':'#8a5a00';rr(x-4,y-4,108,108,14);
    ctx.fillStyle=k.state===2?'#d4b0b0':'#ffc83d';rr(x,y,100,100,12);
    ctx.fillStyle=k.state===2?'#c99':'#ffe27a';rr(x+6,y+6,88,20,8);
    ctx.font='900 46px "Trebuchet MS",sans-serif';ctx.textAlign='center';ctx.textBaseline='middle';
    ctx.lineWidth=7;ctx.strokeStyle='#5a3600';ctx.strokeText(k.v,x+50,y+58);
    ctx.fillStyle='#fff';ctx.fillText(k.v,x+50,y+58);
    if(k.state===2){ctx.font='900 40px sans-serif';ctx.fillStyle='#d32f2f';ctx.fillText('✖',x+84,y+16)}
  });
}
function drawPlayer(){
  const p=P,x=p.x-G.cam;
  ctx.fillStyle='rgba(0,0,0,.22)';ctx.beginPath();ctx.ellipse(x,GY+4,24-(GY-p.y)/12,7,0,0,6.3);ctx.fill();
  ctx.save();ctx.translate(x,p.y);ctx.scale(p.face,1);
  const run=p.onGround&&p.moving,bob=run?Math.abs(Math.sin(T*14))*3:0;
  const sw=p.onGround?(run?Math.sin(T*14)*10:0):9;
  ctx.fillStyle='#2b4fd8';rr(-12+sw,-34,11,26,4);rr(1-sw,-34,11,26,4);
  ctx.fillStyle='#6b3b1a';rr(-14+sw,-10,18,10,5);rr(-2-sw,-10,18,10,5);
  ctx.fillStyle='#2ea84a';rr(-17,-66-bob,34,38,10);
  ctx.fillStyle='#ffd23f';ctx.beginPath();ctx.arc(-8,-58-bob,3,0,6.3);ctx.arc(8,-58-bob,3,0,6.3);ctx.fill();
  ctx.fillStyle='#ff8a1f';
  if(p.celebrate){rr(-26,-92,9,34,4);rr(17,-92,9,34,4)}
  else if(p.shootT>0){rr(8,-62,36,10,5);
    const gr=ctx.createRadialGradient(50,-57,2,50,-57,16);gr.addColorStop(0,'#fff');gr.addColorStop(1,'rgba(0,200,255,0)');
    ctx.fillStyle=gr;ctx.beginPath();ctx.arc(50,-57,16,0,6.3);ctx.fill();ctx.fillStyle='#ff8a1f';rr(-24,-62,9,26,4)}
  else{const s=run?Math.sin(T*14)*8:0;rr(-24+s,-62-bob,9,26,4);rr(15-s,-62-bob,9,26,4)}
  ctx.fillStyle='#ffd3a8';ctx.beginPath();ctx.arc(0,-82-bob,21,0,6.3);ctx.fill();
  ctx.fillStyle='#e8321e';ctx.beginPath();ctx.arc(0,-86-bob,22,Math.PI,0);ctx.fill();rr(4,-92-bob,28,8,4);
  ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(-4,-98-bob,6,0,6.3);ctx.fill();
  ctx.fillStyle='#e8321e';ctx.font='900 9px sans-serif';ctx.textAlign='center';ctx.fillText('★',-4,-95-bob);
  ctx.fillStyle='#fff';ctx.beginPath();ctx.ellipse(8,-82-bob,6,7,0,0,6.3);ctx.fill();
  ctx.fillStyle='#222';ctx.beginPath();ctx.arc(10,-82-bob,3,0,6.3);ctx.fill();
  ctx.fillStyle='#ffb3a0';ctx.beginPath();ctx.arc(-2,-72-bob,5,0,6.3);ctx.fill();
  ctx.fillStyle='#f0a878';ctx.beginPath();ctx.arc(18,-78-bob,4,0,6.3);ctx.fill();
  ctx.strokeStyle='#7a2a10';ctx.lineWidth=2.5;ctx.beginPath();
  if(p.celebrate||p.shootT>0)ctx.arc(9,-72-bob,5,0,Math.PI);else ctx.arc(9,-74-bob,5,.15,Math.PI-.3);
  ctx.stroke();ctx.restore();
}
function drawPoseDots(){
  if(!lm||!vid.videoWidth)return;
  ctx.setTransform(1,0,0,1,0,0);
  const cw=cv.width,ch=cv.height,s=Math.max(cw/vid.videoWidth,ch/vid.videoHeight);
  const ox=(cw-vid.videoWidth*s)/2,oy=(ch-vid.videoHeight*s)/2;
  [[11,'#fff'],[12,'#fff'],[0,'#ffd23f'],[15,'#ff5ca8'],[16,'#00e5ff']].forEach(([i,c])=>{
    ctx.fillStyle=c;ctx.strokeStyle='#000';ctx.lineWidth=2;ctx.beginPath();
    ctx.arc(ox+(1-lm[i].x)*vid.videoWidth*s,oy+lm[i].y*vid.videoHeight*s,8,0,6.3);ctx.fill();ctx.stroke()});
}
function draw(){
  ctx.setTransform(sc,0,0,sc,0,0);ctx.clearRect(0,0,VW,H);
  drawBg();
  if(G.state==='menu'){return}
  const cam=G.cam;
  for(const r of G.rocks){const x=r.x-cam;ctx.fillStyle='#7a7a85';rr(x-26,GY-32,52,34,14);ctx.fillStyle='#a3a3ad';rr(x-18,GY-30,26,12,6)}
  for(const c of G.cw)if(!c.got)coinDraw(c.x-cam,c.y+Math.sin(T*3+c.x)*4);
  drawBlocks();
  for(const b of G.balls){const x=b.x-cam,gr=ctx.createRadialGradient(x,b.y,2,x,b.y,22);
    gr.addColorStop(0,'#fff');gr.addColorStop(.4,'#00e5ff');gr.addColorStop(1,'rgba(0,120,255,0)');
    ctx.fillStyle=gr;ctx.beginPath();ctx.arc(x,b.y,22,0,6.3);ctx.fill()}
  drawPlayer();
  for(const p of G.parts){ctx.globalAlpha=Math.max(0,p.life);ctx.fillStyle=p.c;ctx.beginPath();ctx.arc(p.x-cam,p.y,p.r,0,6.3);ctx.fill()}
  ctx.globalAlpha=1;
  for(const f of G.floats){ctx.globalAlpha=Math.min(1,f.life);ctx.font='900 44px sans-serif';ctx.textAlign='center';
    ctx.lineWidth=6;ctx.strokeStyle='#5a3600';ctx.strokeText(f.t,f.x-cam,f.y);ctx.fillStyle='#ffd23f';ctx.fillText(f.t,f.x-cam,f.y)}
  ctx.globalAlpha=1;
  drawPoseDots();
}

/* ---------- Kamera & model ---------- */
async function initCam(){
  if(!navigator.mediaDevices||!navigator.mediaDevices.getUserMedia)
    throw new Error('Browser tidak mendukung kamera. Buka lewat localhost atau HTTPS.');
  const s=await navigator.mediaDevices.getUserMedia({video:{width:640,height:480,facingMode:'user'},audio:false});
  vid.srcObject=s;await vid.play();vid.style.display='block';camOn=true;
}
async function initPose(){
  const V='https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14';
  const m=await import(V+'/vision_bundle.mjs');
  const fs=await m.FilesetResolver.forVisionTasks(V+'/wasm');
  const model='https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task';
  const mk=d=>m.PoseLandmarker.createFromOptions(fs,{baseOptions:{modelAssetPath:model,delegate:d},runningMode:'VIDEO',numPoses:1});
  try{pose=await mk('GPU')}catch(e){pose=await mk('CPU')}
}
function warn(t){const w=$('warn');w.textContent=t;w.style.display=t?'block':'none'}

let starting=false;
async function onStart(){
  if(starting)return;starting=true;
  try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();AC.resume()}catch(e){}
  const lt=$('loadTxt');let msgs=[];
  if(!camOn){
    lt.textContent='📷 Meminta izin kamera…';
    try{await initCam()}catch(e){
      msgs.push(e.name==='NotAllowedError'?'Izin kamera ditolak. Kamu tetap bisa main dengan keyboard (panah, Spasi, Enter). Izinkan kamera di pengaturan browser lalu muat ulang untuk gerakan tubuh.'
        :e.name==='NotFoundError'?'Kamera tidak ditemukan. Main dengan keyboard dulu ya.':'Kamera tidak bisa dipakai: '+(e.message||e.name)+'. Main dengan keyboard dulu ya.');
    }
  }
  if(camOn&&!pose){
    lt.textContent='🧠 Memuat model gerak tubuh…';
    try{await initPose()}catch(e){
      msgs.push('Model gerak tubuh gagal dimuat (periksa internet). Kamu tetap bisa main dengan keyboard.');console.error(e)}
  }
  warn(msgs.join(' '));
  setStat(pose?'🧍 Berdiri tegak sebentar…':'⌨️ Mode keyboard: panah, Spasi, Enter');
  lt.textContent='';starting=false;newGame();
}
function setPause(p){
  if(p&&G.state==='play'){G.state='pause';$('ovPause').classList.add('show');$('bPause').textContent='▶ Lanjutkan'}
  else if(!p&&G.state==='pause'){G.state='play';$('ovPause').classList.remove('show');$('bPause').textContent='⏸ Jeda';calib.length=0}
}

$('bStart').onclick=onStart;
$('bAgain').onclick=newGame;
$('bRetry').onclick=()=>{if(G.state!=='menu')newGame()};
$('bPause').onclick=()=>setPause(G.state==='play');
$('bResume').onclick=()=>setPause(false);
$('bSnd').onclick=()=>{snd=!snd;$('bSnd').textContent=snd?'🔊 Suara':'🔇 Senyap'};
addEventListener('keydown',e=>{
  if(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown',' ','Enter'].includes(e.key)&&G.state==='play')e.preventDefault();
  if(e.repeat)return;
  keys[e.key]=true;
  if(e.key===' '||e.key==='ArrowUp')pend.jump=true;
  if(e.key==='Enter'&&G.state==='play')pend.shoot=true;
});
addEventListener('keyup',e=>{keys[e.key]=false});
function resize(){cv.width=innerWidth;cv.height=innerHeight;sc=cv.height/H;VW=cv.width/sc}
addEventListener('resize',resize);resize();

let last=0;
function loop(ts){
  const dt=Math.min(.05,(ts-last)/1000||0);last=ts;
  if(G.state==='play'){poseStep();update(dt)}
  draw();requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
</script>
</body>
</html>
