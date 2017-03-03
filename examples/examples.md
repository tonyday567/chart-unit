<meta charset="utf-8"> <link rel="stylesheet" href="https://tonyday567.github.io/other/lhs.css">
<script type="text/javascript" async
  src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>
[chart-unit](https://tonyday567.github.io/chart-unit) [![Build Status](https://travis-ci.org/tonyday567/chart-unit.png)](https://travis-ci.org/tonyday567/chart-unit)
===

[repo](https://tonyday567.github.com/chart-unit)

`chart-unit` is an experimental haskell chart library.

scratchpad

<img style="border:5px solid grey" src="other/scratchpad.svg">

unital charting
-----

This slowly growing collection of charts:

-   renders nicely in svg over a wide chart size.
-   retain a similar look-n-feel across different scales
-   are highly customizable
-   have a unit scale in the spirit of the
    [diagrams](http://projects.haskell.org/diagrams/doc/quickstart.html)
    design space, making combining a snap.
-   can be quickly integrated into ad-hoc haskell data analytics,
    providing a visual feedback loop.

charts
======

A chart can be anything that is represented on an XY plane, and usually comes with visual clues about what is being represented, such as axes, titles and legends.  Here's the default blank chart:

![](other/exampleAxes.svg)

~~~
axes def sixbyfour [toCorners (one::XY)]
~~~

`sixbyfour` is a value of type XY, and represents the rectangle that the chart will be rendered with.  As with any SVG element, the ultimate product is still subject to sizing on use, so think of `sixbyfour` as a relative aspect ratio rather than a concrete size.

Note that there are two independent scales used:

- the aspect ratio of the chart, and
- the axes scales, `[toCorners (one::XY)]` which computes to -0.5 to 0.5 for both the X and Y axes in the above chart

customization
---

Axes and most other things are highly customizable.  Here's an approximation of ggplot axes and canvas style:

![](other/exampleGgplot.svg)

line chart
---

Some actual, real-life lines to be plotted:

![](other/exampleLine.svg)

~~~
line lineDefs sixbyfour lineData
~~~

Breaking the code down:

- `line` is a typical chart renderer, taking a
- `[LineConfig]`, which is a list of configurations for each line, an
- `XY`, which is the aspect ratio to render the chart, and, finally
- the data, a `(Traversable g, Traversable f, R2~r) => g (f (r a))`, or in this case, a `[[V2 Double]]`, which is a double container of the values to chart

Adding axes:

![](other/exampleLineAxes.svg)

~~~
line lineDefs sixbyfour lineData <> axes def sixbyfour lineData
~~~

scatter
---

Other default chart types follow this same pattern:

![](other/exampleScatter.svg)

~~~
scatter defs one xys <> axes def one xys
~~~

As with `line`, `scatter` zips together multiple configurations and multiple containers of data.  It's often much easier to construct charts assuming multiple data sets. 

A major point of the chart-unit library is that the look-n-feel of a chart is invariant to the data scale.

![](other/exampleScatter2.svg)

~~~
let xys1 = fmap (over _x (*1e8) . over _y (*1e-8)) <$> xys in
scatter defs one xys1 <> axes def one xys1
~~~

histogram
---

A histogram, in widescreen

![](other/exampleHist.svg)

~~~
hist
    [ def
    , rectBorderColor .~ Color 0 0 0 0
      $ rectColor .~ Color 0.333 0.333 0.333 0.4
      $ def
    ]
    wideScreen
    xys
~~~

A labelled bar chart:

![](other/exampleLabelledBar.svg)


Compound charts
---

`chart-unit` is a fairly thin wrapper over diagrams that establishes the basics of what a chart is, and provides some sane defaults.  From this starting point, production of high-quality charting is easy and pleasant. Two examples:

A scatter chart with histograms of the data along the x & y dimensions.

![](other/exampleScatterHist.svg)

A unital gradient chart, using diagrams arrows:

![](other/exampleArrow.svg)

The `QChart` type exists to enable combining different types of charts using the same scale.

![](other/exampleCompound.svg)

Clipping charts

![](other/exampleClipping.svg)


data
---

Double-containered dimensioned data covers what a chart charts - one or more data sets with at least an x and y dimension (called R2 in the linear library).

Most chart variations are about what to do with the extra dimensions in the data. A rectangle, for example, is built from 4 dimensions, an anchoring of position in XY space, with a width (W) and height (Z).  A contour map is three dimensional data (V3 in linear), with placement as XY and color as Z.


diagrams development recipe
---------------------------

In constructing new chart units:

-   diagrams go from polymorphic & abstract to strongly-typed & concrete
-   V2 (-0.5 ... 0.5) (-0.5 ... 0.5) forms a unitSquare: one unit by one unit, origin in the center
-   regularly check where the origin is, usually not where it needs to be.
-   turn pointful shapes into a Trail
-   close the Trail into a SVG-like loop
-   turn the closed Trail into a QDiagram

You can slide up and down the various diagrams abstraction levels
creating transformations at each level. For example, here's something I
use to work at the point level:

    unitp f = unitSquare # f # fromVertices # closeTrail # strokeTrail

workflow
--------

recipe 1

``` {.sourceCode .literate .haskell}
scratch :: Chart SVG -> IO ()
scratch = fileSvg "other/scratchpad.svg" (600,400)
```

I tend to work in ghci a lot, using the above `scratch` to try code out, mashing the refresh button in the browser.  


recipe 2

    stack build --copy-bins --exec  "chart-unit-examples" --exec "pandoc -f markdown -t html -i readme.md -o index.html --mathjax --filter pandoc-include" --file-watch