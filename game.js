const realms={human:{name:'人界',sub:'烟火与四季流转之地',sigil:'人'},demon:{name:'魔界',sub:'赤月照耀的炽焰荒原',sigil:'魔'},immortal:{name:'仙界',sub:'浮云之上的琉璃天宫',sigil:'仙'},underworld:{name:'冥界',sub:'忘川彼岸的长夜国度',sigil:'冥'}};
const creatures=[['焰尾灵狐','🦊'],['玄甲幼龙','🐉'],['月影猫灵','🐈'],['青羽云雀','🕊️'],['山海麒麟','🦌'],['星辉水獭','🦦']];
const creatureArt={
  '焰尾灵狐':'picture/spirit-flame-fox.png',
  '玄甲幼龙':'picture/spirit-jade-dragon.png',
  '月影猫灵':'picture/spirit-moon-cat.png',
  '青羽云雀':'picture/spirit-jade-dragon.png',
  '山海麒麟':'picture/spirit-flame-fox.png',
  '星辉水獭':'picture/spirit-moon-cat.png'
};
const skills={intellect:['智力','洞察战局，提高暴击'],strength:['体力','强健筋骨，提高攻击'],spirit:['灵力','感应万物，提高治愈'],magic:['魔力','驾驭元素，提高术攻'],endurance:['耐力','坚韧不拔，提高防御']};
let state=JSON.parse(localStorage.getItem('spirit-realms-save')||'null')||{intro:0,dust:180,hasEgg:false,hatched:false,training:null,cards:[],realmVisits:[]};
const game=document.querySelector('#game');
const save=()=>{localStorage.setItem('spirit-realms-save',JSON.stringify(state)); sync();};
function sync(){document.querySelector('#dust').textContent=state.dust;document.querySelector('#card-count').textContent=state.cards.length;}
function toast(msg){const el=document.querySelector('#toast');el.textContent=msg;el.classList.add('show');setTimeout(()=>el.classList.remove('show'),2200)}
function setActive(view){document.querySelectorAll('#nav button').forEach(b=>b.classList.toggle('active',b.dataset.view===view));}
function intro(){setActive('');const lines=[['阿婆','小澈，车就快来了。去了城里，可别忘了山里的风。'],['小澈','我只是去上学，又不是不回来……那枚旧玉佩，我会好好带着。'],['？？？','四界的门已经苏醒。持契之人，你听见它们的呼唤了吗？']];let n=Math.min(state.intro,lines.length-1);game.innerHTML=`<section class="hero"><div class="dialogue"><span class="speaker">${lines[n][0]}</span><p>${lines[n][1]}</p><footer><span>序章 · 离乡之日</span><button data-action="dialogue">${n===lines.length-1?'循着声音前往 →':'继续 →'}</button></footer></div></section>`}
function landing(){setActive('');game.innerHTML=`<section class="hero"><div class="hero-copy"><span class="kicker">东方幻想 · 灵兽养成 · 策略卡牌</span><h1>四界灵契</h1><p>山风捎来一封没有署名的信，沉睡的古玉在掌心发亮。跨过人、魔、仙、冥四界，与你命中注定的灵兽缔结契约。</p><div class="hero-actions"><button class="primary" data-action="start">踏入四界</button><button class="secondary" data-view="cards">查看灵契</button></div></div></section>`}
function map(){setActive('map');game.innerHTML=`<section class="world-page"><div class="world-hud"><div><span class="kicker">THE FOUR REALMS · 四境共鸣</span><h1>选择你的旅途</h1><p>古玉指引着四条命运岔路。每一次远行，都会留下不同的灵契。</p></div><div class="chapter"><small>主线章节</small><b>第一章 · 赤月来客</b><span><i></i> 1 / 7</span></div></div><div class="world-map">${Object.entries(realms).map(([k,r])=>`<button class="map-point ${k} ${state.realmVisits.includes(k)?'visited':''}" data-realm="${k}"><span class="pulse"></span><span class="map-sigil">${r.sigil}</span><span class="map-label"><b>${r.name}</b><small>${r.sub}</small><em>${state.realmVisits.includes(k)?'再次探索':'踏入此界'} ›</em></span></button>`).join('')}<div class="map-compass"><span>北</span><b>✦</b><small>灵脉舆图</small></div></div><div class="world-foot"><span>◈ 鼠标悬停查看境域</span><span>本日灵息：稳定　✦ 适宜远行</span></div></section>`}
function realm(key){let r=realms[key];setActive('map');if(key!=='demon'){game.innerHTML=`<section class="page"><div class="page-head"><div><h1>${r.name}</h1><p>${r.sub}</p></div><button class="secondary" data-view="map">返回地图</button></div><div class="panel empty"><div style="font-size:72px">${key==='human'?'🏞️':key==='immortal'?'☁️':'🌙'}</div><h2>灵门尚未完全开启</h2><p>这里的故事正在苏醒。先去魔界寻找第一枚灵兽蛋吧。</p><button class="primary" data-realm="demon">前往魔界</button></div></section>`;return}
  game.innerHTML=`<section class="demon-page"><div class="demon-vignette"></div><button class="realm-back" data-view="map"><span>‹</span> 四界舆图</button><header class="realm-heading"><span class="kicker">DEMON REALM · 01</span><h1>赤烬魔域</h1><p>赤月照临之地，万物以力量铭刻真名</p></header><div class="demon-moon"></div><div class="emissary"><div class="horn left"></div><div class="horn right"></div><div class="mask">烬</div><div class="emissary-body"></div></div><div class="story-ribbon"><span>主线际遇</span><b>越过赤月之门</b><p>空气里有硫磺与夜昙的气味。断碑之前，戴着骨面具的使者已经等候多时。</p></div><aside class="quest-dialog"><div class="dialog-cap"><span>魔界使者</span><b>烬罗</b><small>EMBER ENVOY</small></div><blockquote>“玉佩选择了你。这枚尚未命名的生命，将因你的抉择显露真形。”</blockquote><div class="egg-sanctum"><div class="egg-aura"></div><div class="egg-display">${state.hasEgg?'✨🥚':'🥚'}</div><span>${state.hasEgg?'灵契共鸣完成':'未知生命体 · 共鸣中'}</span></div>${state.hasEgg?`<div class="quest-complete"><i>✓</i><div><b>灵兽蛋已收入行囊</b><small>返回云栖小筑，将它安置于孵化祭坛。</small></div></div><button class="demon-action" data-view="home">返回云栖小筑 <span>›</span></button>`:`<div class="reward"><span>际遇奖励</span><b>赤纹灵兽蛋 × 1</b></div><button class="demon-action" data-action="take-egg">接受灵兽蛋 <span>›</span></button>`}</aside><footer class="realm-lore"><span>赤烬关 · 魔界南境</span><i></i><small>危险度</small><b>◆ ◆ ◇ ◇ ◇</b></footer></section>`}
function home(){setActive('home');let tr=state.training,done=tr&&Date.now()>=tr.ends;let stage=!state.hasEgg?'empty':!state.hatched?'egg':tr?'training':'choose';let title=stage==='empty'?'祭坛正在沉睡':stage==='egg'?'赤纹灵兽蛋':stage==='training'?tr.name:'灵息初醒';let subtitle=stage==='empty'?'前往魔界，寻找与你共鸣的生命':stage==='egg'?'来自魔界 · 生命波动稳定':stage==='training'?`${skills[tr.skill][0]}专精 · 修炼中`:'为新生灵兽选择成长之路';game.innerHTML=`<section class="sanctuary"><div class="sanctuary-shade"></div><header class="sanctuary-title"><span class="kicker">YOUR SANCTUARY · 灵兽家园</span><h1>云栖小筑</h1><p>云深不知处，万灵归栖时</p></header><aside class="home-status glass-panel"><div class="panel-cap"><span>培育档案</span><small>BREEDING LOG</small></div><div class="bond-ring"><b>${state.cards.length}</b><span>已缔结灵契</span></div><dl><div><dt>家园等级</dt><dd>壹 · 初栖</dd></div><div><dt>灵息浓度</dt><dd class="good">充盈 ↑</dd></div><div><dt>环境加成</dt><dd>孵化速度 +5%</dd></div></dl><div class="daily"><span>今日照料</span><b>喂食灵露</b><small>可领取 20 灵尘</small></div></aside><main class="altar-stage ${stage}"><div class="spirit-orbit"><i></i><i></i><i></i></div><div class="altar-being">${stage==='empty'?'◇':stage==='egg'?'🥚':stage==='training'?tr.emoji:'✦'}</div><div class="altar-info"><small>${stage==='training'&&!done?'修炼进度':'CURRENT RESONANCE'}</small><h2>${title}</h2><p>${subtitle}</p>${stage==='empty'?`<button class="gold-button" data-realm="demon">前往赤烬魔域</button>`:stage==='egg'?`<button class="gold-button" data-action="hatch"><span>✦</span> 注入灵息 · 开始孵化</button>`:stage==='training'?`<div class="ritual-progress"><i style="width:${done?100:Math.max(4,100-(tr.ends-Date.now())/864000)}%"></i></div><div class="timer">${done?'灵契已经凝结，等待唤醒':remaining(tr.ends)}</div><button class="gold-button" data-action="finish">${done?'凝结灵契卡牌':'原型 · 立即完成修炼'}</button>`:`<p class="select-callout">请在右侧选择一种修炼方向</p>`}</div></main><aside class="training-panel glass-panel"><div class="panel-cap"><span>${stage==='choose'?'选择修炼':'培育指南'}</span><small>SPIRIT TRAINING</small></div>${stage==='choose'?`<p class="panel-copy">你选择的专精将提高对应能力，并影响灵契卡牌的战斗定位。</p><div class="skill-wheel">${Object.entries(skills).map(([k,v],i)=>`<button class="skill-node s${i+1}" data-skill="${k}"><span>${['◉','◆','✦','✧','⬡'][i]}</span><b>${v[0]}</b><small>${v[1].split('，')[1]||v[1]}</small></button>`).join('')}</div><button class="gold-button full" id="train" data-action="train" disabled>确认专精 · 修炼 24 小时</button>`:`<div class="guide-art">${stage==='training'?tr.emoji:'☯'}</div><h3>${stage==='training'?'灵脉正在运转':'万物皆有灵'}</h3><p class="panel-copy">不同境域的蛋会孕育不同族系。耐心照料，选择适合它的成长方向。</p><div class="tip"><b>培育提示</b><span>${stage==='empty'?'魔界使者正等待有缘之人。':stage==='egg'?'轻触中央按钮，让灵息唤醒蛋中的生命。':stage==='training'?'离开页面后，修炼倒计时仍会继续。':'每完成一次灵契，便可培育新的灵兽。'}</span></div>`}</aside><footer class="home-dock"><button data-view="cards"><span>▱</span><small>灵契图鉴</small><b>${state.cards.length}</b></button><button class="active"><span>⌂</span><small>孵化祭坛</small></button><button data-view="battle"><span>⚔</span><small>契斗阵列</small></button></footer></section>`}
function remaining(end){let s=Math.max(0,Math.ceil((end-Date.now())/1000)),h=Math.floor(s/3600),m=Math.floor(s%3600/60);return `${h}小时 ${m}分钟`}
function cardHTML(c,mini=false){let art=creatureArt[c.name]||creatureArt['焰尾灵狐'];return `<article class="spirit-card ${c.rarity==='珍稀'?'rare':''}"><div class="card-inner"><span class="card-crystal">◆</span><span class="rarity">${c.rarity} · ${c.realm}</span><div class="card-art"><img src="${art}" alt="${c.name}"></div><div class="card-name"><h3>${c.name}</h3><small>${skills[c.skill][0]}专精 · #${c.id}</small></div><div class="stats"><span>攻<b>${c.atk}</b></span><span>守<b>${c.def}</b></span><span>灵<b>${c.spi}</b></span></div></div></article>`}
function cards(){setActive('cards');game.innerHTML=`<section class="page"><div class="page-head"><div><h1>灵契图鉴</h1><p>已缔结 ${state.cards.length} / 5 张首战灵契</p></div><button class="primary" data-view="home">培育新灵兽</button></div><div class="card-grid">${state.cards.length?state.cards.map(cardHTML).join(''):`<div class="panel empty"><div style="font-size:62px">🀄</div><h2>还没有灵契卡牌</h2><p>孵化灵兽蛋、选择修炼方向，24 小时后它将凝结为卡牌。</p><button class="primary" data-view="home">前往云栖小筑</button></div>`}</div></section>`}
function battle(){setActive('battle');let ready=state.cards.length>=5;game.innerHTML=`<section class="page"><div class="page-head"><div><h1>四界竞技场</h1><p>五契成阵，以羁绊与策略决出胜负</p></div><span>${state.cards.length} / 5 已就绪</span></div><div class="battle-board panel"><div class="deck">${state.cards.slice(0,5).map(cardHTML).join('')||'<p>你的阵列还没有卡牌。</p>'}</div><div class="vs">VS</div><div class="deck" style="opacity:.55">${Array.from({length:5},(_,i)=>`<article class="spirit-card"><div class="card-inner"><div class="card-art">?</div><h3>未知灵契</h3><small>等待匹配</small></div></article>`).join('')}</div><button class="primary" data-action="battle" ${ready?'':'disabled'}>${ready?'寻找对手':'还需 '+(5-state.cards.length)+' 张灵契'}</button>${!ready?`<div class="dev-tools"><p class="hint">为了立即体验对战，可生成仅用于原型演示的测试卡牌。</p><button class="secondary" data-action="demo-cards">补齐测试卡牌</button></div>`:''}<div id="battle-log" class="battle-log" style="margin-top:18px">竞技场的铜铃尚未响起……</div></div></section>`}
function makeCard(skill){let [name,emoji]=creatures[Math.floor(Math.random()*creatures.length)],base=()=>Math.floor(35+Math.random()*31),stats={atk:base(),def:base(),spi:base()};if(skill==='strength')stats.atk+=28;if(skill==='endurance')stats.def+=28;if(skill==='spirit'||skill==='magic')stats.spi+=28;if(skill==='intellect'){stats.atk+=14;stats.spi+=14}return{id:Math.floor(1000+Math.random()*9000),name,emoji,skill,...stats,rarity:Math.max(stats.atk,stats.def,stats.spi)>85?'珍稀':'灵品',realm:'魔界'}}
document.addEventListener('click',e=>{let b=e.target.closest('[data-view],[data-action],[data-realm],[data-skill]');if(!b)return;if(b.dataset.view){views[b.dataset.view]();return}if(b.dataset.realm){let k=b.dataset.realm;if(!state.realmVisits.includes(k))state.realmVisits.push(k);save();realm(k);return}if(b.dataset.skill){document.querySelectorAll('[data-skill]').forEach(x=>x.classList.remove('selected'));b.classList.add('selected');let trainButton=document.querySelector('#train');trainButton.disabled=false;trainButton.dataset.trainingSkill=b.dataset.skill;return}let a=b.dataset.action;if(a==='home')landing();if(a==='start')intro();if(a==='dialogue'){state.intro++;save();state.intro>=3?map():intro()}if(a==='take-egg'){state.hasEgg=true;save();toast('获得：赤纹灵兽蛋');realm('demon')}if(a==='hatch'){state.hatched=true;save();toast('蛋壳中传来了回应');home()}if(a==='train'){let [name,emoji]=creatures[Math.floor(Math.random()*creatures.length)];state.training={skill:b.dataset.trainingSkill,name,emoji,ends:Date.now()+86400000};save();toast(`${name}开始了${skills[b.dataset.trainingSkill][0]}修炼`);home()}if(a==='finish'){state.cards.push(makeCard(state.training.skill));state.training=null;state.hatched=false;state.hasEgg=true;save();toast('新的灵契卡牌诞生了！');cards()}if(a==='demo-cards'){while(state.cards.length<5)state.cards.push(makeCard(Object.keys(skills)[state.cards.length%5]));save();battle();toast('测试阵列已补齐')}if(a==='battle'){let mine=state.cards.slice(0,5).reduce((s,c)=>s+c.atk+c.def+c.spi,0),enemy=Math.floor(650+Math.random()*250),win=mine>=enemy,log=document.querySelector('#battle-log');log.innerHTML=`你的阵列灵契值：${mine}<br>对手阵列灵契值：${enemy}<br><b>${win?'灵光贯穿战场——你赢得了本场契斗！':'对方阵法更胜一筹。调整专精，再来一战。'}</b>`;if(win){state.dust+=30;save()}}});
// Enhanced arena view with an owned-card roster and selectable battle deck.
function battle(){
  setActive('battle');
  state.battleDeck=Array.isArray(state.battleDeck)?state.battleDeck:state.cards.slice(0,5).map(c=>c.id);
  const selected=new Set(state.battleDeck);
  const owned=state.cards||[];
  const chosen=owned.filter(c=>selected.has(c.id)).slice(0,5);
  const ready=chosen.length>=5;
  const slot=(c)=>c?cardHTML(c):'<article class="spirit-card empty-slot"><div class="card-inner"><div class="card-art">+</div><h3>选择灵契</h3><small>从右侧加入</small></div></article>';
  game.innerHTML=`<section class="page"><div class="page-head"><div><h1>四界竞技场</h1><p>五契成阵，以羁绊与策略决出胜负</p></div><span>${chosen.length} / 5 已就绪</span></div><div class="arena-layout"><div class="battle-board panel"><div class="deck player-deck">${Array.from({length:5},(_,i)=>slot(chosen[i])).join('')}</div><div class="vs">VS</div><div class="deck enemy-deck" style="opacity:.55">${Array.from({length:5},()=>`<article class="spirit-card"><div class="card-inner"><div class="card-art">?</div><h3>未知灵契</h3><small>等待匹配</small></div></article>`).join('')}</div><button class="primary" data-action="battle" ${ready?'':'disabled'}>${ready?'寻找对手':'还需 '+(5-chosen.length)+' 张灵契'}</button>${!ready?`<div class="dev-tools"><p class="hint">从右侧选择至少 5 张灵契，组成你的出战阵列。</p><button class="secondary" data-action="demo-cards">补齐测试卡牌</button></div>`:''}<div id="battle-log" class="battle-log" style="margin-top:18px">竞技场的铜铃尚未响起……</div></div><aside class="arena-roster"><div class="roster-title"><b>我的灵契</b><small>点击选择出战 · ${owned.length} 张</small></div><div class="roster-list">${owned.length?owned.map(c=>`<div class="roster-card ${selected.has(c.id)?'selected':''}" data-card-select="${c.id}">${cardHTML(c,true)}</div>`).join(''):'<div class="roster-empty">还没有可用卡牌<br>先去云栖小筑培育灵兽吧。</div>'}</div></aside></div></section>`;
}

// Stable AI opponent deck for the arena preview.
const aiDeck=Array.from({length:5},(_,i)=>makeCard(Object.keys(skills)[i%Object.keys(skills).length]));
const renderBattle=battle;
battle=function(){
  renderBattle();
  const enemy=document.querySelector('.enemy-deck');
  if(enemy)enemy.innerHTML=aiDeck.map(c=>cardHTML(c,true)).join('');
};

const views={map,home,cards,battle};sync();landing();

// Slay-the-Spire-inspired turn loop: draw, spend energy, resolve intent, end turn.
let spireRun=null;
function drawSpireCards(){
  while(spireRun.hand.length<3){
    if(!spireRun.draw.length){spireRun.draw=spireRun.discard.splice(0);}
    if(!spireRun.draw.length)break;
    spireRun.hand.push(spireRun.draw.shift());
  }
}
function ensureSpireRun(){
  const ids=Array.isArray(state.battleDeck)?state.battleDeck:[];
  const deck=state.cards.filter(c=>ids.includes(c.id)).slice(0,5);
  const key=ids.join(',');
  if(!spireRun||spireRun.key!==key){
    spireRun={key,deck,draw:[...deck],hand:[],discard:[],energy:3,turn:1,playerHp:100,playerMax:100,block:0,enemyHp:100,enemyMax:100,enemyIntent:10,log:'战斗开始：观察敌人的意图，选择合适的灵契出牌。'};
    drawSpireCards();
  }
  return spireRun;
}
function renderSpire(){
  const r=ensureSpireRun(), hand=r.hand;
  const hp=(r.playerHp/r.playerMax*100), ehp=(r.enemyHp/r.enemyMax*100);
  const ended=r.playerHp<=0||r.enemyHp<=0;
  game.innerHTML=`<section class="page"><div class="page-head"><div><h1>四界竞技场</h1><p>回合制灵契战 · 观察意图，管理能量，构筑你的胜机</p></div><span>第 ${r.turn} 回合</span></div><section class="spire-arena ${r.turn % 2===0?'turn-enemy':''}"><header class="spire-topbar"><div class="spire-run-title"><small>ASCENSION RUN · 灵契试炼</small><b>赤烬阶梯 · 第一层</b></div><div class="spire-stats"><div class="spire-stat"><small>生命</small><b>${r.playerHp}/${r.playerMax}</b></div><div class="spire-stat"><small>护盾</small><b>${r.block}</b></div><div class="spire-stat"><small>能量</small><b>${r.energy}/3</b></div></div></header><div class="spire-combat"><div class="spire-side spire-player"><div class="spire-orb">✦</div><h3>你的灵契阵列</h3><small>五契共鸣 · ${r.deck.length} 张</small><div class="spire-hp"><i style="width:${hp}%"></i></div></div><div class="spire-cross">VS<i></i><small>回合 ${r.turn}</small></div><div class="spire-side spire-enemy"><div class="spire-orb">🔥</div><h3>AI · 赤烬守卫</h3><small>意图：${r.enemyIntent} 点攻击</small><div class="spire-hp"><i style="width:${ehp}%"></i></div><div class="spire-intent">⚔ 下回合攻击 ${r.enemyIntent}</div></div></div><div class="spire-hand"><div class="spire-hand-head"><b>手牌 · ${hand.length} / 3</b><small>抽牌堆 ${r.draw.length}　弃牌堆 ${r.discard.length}</small></div><div class="spire-hand-list">${hand.length?hand.map(c=>`<button class="spire-card-btn" data-spire-card="${c.id}" ${ended||r.energy<1?'disabled':''}>${cardHTML(c,true)}</button>`).join(''):'<div class="roster-empty">手牌已空，结束回合以重新抽牌。</div>'}</div></div><footer class="spire-footer"><div class="spire-log">${r.log}</div><button class="spire-end" data-action="spire-end" ${ended?'disabled':''}>结束回合 · 抽牌</button></footer></section></section>`;
}
function battleSpire(){ensureSpireRun();renderSpire()}
battle=battleSpire;views.battle=battleSpire;

document.addEventListener('click',e=>{
  const card=e.target.closest('[data-spire-card]');
  if(card){
    const r=ensureSpireRun(),id=Number(card.dataset.spireCard),idx=r.hand.findIndex(c=>c.id===id);
    if(idx<0||r.energy<1||r.playerHp<=0||r.enemyHp<=0)return;
    const c=r.hand.splice(idx,1)[0],damage=Math.max(6,Math.round((c.atk+c.spi)/20)),block=Math.max(1,Math.round(c.def/22));
    r.energy-=1;r.enemyHp=Math.max(0,r.enemyHp-damage);r.block+=block;r.discard.push(c);r.log=`${c.name} 发动灵契共鸣，造成 ${damage} 点伤害并获得 ${block} 点护盾！`;
    if(r.enemyHp<=0)r.log+='　赤烬守卫已被击破，胜利！';
    renderSpire();return;
  }
  if(e.target.closest('[data-action="spire-end"]')){
    const r=ensureSpireRun();if(r.playerHp<=0||r.enemyHp<=0)return;
    const taken=Math.max(0,r.enemyIntent-r.block);r.playerHp=Math.max(0,r.playerHp-taken);r.block=0;
    r.discard.push(...r.hand);r.hand=[];r.energy=3;r.turn+=1;r.enemyIntent=8+Math.floor(Math.random()*8)+r.turn;
    drawSpireCards();r.log=taken?`赤烬守卫发动攻击，你承受 ${taken} 点伤害。新回合开始，抽取 ${r.hand.length} 张灵契。`:'护盾抵挡了本次攻击。新回合开始，抽取新的灵契。';
    if(r.playerHp<=0)r.log='你的灵契阵列倒下了……重新整理卡组，再来一次。';
    renderSpire();
  }
});

// Keep the browser collection aligned with the Godot cap of 100 cards.
const collectionLimit = 100;
const collectionLabelObserver = new MutationObserver(() => {
  const heading = document.querySelector('.page-head h1');
  const label = document.querySelector('.page-head p');
  if (heading && label && document.querySelector('.card-grid')) {
    const next = `已缔结 ${state.cards.length} / ${collectionLimit} 张灵契 · 可分页浏览`;
    if (label.textContent !== next) label.textContent = next;
  }
});
collectionLabelObserver.observe(game, {childList:true, subtree:true});
document.addEventListener('click', e => {
  const finishButton = e.target.closest('[data-action="finish"]');
  if (!finishButton || state.cards.length < collectionLimit) return;
  e.stopImmediatePropagation();
  toast('灵契图鉴已满 100 张');
}, true);

/* Combat rules pass: five-card draws, discard/exhaust, transparent intent and statuses. */
function cardCost(c){return c.skill==='magic'?2:c.skill==='intellect'?0:1}
function isAttackCard(c){return ['strength','intellect','magic','spirit'].includes(c.skill)}
function cardTitle(c){return c.status?'灼伤':c.name}
function cardView(c){if(c.status)return `<article class="status-card"><b>灼伤</b><small>状态牌 · 无法打出</small></article>`;return cardHTML(c,true)}
function nextIntent(r){const cycle=r.turn%3;if(cycle===1)return{type:'attack',value:10+Math.floor(r.turn/2)*2};if(cycle===2)return{type:'defend',value:8+Math.floor(r.turn/3)*2};return{type:'debuff',value:1}}
function drawCards(r,count=5){
  for(let i=0;i<count;i++){
    if(!r.draw.length){r.draw=r.discard.splice(0).sort(()=>Math.random()-.5)}
    if(!r.draw.length)break;r.hand.push(r.draw.shift())
  }
}
function initRulesRun(){
  if(!Array.isArray(state.battleDeck)||!state.battleDeck.length)state.battleDeck=state.cards.slice(0,5).map(c=>c.id);
  const ids=state.battleDeck,deck=state.cards.filter(c=>ids.includes(c.id)).slice(0,5),key=ids.join(',');
  if(!spireRun||spireRun.key!==key){
    spireRun={key,deck,draw:[...deck].sort(()=>Math.random()-.5),discard:[],exhaust:[],hand:[],energy:3,turn:1,playerHp:100,playerMax:100,block:0,strength:0,weak:0,vulnerable:0,frail:0,enemyHp:110,enemyMax:110,enemyBlock:0,enemyIntent:{type:'attack',value:10},attacksPlayed:0,potions:1,relicName:'回响棱镜',log:'观察敌人意图：本回合预计攻击 10 点。'}
    drawCards(spireRun,5)
  }
  return spireRun
}
function intentText(i){if(i.type==='attack')return `⚔ 攻击 ${i.value}`;if(i.type==='defend')return `◇ 防御 +${i.value} 格挡`;return '✦ 施加虚弱 1 层'}
function renderRules(){
  const r=initRulesRun(),ended=r.playerHp<=0||r.enemyHp<=0,hp=Math.max(0,r.playerHp/r.playerMax*100),ehp=Math.max(0,r.enemyHp/r.enemyMax*100);
  const hand=r.hand.map(c=>`<button class="spire-card-btn ${c.status?'is-status':''}" data-rules-card="${c.id}" ${ended||c.status||r.energy<cardCost(c)?'disabled':''}><span class="card-cost">${c.status?'—':cardCost(c)}</span>${cardView(c)}</button>`).join('');
  game.innerHTML=`<section class="page"><div class="page-head"><div><h1>四界竞技场</h1><p>灵契试炼 · 读懂意图，计算能量，掌控每一个回合</p></div><span>第 ${r.turn} 回合</span></div><section class="spire-arena rules-arena ${r.fx?'fx-'+r.fx.type:''}">${r.fx?`<div class="combat-fx"><b>${r.fx.value}</b><small>${r.fx.type==='hit'?'灵契暴击':'受到伤害'}</small><i></i><i></i><i></i><i></i></div>`:''}<header class="spire-topbar"><div class="spire-run-title"><small>ASCENSION RUN · 战斗规则</small><b>赤烬阶梯 · 第一层</b></div><div class="spire-stats"><div class="spire-stat"><small>生命</small><b>${r.playerHp}/${r.playerMax}</b></div><div class="spire-stat"><small>格挡</small><b>${r.block}</b></div><div class="spire-stat"><small>能量</small><b>${r.energy}/3</b></div><button class="potion-btn" data-rules-potion ${r.potions?'':'disabled'}>药水 ${r.potions}</button></div></header><div class="spire-combat"><div class="spire-side spire-player"><div class="spire-orb">✦</div><h3>你的灵契阵列</h3><small>力量 ${r.strength} · 虚弱 ${r.weak} · 易伤 ${r.vulnerable}</small><div class="spire-hp"><i style="width:${hp}%"></i></div></div><div class="spire-cross">VS<i></i><small>能量 3 · 抽牌 5</small></div><div class="spire-side spire-enemy"><div class="spire-orb">🔥</div><h3>AI · 赤烬守卫</h3><small>格挡 ${r.enemyBlock}</small><div class="spire-hp"><i style="width:${ehp}%"></i></div><div class="spire-intent">${intentText(r.enemyIntent)}</div></div></div><div class="spire-hand"><div class="spire-hand-head"><b>手牌 · ${r.hand.length} / 10</b><small>抽牌堆 ${r.draw.length}　弃牌堆 ${r.discard.length}　消耗 ${r.exhaust.length}</small></div><div class="spire-hand-list">${hand||'<div class="roster-empty">手牌已空，结束回合以抽取 5 张牌。</div>'}</div></div><footer class="spire-footer"><div class="spire-log">${r.log}<br><small>遗物：${r.relicName} · 每打出 3 张攻击牌获得 4 格挡</small></div><button class="spire-end" data-rules-end ${ended?'disabled':''}>结束回合 · 弃牌并抽 5 张</button></footer></section></section>`
}
function playRulesCard(id){
  const r=initRulesRun(),idx=r.hand.findIndex(c=>String(c.id)===String(id));if(idx<0||r.playerHp<=0||r.enemyHp<=0)return;const c=r.hand[idx],cost=cardCost(c);if(c.status||r.energy<cost)return;
  r.hand.splice(idx,1);r.energy-=cost;let text='';
  if(isAttackCard(c)){let dmg=Math.max(1,Math.round(c.atk/7)+r.strength);if(r.weak)dmg=Math.floor(dmg*.75);if(c.skill==='magic')r.enemyBlock=0;let dealt=Math.max(0,dmg-r.enemyBlock);r.enemyBlock=Math.max(0,r.enemyBlock-dmg);r.enemyHp=Math.max(0,r.enemyHp-dealt);r.attacksPlayed++;text=`${cardTitle(c)}造成 ${dealt} 点伤害`}
  if(c.skill==='endurance'){let gain=Math.max(1,Math.round(c.def/7));if(r.frail)gain=Math.floor(gain*.75);r.block+=gain;text=`${cardTitle(c)}获得 ${gain} 点格挡`}
  if(c.skill==='spirit'){r.block+=4;text+='，并获得 4 点格挡'}
  if(c.skill==='intellect')r.strength+=1;
  if(c.skill==='magic')r.vulnerable=Math.max(r.vulnerable,1);
  if(r.attacksPlayed%3===0){r.block+=4;text+='；遗物“回响棱镜”触发，获得 4 格挡'}
  if(c.skill==='magic')r.exhaust.push(c);else r.discard.push(c);r.log=`打出 ${cardTitle(c)}（${cost} 能量）：${text}。`;r.fx={type:'hit',value:dealt||0};renderRules();setTimeout(()=>{if(spireRun===r){r.fx=null;renderRules()}},850)
}
function endRulesTurn(){
  const r=initRulesRun();if(r.playerHp<=0||r.enemyHp<=0)return;
  const i=r.enemyIntent;if(i.type==='attack'){let dmg=i.value;if(r.vulnerable)dmg=Math.floor(dmg*1.5);const taken=Math.max(0,dmg-r.block);r.playerHp=Math.max(0,r.playerHp-taken);r.log=`敌人执行意图：攻击 ${dmg}。你的格挡吸收后受到 ${taken} 点伤害。`}
  if(i.type==='defend'){r.enemyBlock+=i.value;r.log=`敌人执行意图：获得 ${i.value} 点格挡。`}
  if(i.type==='debuff'){r.weak=1;r.frail=1;r.hand.push({id:'burn-'+Date.now(),name:'灼伤',status:true,skill:'curse',atk:0,def:0,spi:0});r.log='敌人执行意图：施加虚弱与脆弱，并将一张灼伤加入弃牌堆。'}
  r.discard.push(...r.hand);r.hand=[];r.energy=3;r.block=0;r.turn++;r.enemyIntent=nextIntent(r);if(r.weak)r.weak--;if(r.frail)r.frail--;drawCards(r,5);r.fx={type:'enemy',value:taken};renderRules();setTimeout(()=>{if(spireRun===r){r.fx=null;renderRules()}},850)
}
function useRulesPotion(){const r=initRulesRun();if(!r.potions)return;r.potions--;r.energy=3;r.log='使用能量药水：能量恢复至 3 点。';renderRules()}
battle=()=>{initRulesRun();renderRules()};views.battle=battle;
document.addEventListener('click',e=>{const c=e.target.closest('[data-rules-card]');if(c){playRulesCard(c.dataset.rulesCard);return}if(e.target.closest('[data-rules-end]')){endRulesTurn();return}if(e.target.closest('[data-rules-potion]'))useRulesPotion()});

/* Video-faithful battlefield: characters on stage, multiple enemies, fanned hand and target selection. */
function ensureVideoRun(){
  const r=initRulesRun();
  // Keep a fresh install immediately playable without polluting the saved collection.
  if(!r.deck.length){
    const demoSkills=['strength','endurance','magic','spirit','intellect'];
    r.deck=demoSkills.map(makeCard);
    r.draw=[...r.deck].sort(()=>Math.random()-.5);
    r.hand=[];
    drawCards(r,5);
  }
  if(!r.enemies)r.enemies=[
    {name:'炽羽魔鸦',hp:44,max:44,block:0,intent:{type:'attack',value:7},img:'picture/spirit-moon-cat.png'},
    {name:'赤纹妖犬',hp:58,max:58,block:0,intent:{type:'debuff',value:1},img:'picture/spirit-flame-fox.png'},
    {name:'赤烬守卫',hp:110,max:110,block:0,intent:{type:'attack',value:12},img:'picture/spirit-jade-dragon.png'}
  ];
  return r
}
function enemyIntentMarkup(e){if(e.hp<=0)return'<span class="intent-dead">已击破</span>';if(e.intent.type==='attack')return`<span class="intent-attack">⚔ ${e.intent.value}</span>`;if(e.intent.type==='defend')return`<span class="intent-defend">◇ ${e.intent.value}</span>`;return'<span class="intent-debuff">✦ 虚弱</span>'}
function renderVideoBattle(){
  const r=ensureVideoRun(),alive=r.enemies.filter(e=>e.hp>0),ended=r.playerHp<=0||!alive.length;
  const hand=r.hand.map((c,i)=>{const attack=!c.status&&isAttackCard(c);return`<button class="fan-card ${attack?'attack-card':'skill-card'} ${r.pending===c.id?'selected':''}" style="--i:${i};--n:${r.hand.length}" data-video-card="${c.id}" ${ended||c.status||r.energy<cardCost(c)?'disabled':''}><span class="card-cost">${c.status?'—':cardCost(c)}</span>${cardView(c)}</button>`}).join('');
  const playerArt=r.deck[0]?(creatureArt[r.deck[0].name]||'picture/spirit-jade-dragon.png'):'picture/spirit-jade-dragon.png';
  game.innerHTML=`<section class="video-battle-page"><div class="video-arena ${r.pending?'targeting':''} ${r.videoFx?'video-'+r.videoFx.type:''}"><header class="battle-statusbar"><div><b>灵契使 · 小澈</b><span>♥ ${r.playerHp}/${r.playerMax}</span></div><div class="relic-strip"><i>◆</i><i>◇</i><i>✦</i><i>☯</i><small>${r.relicName}</small></div><button data-video-potion ${r.potions?'':'disabled'}>药水 × ${r.potions}</button></header>${r.banner?`<div class="turn-banner">${r.banner}</div>`:''}${r.videoFx?`<div class="video-damage"><b>${r.videoFx.value}</b><span>${r.videoFx.label}</span></div>`:''}<main class="battle-stage"><div class="combatant player-unit"><div class="unit-art"><img src="${playerArt}" alt="玩家灵兽"></div><div class="unit-state"><b>${r.deck[0]?.name||'契约灵兽'}</b><div class="unit-hp"><i style="width:${Math.max(0,r.playerHp/r.playerMax*100)}%"></i><span>${r.playerHp}/${r.playerMax}</span></div><div class="status-icons"><em>格挡 ${r.block}</em>${r.weak?'<em>虚弱</em>':''}${r.frail?'<em>脆弱</em>':''}</div></div></div><div class="enemy-line">${r.enemies.map((e,i)=>`<button class="combatant enemy-unit ${e.hp<=0?'defeated':''}" data-video-target="${i}" ${r.pending&&e.hp>0?'':'disabled'}><div class="enemy-intent">${enemyIntentMarkup(e)}</div><div class="unit-art"><img src="${e.img}" alt="${e.name}"></div><div class="unit-state"><b>${e.name}</b><div class="unit-hp"><i style="width:${Math.max(0,e.hp/e.max*100)}%"></i><span>${e.hp}/${e.max}</span></div><div class="status-icons">${e.block?`<em>格挡 ${e.block}</em>`:''}</div></div></button>`).join('')}</div><div class="target-arrow"><i></i><i></i><i></i><i></i><i></i><i></i><b>➤</b></div></main><div class="battle-controls"><div class="energy-orb"><b>${r.energy}</b><small>/ 3</small></div><div class="pile draw-pile"><b>${r.draw.length}</b><small>抽牌堆</small></div><div class="fan-hand">${hand}</div><div class="pile discard-pile"><b>${r.discard.length}</b><small>弃牌堆</small></div><button class="video-end-turn" data-video-end ${ended?'disabled':''}>结束回合</button></div><div class="battle-message">${r.pending?'选择一个敌人作为攻击目标':r.log}</div></div></section>`;
  if(r.banner)setTimeout(()=>{if(spireRun===r){r.banner='';renderVideoBattle()}},700)
}
function videoCardSelect(id){
  const r=ensureVideoRun(),c=r.hand.find(x=>String(x.id)===String(id));if(r.locked||!c||c.status||r.energy<cardCost(c))return;
  if(isAttackCard(c)){r.pending=c.id;r.log=`已选择 ${c.name}，请选择攻击目标。`;renderVideoBattle();return}
  const cost=cardCost(c),gain=Math.max(1,Math.round(c.def/7));r.energy-=cost;r.block+=r.frail?Math.floor(gain*.75):gain;r.hand.splice(r.hand.indexOf(c),1);r.discard.push(c);r.log=`${c.name}：获得 ${gain} 点格挡。`;renderVideoBattle()
}
function videoTarget(index){
  const r=ensureVideoRun(),c=r.hand.find(x=>x.id===r.pending),enemy=r.enemies[index];if(r.locked||!c||!enemy||enemy.hp<=0)return;
  const cost=cardCost(c);let dmg=Math.max(1,Math.round(c.atk/7)+r.strength);if(r.weak)dmg=Math.floor(dmg*.75);const dealt=Math.max(0,dmg-enemy.block);enemy.block=Math.max(0,enemy.block-dmg);enemy.hp=Math.max(0,enemy.hp-dealt);r.energy-=cost;r.hand.splice(r.hand.indexOf(c),1);if(c.skill==='magic')r.exhaust.push(c);else r.discard.push(c);r.pending=null;r.videoFx={type:'hit',value:dealt,label:c.name,target:index};r.log=`${c.name} 命中 ${enemy.name}，造成 ${dealt} 点伤害。`;renderVideoBattle();setTimeout(()=>{if(spireRun===r){r.videoFx=null;renderVideoBattle()}},720)
}
function videoEndTurn(){
  const r=ensureVideoRun();if(r.locked)return;
  r.locked=true;r.pending=null;r.energy=0;r.discard.push(...r.hand);r.hand=[];r.banner='敌方回合';r.log='敌人正在依次执行公开意图……';renderVideoBattle();
  const actors=r.enemies.filter(e=>e.hp>0);let cursor=0;
  const act=()=>{
    if(spireRun!==r)return;
    if(cursor>=actors.length){
      r.videoFx=null;r.energy=3;r.block=0;r.turn++;if(r.weak)r.weak--;if(r.frail)r.frail--;drawCards(r,5);r.banner='玩家回合';r.locked=false;r.log='观察意图，规划 3 点能量与 5 张手牌。';renderVideoBattle();return;
    }
    const enemy=actors[cursor++],intent=enemy.intent;
    if(intent.type==='attack'){
      const absorbed=Math.min(r.block,intent.value),taken=Math.max(0,intent.value-r.block);r.block=Math.max(0,r.block-intent.value);r.playerHp=Math.max(0,r.playerHp-taken);r.videoFx={type:'enemy',value:taken,label:`${enemy.name} · 攻击`};r.log=`${enemy.name} 发动攻击：格挡吸收 ${absorbed}，受到 ${taken} 点伤害。`;
    }else if(intent.type==='defend'){
      enemy.block+=intent.value;r.videoFx={type:'hit',value:intent.value,label:`${enemy.name} · 格挡`};r.log=`${enemy.name} 获得 ${intent.value} 点格挡。`;
    }else{
      r.weak=2;r.frail=2;r.videoFx={type:'enemy',value:'✦',label:`${enemy.name} · 虚弱`};r.log=`${enemy.name} 施加虚弱与脆弱。`;
    }
    enemy.intent=nextIntent({...r,turn:r.turn+cursor});renderVideoBattle();setTimeout(act,720);
  };
  setTimeout(act,720)
}
function videoPotion(){const r=ensureVideoRun();if(r.locked||!r.potions)return;r.potions--;r.energy=Math.min(5,r.energy+2);r.log='使用能量药水：恢复 2 点能量。';renderVideoBattle()}
battle=()=>{const r=ensureVideoRun();if(!r.banner)r.banner='玩家回合';renderVideoBattle()};views.battle=battle;
document.addEventListener('click',e=>{const card=e.target.closest('[data-video-card]'),target=e.target.closest('[data-video-target]');if(card){e.stopImmediatePropagation();videoCardSelect(card.dataset.videoCard);return}if(target){e.stopImmediatePropagation();videoTarget(Number(target.dataset.videoTarget));return}if(e.target.closest('[data-video-end]')){e.stopImmediatePropagation();videoEndTurn();return}if(e.target.closest('[data-video-potion]')){e.stopImmediatePropagation();videoPotion()}},true);

// Select / deselect cards in the owned roster.
document.addEventListener('click',e=>{
  const item=e.target.closest('[data-card-select]');
  if(!item)return;
  const id=Number(item.dataset.cardSelect);
  state.battleDeck=Array.isArray(state.battleDeck)?state.battleDeck:[];
  const index=state.battleDeck.indexOf(id);
  if(index>=0)state.battleDeck.splice(index,1);
  else if(state.battleDeck.length<5)state.battleDeck.push(id);
  else {toast('出战阵列最多容纳 5 张灵契');return}
  save();battle();
});

// Capture selection before the legacy combat resolver sums the first five cards.
document.addEventListener('click',e=>{
  if(!e.target.closest('[data-action="battle"]'))return;
  const ids=Array.isArray(state.battleDeck)?state.battleDeck:[];
  if(ids.length<5)return;
  const chosen=state.cards.filter(c=>ids.includes(c.id));
  const rest=state.cards.filter(c=>!ids.includes(c.id));
  state.cards=[...chosen,...rest];
},{capture:true});

// Arena choreography: stage the result so players can read the exchange.
document.addEventListener('click',e=>{
  const trigger=e.target.closest('[data-action="battle"]');
  if(!trigger)return;
  const board=document.querySelector('.battle-board');
  const log=document.querySelector('#battle-log');
  if(!board||!log)return;
  const finalText=log.innerHTML;
  board.classList.remove('battle-running','battle-hit');
  log.classList.remove('battle-live');
  void board.offsetWidth;
  board.classList.add('battle-running');
  log.innerHTML='<b>铜铃已鸣 · 灵契阵列展开……</b><br><span>双方灵息正在锁定目标</span>';
  setTimeout(()=>{board.classList.add('battle-hit');log.classList.add('battle-live');log.innerHTML='<b>灵光交锋！</b><br><span>你的主阵灵契发动共鸣攻击，战场灵压骤升。</span>'},1100);
  setTimeout(()=>{log.classList.remove('battle-live');log.innerHTML=finalText;board.classList.remove('battle-running','battle-hit')},2300);
});
