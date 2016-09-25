<meta charset="utf-8"> <link rel="stylesheet" href="other/lhs.css">
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>
<h1 id="chart-svg-repo-build-status">chart-svg <a href="https://github.com/tonyday567/chart-svg"><img src="https://a248.e.akamai.net/assets.github.com/images/icons/emoji/octocat.png" alt="repo" /></a> <a href="https://travis-ci.org/tonyday567/chart-svg"><img src="https://travis-ci.org/tonyday567/chart-svg.png" alt="Build Status" /></a></h1>
<p>Github refuses to render svg in a readme.md, so it all looks much better in served <a href="http://tonyday567.github.io/chart-svg.html">html</a>.</p>
<h1 id="chart-svg">chart-svg</h1>
<h2 id="scratchpad">scratchpad</h2>
<p>My newest chart <code>padq $ linesXY def [[(0,0),(1,1)],[(0,0),(1,2)]]</code></p>
<div class="figure">
<img src="other/scratchpad.svg" />

</div>
<h2 id="chart-svg-1">chart-svg</h2>
<p>This slowly growing collection of svg charts:</p>
<ul class="incremental">
<li>render nicely over a wide chart size range</li>
<li>render similarly at different scale</li>
<li>are opinionated minimalism</li>
<li>are unit shapes in the spirit of the <a href="http://projects.haskell.org/diagrams/doc/quickstart.html">diagrams</a> design space.</li>
<li>can be quickly integrated into ad-hoc haskell data analytics, providing a visual feedback loop.</li>
</ul>
<h2 id="charts">charts</h2>
<p>Scatter</p>
<div class="figure">
<img src="other/scatter.svg" />

</div>
<p>Histogram</p>
<div class="figure">
<img src="other/hist.svg" />

</div>
<p>Line</p>
<div class="figure">
<img src="other/line.svg" />

</div>
<p>Lines</p>
<div class="figure">
<img src="other/lines.svg" />

</div>
<p>Labelled Bar Chart</p>
<div class="figure">
<img src="other/bar.svg" />

</div>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell"><span class="ot">{-# OPTIONS_GHC -Wall #-}</span>
<span class="ot">{-# OPTIONS_GHC -fno-warn-type-defaults #-}</span>
<span class="ot">{-# OPTIONS_GHC -fno-warn-missing-signatures #-}</span>
<span class="kw">import </span><span class="dt">Protolude</span>
<span class="kw">import </span><span class="dt">Control.Monad.Primitive</span> (unsafeInlineIO)
<span class="kw">import </span><span class="dt">Diagrams.Prelude</span> <span class="kw">hiding</span> ((&lt;&gt;))
<span class="kw">import </span><span class="dt">Diagrams.Backend.SVG</span> (<span class="dt">SVG</span>)
<span class="kw">import qualified</span> <span class="dt">Control.Foldl</span> <span class="kw">as</span> <span class="dt">L</span>
<span class="kw">import qualified</span> <span class="dt">Data.Random</span> <span class="kw">as</span> <span class="dt">R</span>
<span class="kw">import qualified</span> <span class="dt">Data.Map.Strict</span> <span class="kw">as</span> <span class="dt">Map</span>

<span class="kw">import </span><span class="dt">Chart</span></code></pre></div>
<h2 id="some-test-data">some test data</h2>
<p>Standard normal random variates. Called ys to distinguish from the horizontal axis of the chart (xs) which are often implicitly [0..]</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell"><span class="ot">ys ::</span> <span class="dt">Int</span> <span class="ot">-&gt;</span> <span class="dt">IO</span> [<span class="dt">Double</span>]
ys n <span class="fu">=</span>
  replicateM n <span class="fu">$</span> R.runRVar R.stdNormal <span class="dt">R.StdRandom</span></code></pre></div>
<p>A bunch of ys, accumulated.</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell"><span class="ot">yss ::</span> (<span class="dt">Int</span>, <span class="dt">Int</span>) <span class="ot">-&gt;</span> [[<span class="dt">Double</span>]]
yss (n,m) <span class="fu">=</span> unsafeInlineIO <span class="fu">$</span> <span class="kw">do</span>
  yss&#39; <span class="ot">&lt;-</span> replicateM m <span class="fu">$</span> ys n
  pure <span class="fu">$</span> (drop <span class="dv">1</span> <span class="fu">.</span> L.scan L.sum) <span class="fu">&lt;$&gt;</span> yss&#39;</code></pre></div>
<p>xys is a list of X,Y pairs, correlated normal random variates to add some shape to chart examples.</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell"><span class="ot">rXYs ::</span> <span class="dt">Int</span> <span class="ot">-&gt;</span> <span class="dt">Double</span> <span class="ot">-&gt;</span> [(<span class="dt">Double</span>,<span class="dt">Double</span>)]
rXYs n c <span class="fu">=</span> unsafeInlineIO <span class="fu">$</span> <span class="kw">do</span>
  s0 <span class="ot">&lt;-</span> replicateM n <span class="fu">$</span> R.runRVar R.stdNormal <span class="dt">R.StdRandom</span>
  s1 <span class="ot">&lt;-</span> replicateM n <span class="fu">$</span> R.runRVar R.stdNormal <span class="dt">R.StdRandom</span>
  <span class="kw">let</span> s1&#39; <span class="fu">=</span> zipWith (\x y <span class="ot">-&gt;</span> c <span class="fu">*</span> x <span class="fu">+</span> sqrt (<span class="dv">1</span> <span class="fu">-</span> c <span class="fu">*</span> c) <span class="fu">*</span> y) s0 s1
  pure <span class="fu">$</span> zip s0 s1&#39;

xys <span class="fu">=</span> rXYs <span class="dv">1000</span> <span class="fl">0.8</span></code></pre></div>
<p>XY random walk</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell">rwxy <span class="fu">=</span> L.scan (<span class="dt">L.Fold</span> (\(x,y) (x&#39;,y&#39;) <span class="ot">-&gt;</span> (x<span class="fu">+</span>x&#39;,y<span class="fu">+</span>y&#39;)) (<span class="fl">0.0</span>,<span class="fl">0.0</span>) identity) (take <span class="dv">100</span> xys)</code></pre></div>
<p>xysHist is a histogram of 10000 one-dim random normals.</p>
<p>The data out is a (X,Y) pair list, with mid-point of the bucket as X, and bucket count as Y.</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell"><span class="ot">xysHist ::</span> [(<span class="dt">Double</span>,<span class="dt">Double</span>)]
xysHist <span class="fu">=</span> unsafeInlineIO <span class="fu">$</span> <span class="kw">do</span>
  ys&#39; <span class="ot">&lt;-</span> replicateM <span class="dv">10000</span> <span class="fu">$</span> R.runRVar R.stdNormal <span class="dt">R.StdRandom</span><span class="ot"> ::</span> <span class="dt">IO</span> [<span class="dt">Double</span>]
  <span class="kw">let</span> (f,s,n) <span class="fu">=</span> mkTicks&#39; (range1D ys&#39;) <span class="dv">100</span>
  <span class="kw">let</span> cuts <span class="fu">=</span> (\x <span class="ot">-&gt;</span> f<span class="fu">+</span>s<span class="fu">*</span>fromIntegral x) <span class="fu">&lt;$&gt;</span> [<span class="dv">0</span><span class="fu">..</span>n]
  <span class="kw">let</span> mids <span class="fu">=</span> (<span class="fu">+</span>(s<span class="fu">/</span><span class="dv">2</span>)) <span class="fu">&lt;$&gt;</span> cuts
  <span class="kw">let</span> count <span class="fu">=</span> <span class="dt">L.Fold</span> (\x a <span class="ot">-&gt;</span> Map.insertWith (<span class="fu">+</span>) a <span class="dv">1</span> x) Map.empty identity
  <span class="kw">let</span> countBool <span class="fu">=</span> <span class="dt">L.Fold</span> (\x a <span class="ot">-&gt;</span> x <span class="fu">+</span> <span class="kw">if</span> a <span class="kw">then</span> <span class="dv">1</span> <span class="kw">else</span> <span class="dv">0</span>) <span class="dv">0</span> identity
  <span class="kw">let</span> histMap <span class="fu">=</span> L.fold count <span class="fu">$</span> (\x <span class="ot">-&gt;</span> L.fold countBool (fmap (x <span class="fu">&gt;</span>) cuts)) <span class="fu">&lt;$&gt;</span> ys&#39;
  <span class="kw">let</span> histList <span class="fu">=</span> (\x <span class="ot">-&gt;</span> Map.findWithDefault <span class="dv">0</span> x histMap) <span class="fu">&lt;$&gt;</span> [<span class="dv">0</span><span class="fu">..</span>n]
  return (zip mids (fromIntegral <span class="fu">&lt;$&gt;</span> histList))</code></pre></div>
<h2 id="scale-robustness">Scale Robustness</h2>
<p>xys rendered on the XY plane as dots - a scatter chart with no axes - is invariant to scale. The data could be multiplied by any scalar, and look exactly the same.</p>
<div class="figure">
<img src="other/dots.svg" />

</div>
<p>Axes break this scale invariance. Ticks and tick labels can hide this to some extent and look almost the same across scales.</p>
<div class="figure">
<img src="other/scatter.svg" />

</div>
<p>This chart will look the same on a data scale change, except for tick magnitudes.</p>
<h2 id="main">main</h2>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell">
<span class="ot">main ::</span> <span class="dt">IO</span> ()
main <span class="fu">=</span> <span class="kw">do</span></code></pre></div>
<p>See develop section below for my workflow.</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell">  padq <span class="fu">$</span>
      linesXY def [[(<span class="dv">0</span>,<span class="dv">0</span>),(<span class="dv">1</span>,<span class="dv">1</span>)],[(<span class="dv">0</span>,<span class="dv">0</span>),(<span class="dv">1</span>,<span class="dv">2</span>)]]
  toFile <span class="st">&quot;other/line.svg&quot;</span> (<span class="dv">200</span>,<span class="dv">200</span>) (lineXY def rwxy)
  toFile <span class="st">&quot;other/lines.svg&quot;</span> (<span class="dv">200</span>,<span class="dv">200</span>) (linesXY def <span class="fu">$</span> zip [<span class="dv">0</span><span class="fu">..</span>] <span class="fu">&lt;$&gt;</span> yss (<span class="dv">1000</span>, <span class="dv">10</span>))
  toFile <span class="st">&quot;other/dots.svg&quot;</span> (<span class="dv">100</span>,<span class="dv">100</span>) (scatter def xys)
  toFile <span class="st">&quot;other/scatter.svg&quot;</span> (<span class="dv">200</span>,<span class="dv">200</span>) (scatterXY def xys)
  toFile <span class="st">&quot;other/bar.svg&quot;</span> (<span class="dv">200</span>,<span class="dv">200</span>) <span class="fu">$</span>
    barLabelled def (unsafeInlineIO <span class="fu">$</span> ys <span class="dv">10</span>) (take <span class="dv">10</span> <span class="fu">$</span> (<span class="fu">:</span>[]) <span class="fu">&lt;$&gt;</span> [<span class="ch">&#39;a&#39;</span><span class="fu">..</span>])
  toFile <span class="st">&quot;other/hist.svg&quot;</span> (<span class="dv">200</span>,<span class="dv">200</span>) <span class="fu">$</span>
    barRange def xysHist</code></pre></div>
<h2 id="diagrams-development-recipe">diagrams development recipe</h2>
<p>In constructing new <code>units</code>:</p>
<ul class="incremental">
<li>diagrams go from abstract to concrete</li>
<li>start with the unitSquare: 4 points, 1x1, origin in the center</li>
<li>work out where the origin should be, given the scaling needed.</li>
<li>turn the pointful shape into a Trail</li>
<li>close the Trail into a SVG-like loop</li>
<li>turn the Trail into a QDiagram</li>
</ul>
<p>You can slide up and down the various diagrams abstraction levels creating transformations at each level. For example, here's something I use to work at the point level:</p>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell">unitp f <span class="fu">=</span> unitSquare <span class="fu">#</span> f <span class="fu">#</span> fromVertices <span class="fu">#</span> closeTrail <span class="fu">#</span> strokeTrail</code></pre></div>
<h2 id="workflow">workflow</h2>
<div class="sourceCode"><pre class="sourceCode literate haskell"><code class="sourceCode haskell"><span class="ot">padq ::</span> <span class="dt">QDiagram</span> <span class="dt">SVG</span> <span class="dt">V2</span> <span class="dt">Double</span> <span class="dt">Any</span> <span class="ot">-&gt;</span> <span class="dt">IO</span> ()
padq t <span class="fu">=</span>
  toFile <span class="st">&quot;other/scratchpad.svg&quot;</span> (<span class="dv">400</span>,<span class="dv">400</span>) t</code></pre></div>
<p>Create a markdown version of readme.lhs:</p>
<pre><code>pandoc -f markdown+lhs -t html -i readme.lhs -o readme.html</code></pre>
<p>Then fire up an intero session, and use padq to display coding results on-the-fly, mashing the refresh button on a browser pointed to readme.html.</p>
<p>or go for a compilation loop like:</p>
<pre><code>stack install &amp;&amp; readme &amp;&amp; pandoc -f markdown+lhs -t html -i readme.lhs -o readme.html --mathjax --filter pandoc-include</code></pre>
