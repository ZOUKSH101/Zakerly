import 'dart:convert';

import '../util.dart';

// Canned animations standing in for model output. Each obeys the same
// contract the real prompt imposes on Gemini (see Prompts.animationSystem):
// one self-contained document, no network, responsive fill, a step-by-step
// player with Back/Play/Next controls and a caption per step, light/dark via
// prefers-color-scheme, and no em or en dashes in any copy.

const _baseCss = r'''
:root{
  --bg:#ffffff;--fg:#1c1c1e;--muted:#6e6e73;--card:#f5f5f7;--border:#d8d8dc;
  --accent:#C2255C;--accent-weak:#FBE7EE;
}
@media (prefers-color-scheme: dark){
  :root{
    --bg:#0b0b0f;--fg:#f5f5f7;--muted:#9a9aa0;--card:#1c1c1e;--border:#3a3a3c;
    --accent:#D6336C;--accent-weak:#3A1522;
  }
}
*{box-sizing:border-box}
html,body{margin:0;width:100%;height:100%;background:var(--bg);color:var(--fg);
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  overflow:hidden}
.stage{position:absolute;inset:0;display:grid;grid-template-rows:auto 1fr auto auto;
  gap:1.2vh;padding:3vh 4vw}
h1{margin:0;font-size:clamp(20px,3.8vmin,38px);font-weight:650;letter-spacing:-.01em;line-height:1.15}
.sub{color:var(--muted);font-size:clamp(13px,2vmin,18px);margin-top:.35em}
main{min-height:0;display:flex;align-items:center;justify-content:center}
.caption{margin:0;min-height:1.4em;font-size:clamp(14px,2.2vmin,20px)}
.controls{display:flex;align-items:center;gap:1.6vw}
.controls button{font:inherit;font-size:clamp(13px,1.6vmin,15px);border:1px solid var(--border);
  background:var(--card);color:var(--fg);border-radius:10px;padding:.55em 1.2em;cursor:pointer}
.controls button:hover:not(:disabled){border-color:var(--accent)}
.controls button:disabled{opacity:.4;cursor:default}
.controls button#play{background:var(--accent);border-color:var(--accent);color:#fff}
.counter{margin-left:auto;color:var(--muted);font-size:clamp(12px,1.5vmin,14px)}
''';

const _shellTemplate = r'''
<!doctype html><html><head><meta charset="utf-8"><style>
__BASE_CSS__
__CSS__
</style></head><body>
<div class="stage">
  <div><h1>__TITLE__</h1><div class="sub">__SUB__</div></div>
  <main>__BODY__</main>
  <p class="caption" id="caption" aria-live="polite"></p>
  <div class="controls" role="group" aria-label="Step controls">
    <button id="back" type="button" aria-label="Back">Back</button>
    <button id="play" type="button" aria-label="Play">Play</button>
    <button id="next" type="button" aria-label="Next">Next</button>
    <div class="counter" id="counter"></div>
  </div>
</div>
<script>
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
const captions = __CAPTIONS__;
const total = captions.length;
__SETUP__
let i = 0, playing = false, timer = null;
const els = {
  back: document.getElementById('back'),
  play: document.getElementById('play'),
  next: document.getElementById('next'),
  counter: document.getElementById('counter'),
  caption: document.getElementById('caption')
};
function show(n) {
  i = Math.max(0, Math.min(total - 1, n));
  applyStep(i);
  els.caption.textContent = captions[i];
  els.counter.textContent = 'Step ' + (i + 1) + ' of ' + total;
  els.back.disabled = i === 0;
  els.next.disabled = i === total - 1;
  if (i === total - 1) { pause(); }
}
function next() { show(i + 1); }
function back() { show(i - 1); }
function pause() {
  playing = false;
  els.play.textContent = 'Play';
  els.play.setAttribute('aria-label', 'Play');
  if (timer) { clearInterval(timer); }
  timer = null;
}
function play() {
  if (i === total - 1) { return; }
  playing = true;
  els.play.textContent = 'Pause';
  els.play.setAttribute('aria-label', 'Pause');
  timer = setInterval(function () {
    if (i < total - 1) { next(); } else { pause(); }
  }, 1800);
}
function toggle() { if (playing) { pause(); } else { play(); } }
els.back.addEventListener('click', back);
els.next.addEventListener('click', next);
els.play.addEventListener('click', toggle);
document.addEventListener('keydown', function (e) {
  if (e.key === 'ArrowRight') { e.preventDefault(); next(); }
  else if (e.key === 'ArrowLeft') { e.preventDefault(); back(); }
  else if (e.key === ' ') { e.preventDefault(); toggle(); }
});
show(0);
</script>
</body></html>''';

/// JSON-encodes [items] for direct embedding inside a `<script>` block: also
/// neutralises `</script` and the JS line-terminator code points U+2028 and
/// U+2029, which are legal in JSON strings but would either break out of the
/// script tag or truncate the statement when parsed as JS source.
String _jsStringArray(List<String> items) {
  final s = jsonEncode(items);
  return s
      .replaceAll('</', '<\\/')
      .replaceAll('\u2028', '\\u2028')
      .replaceAll('\u2029', '\\u2029');
}

String _shell({
  required String title,
  required String sub,
  required String css,
  required String body,
  required List<String> captions,
  required String setup,
}) {
  return _shellTemplate
      .replaceFirst('__BASE_CSS__', _baseCss)
      .replaceFirst('__CSS__', css)
      .replaceFirst('__TITLE__', htmlEscape(title))
      .replaceFirst('__SUB__', htmlEscape(sub))
      .replaceFirst('__BODY__', body)
      .replaceFirst('__CAPTIONS__', _jsStringArray(captions))
      .replaceFirst('__SETUP__', setup);
}

const _bstCss = r'''
main{padding:0}
svg{width:100%;height:100%}
.node circle{fill:var(--card);stroke:var(--border);stroke-width:2;transition:fill .3s,stroke .3s}
.node text{fill:var(--fg);font-size:28px;font-weight:600;text-anchor:middle;dominant-baseline:central}
.node{opacity:0;transform-box:fill-box;transform-origin:center;transform:scale(.6);
transition:opacity .35s ease,transform .4s cubic-bezier(.3,2,.5,1)}
.node.on{opacity:1;transform:scale(1)}
.node.path circle{stroke:var(--accent);fill:var(--accent-weak)}
line{stroke:var(--border);stroke-width:2;opacity:0;transition:opacity .3s}
line.on{opacity:1}
@media (prefers-reduced-motion: reduce){
  .node,line{transition:none}
}
''';

const _bstBody = '<svg id="tree" viewBox="0 0 800 460" preserveAspectRatio="xMidYMid meet"></svg>';

const _bstSetup = r'''
const pos = {50:[400,80],30:[220,180],70:[580,180],20:[130,280],40:[310,280],60:[490,280],80:[670,280]};
const parent = {30:50,70:50,20:30,40:30,60:70,80:70};
const order = [50,30,70,20,40,60,80];
const svg = document.getElementById('tree');
const ns = 'http://www.w3.org/2000/svg';
const nodes = {}, lines = {};
for (const k of order) {
  if (parent[k]) {
    const l = document.createElementNS(ns, 'line');
    const a = pos[parent[k]], c = pos[k];
    l.setAttribute('x1', a[0]); l.setAttribute('y1', a[1]);
    l.setAttribute('x2', c[0]); l.setAttribute('y2', c[1]);
    svg.appendChild(l); lines[k] = l;
  }
}
for (const k of order) {
  const g = document.createElementNS(ns, 'g');
  g.setAttribute('class', 'node');
  const p = pos[k];
  g.innerHTML = '<circle cx="' + p[0] + '" cy="' + p[1] + '" r="34"/><text x="' + p[0] + '" y="' + p[1] + '">' + k + '</text>';
  svg.appendChild(g); nodes[k] = g;
}
function applyStep(step) {
  for (const k of order) { nodes[k].classList.remove('path'); }
  const shown = order.slice(0, step);
  for (const k of order) {
    const on = shown.indexOf(k) !== -1;
    nodes[k].classList.toggle('on', on);
    if (lines[k]) { lines[k].classList.toggle('on', on); }
  }
  if (step > 0) {
    let c = parent[order[step - 1]];
    while (c) { nodes[c].classList.add('path'); c = parent[c]; }
  }
}
''';

const _bstCaptions = [
  'Start with an empty tree.',
  'Insert 50. It becomes the root.',
  'Insert 30. It is less than 50, so it goes to the left.',
  'Insert 70. It is greater than 50, so it goes to the right.',
  'Insert 20. Less than 50, then less than 30, so it goes left twice.',
  'Insert 40. Less than 50, then greater than 30, so it goes left then right.',
  'Insert 60. Greater than 50, then less than 70, so it goes right then left.',
  'Insert 80. Greater than 50, then greater than 70, so it goes right twice.',
];

String bstAnimation(String concept) => _shell(
      title: concept,
      sub: 'Watch each key find its place by comparing it to the nodes above it.',
      css: _bstCss,
      body: _bstBody,
      captions: _bstCaptions,
      setup: _bstSetup,
    );

const _growthCss = r'''
main{padding:0 0 2vh}
.chart{width:100%;height:100%;display:flex;align-items:flex-end;gap:1.6%;padding-bottom:3.6vh}
.col{flex:1;display:flex;gap:8%;align-items:flex-end;height:100%;position:relative}
.bar{flex:1;border-radius:6px 6px 2px 2px;height:0;transition:height .5s cubic-bezier(0,0,.5,1)}
.bar.simple{background:var(--border)}
.bar.compound{background:var(--accent)}
.yr{position:absolute;bottom:-3.2vh;left:0;right:0;text-align:center;color:var(--muted);font-size:clamp(10px,1.3vmin,12px)}
.legend{display:flex;gap:18px;font-size:clamp(11px,1.4vmin,13px);color:var(--muted);margin-top:1vh;justify-content:center}
.legend i{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:6px;vertical-align:-1px}
.legend i.simple{background:var(--border)}
.legend i.compound{background:var(--accent)}
@media (prefers-reduced-motion: reduce){ .bar{transition:none} }
''';

const _growthBody = '<div style="width:100%;height:100%;display:flex;flex-direction:column">'
    '<div class="chart" id="chart"></div>'
    '<div class="legend"><span><i class="simple"></i>Simple interest</span>'
    '<span><i class="compound"></i>Compound interest</span></div></div>';

const _growthSetup = r'''
const years = 10, P = 1000, r = 0.2;
const max = P * Math.pow(1 + r, years);
const chart = document.getElementById('chart');
const cols = [];
for (let y = 1; y <= years; y++) {
  const col = document.createElement('div');
  col.className = 'col';
  col.innerHTML = '<div class="bar simple"></div><div class="bar compound"></div><div class="yr">Y' + y + '</div>';
  chart.appendChild(col);
  cols.push(col);
}
function applyStep(step) {
  const yearsShown = step + 1;
  for (let y = 1; y <= years; y++) {
    const bars = cols[y - 1].querySelectorAll('.bar');
    const simple = bars[0], compound = bars[1];
    if (y <= yearsShown) {
      simple.style.height = (P * (1 + r * y) / max * 100) + '%';
      compound.style.height = (P * Math.pow(1 + r, y) / max * 100) + '%';
    } else {
      simple.style.height = '0';
      compound.style.height = '0';
    }
  }
}
''';

const _growthCaptions = [
  'Year 1. Simple and compound interest add the same amount so far.',
  "Year 2. Compound interest starts earning on last year's interest too.",
  'Year 3. The gap between the two is still small.',
  'Year 4. Compound interest keeps building on a larger base.',
  'Year 5. The compound bar is now clearly taller than the simple bar.',
  'Year 6. Growth is speeding up for compound interest.',
  'Year 7. Simple interest keeps growing at the same steady pace.',
  'Year 8. The difference between the two keeps widening.',
  'Year 9. Compound interest is pulling further ahead each year.',
  'Year 10. Compound interest has grown much faster than simple interest.',
];

String growthAnimation(String concept) => _shell(
      title: concept,
      sub: 'EGP 1,000 at 20% a year: simple interest next to compound interest.',
      css: _growthCss,
      body: _growthBody,
      captions: _growthCaptions,
      setup: _growthSetup,
    );

const _keyPointsCss = r'''
main{align-items:center;justify-content:center;overflow:hidden}
ol{list-style:none;margin:0 auto;padding:0;counter-reset:k;display:grid;gap:clamp(12px,2.6vmin,28px);
align-content:center;width:min(100%,62em);font-size:clamp(15px,2.3vmin,24px)}
li{counter-increment:k;display:grid;grid-template-columns:auto 1fr;column-gap:1em;align-items:start;opacity:0;
transform:translateY(16px);transition:transform .4s cubic-bezier(0,0,.5,1),opacity .4s ease}
li.on{opacity:.55;transform:none}
li.current{opacity:1}
li.current b{color:var(--accent)}
li::before{content:counter(k);width:2.2em;height:2.2em;border-radius:50%;display:grid;
place-items:center;background:var(--accent-weak);color:var(--accent);font-weight:700;font-size:.9em}
li b{display:block;font-size:1.25em;line-height:1.2;font-weight:650;letter-spacing:-.01em}
li span{display:block;margin-top:.3em;color:var(--muted);font-size:1em;line-height:1.45}
@media (prefers-reduced-motion: reduce){ li{transition:none} }
''';

const _keyPointsSetup = r'''
const items = Array.prototype.slice.call(document.querySelectorAll('#list li'));
function applyStep(step) {
  items.forEach(function (el, idx) {
    el.classList.toggle('on', idx <= step);
    el.classList.toggle('current', idx === step);
  });
}
''';

/// Generic fallback template: reveals one idea per step, pulled straight
/// from the concept text or the retrieved course chunks. Used for summary
/// concepts and anything that does not match a more specific template.
String keyPointsAnimation(String concept, List<(String, String)> points) {
  final list = points.isEmpty
      ? const [
          ('No files yet', 'Turn on some course files and I\'ll pull the main ideas from them.'),
        ]
      : points.take(6).toList();

  final items = list
      .map((p) => '<li><b>${htmlEscape(p.$1)}</b><span>${htmlEscape(p.$2)}</span></li>')
      .join();
  final captions = [for (final (i, p) in list.indexed) 'Idea ${i + 1}: ${p.$1}.'];

  return _shell(
    title: concept,
    sub: 'The main ideas from your files, one at a time.',
    css: _keyPointsCss,
    body: '<ol id="list">$items</ol>',
    captions: captions,
    setup: _keyPointsSetup,
  );
}
