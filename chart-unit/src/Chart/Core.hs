{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NegativeLiterals #-}
{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ViewPatterns #-}
#if ( __GLASGOW_HASKELL__ < 820 )
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
#endif

-- | In making a chart, there are three main size domains you have to be concerned about:
--
-- - the range of the data being charted. This range is often projected onto chart elements such as axes and labels. A data range in two dimensions is a 'Rect' a.
--
-- - the scale of various chart primitives and elements.  The overall dimensions of the chart canvas - the rectangular shape on which the data is represented - is referred to as an 'Aspect' in the api, and is a wrapped 'Rect' to distinguish aspects from rect ranges.  The default chart options tend to be callibrated to Aspects around widths of one.
--
-- - the size of the chart rendered as an image. Backends tend to shrink charts to fit the rectangle shape specified in the render function, and a loose sympathy is expected between the aspect and a chart's ultimate physical size.
--
-- Jumping ahead a bit, the code snippet below draws vertical lines using a data range of "Rect 0 12 0 0.2" (slightly different to the actual data range), using a widescreen (3:1) aspect, and renders the chart as a 300 by 120 pixel svg:
--
-- > scaleExample :: IO ()
-- > scaleExample =
-- >     fileSvg "other/scaleExample.svg" (#size .~ Pair 300 120 $ def) $
-- >     withHud
-- >       defaultHudOptions
-- >       widescreen
-- >       (Rect 0 12 0 0.2)
-- >       (lineChart (repeat def))
-- >       (vlineOneD ((0.01*) <$> [0..10]))
--
-- ![scale example](other/scaleExample.svg)
--

module Chart.Core
  ( -- * Chart types
    Chart
    -- * Scaling
  , range
  , projectss
  , aspect
  , asquare
  , sixbyfour
  , golden
  , widescreen
  , skinny
  , AlignH(..)
  , AlignV(..)
  , alignHU
  , alignHTU
  , alignVU
  , alignVTU
    -- * Types
  , Orientation(..)
  , Place(..)
    -- * Combinators
    --
    -- | The concept of a point on a chart is the polymorphic 'R2' from the 'linear' library.  Diagrams most often uses 'Point', which is a wrapped 'V2'.  The 'Pair' type from 'numhask-range' is often used as a point reference.
  , positioned
  , p_
  , r_
  , stack
  , vert
  , hori
  , sepVert
  , sepHori

    -- * Color
    --
    -- | chart-unit exposes the 'colour' and 'palette' libraries for color combinators
  , UColor(..)
  , acolor
  , ucolor
  , ccolor
  , ublue
  , ugrey
  , utrans
  , ublack
  , uwhite
    -- * Compatability
  , scaleX
  , scaleY
  , scale
  ) where

import Diagrams.Prelude
       hiding (Color, D, aspect, project, scale, scaleX, scaleY, zero, over)
import qualified Diagrams.Prelude as Diagrams
import qualified Diagrams.TwoD.Text
import NumHask.Pair
import NumHask.Prelude
import NumHask.Rect
import NumHask.Range
import NumHask.Space
import Data.Colour (over)

-- | A Chart is simply a type synonym for a typical Diagrams object.  A close relation to this type is 'Diagram' 'B', but this usage tends to force a single backend (B comes from the backend libraries), so making Chart b's maintains backend polymorphism.
--
-- Just about everything - text, circles, lines, triangles, charts, axes, titles, legends etc - are 'Chart's, which means that most things are amenable to full use of the combinatorially-inclined diagrams-lib.
type Chart b =
  ( Renderable (Path V2 Double) b
  , Renderable (Diagrams.TwoD.Text.Text Double) b) =>
       QDiagram b V2 Double Any

-- | project a double-containered set of data to a new Rect range
projectss ::
     (Functor f, Functor g)
  => Rect Double
  -> Rect Double
  -> g (f (Pair Double))
  -> g (f (Pair Double))
projectss r0 r1 xyss = map (project r0 r1) <$> xyss

-- | determine the range of a double-containered set of data
range :: (Foldable f, Foldable g) => g (f (Pair Double)) -> Rect Double
range xyss = foldMap space xyss

-- | the aspect of a chart expressed as a ratio of x-plane : y-plane.
aspect :: (CanRange a, Multiplicative a) => a -> Rect a
aspect a = Ranges ((a *) <$> one) one

-- | a 1:1 aspect
asquare :: Rect Double
asquare = aspect 1

-- | a 1.5:1 aspect
sixbyfour :: Rect Double
sixbyfour = aspect 1.5

-- | golden ratio
golden :: Rect Double
golden = aspect 1.61803398875

-- | a 3:1 aspect
widescreen :: Rect Double
widescreen = aspect 3

-- | a skinny 5:1 aspect
skinny :: Rect Double
skinny = aspect 5

-- | horizontal alignment
data AlignH
  = AlignLeft
  | AlignCenter
  | AlignRight
  deriving (Show, Eq, Generic)

-- | vertical alignment
data AlignV
  = AlignTop
  | AlignMid
  | AlignBottom
  deriving (Show, Eq, Generic)

-- | conversion of horizontal alignment to (one :: Range Double) limits
alignHU :: AlignH -> Double
alignHU a =
  case a of
    AlignLeft -> 0.5
    AlignCenter -> 0
    AlignRight -> -0.5

-- | svg text is forced to be lower left (-0.5) by default
alignHTU :: AlignH -> Double
alignHTU a =
  case a of
    AlignLeft -> 0
    AlignCenter -> -0.5
    AlignRight -> -1

-- | conversion of vertical alignment to (one :: Range Double) limits
alignVU :: AlignV -> Double
alignVU a =
  case a of
    AlignTop -> -0.5
    AlignMid -> 0
    AlignBottom -> 0.5

-- | svg text is lower by default
alignVTU :: AlignV -> Double
alignVTU a =
  case a of
    AlignTop -> 0.5
    AlignMid -> 0
    AlignBottom -> -0.5

-- | Orientation for an element.  Watch this space for curvature!
data Orientation
  = Hori
  | Vert
  deriving (Show, Eq, Generic)

-- | Placement of elements around (what is implicity but maybe shouldn't just be) a rectangular canvas
data Place
  = PlaceLeft
  | PlaceRight
  | PlaceTop
  | PlaceBottom
  deriving (Show, Eq, Generic)

-- | position an element at a point
positioned :: (R2 r) => r Double -> Chart b -> Chart b
positioned p = moveTo (p_ p)

-- | convert an R2 to a diagrams Point
p_ :: (R2 r) => r Double -> Point V2 Double
p_ r = curry p2 (r ^. _x) (r ^. _y)

-- | convert an R2 to a V2
r_ :: R2 r => r a -> V2 a
r_ r = V2 (r ^. _x) (r ^. _y)

-- | foldMap for beside; stacking chart elements in a direction, with a premap
stack ::
  ( R2 r
  , V a ~ V2
  , Foldable t
  , Juxtaposable a
  , Semigroup a
  , N a ~ Double
  , Monoid a
  )
  => r Double
  -> (b -> a)
  -> t b
  -> a
stack dir f xs = foldr (\a x -> beside (r_ dir) (f a) x) mempty xs

-- | combine elements vertically, with a premap
vert ::
     (V a ~ V2, Foldable t, Juxtaposable a, Semigroup a, N a ~ Double, Monoid a)
  => (b -> a)
  -> t b
  -> a
vert = stack (Pair 0 -1)

-- | combine elements horizontally, with a premap
hori ::
     (V a ~ V2, Foldable t, Juxtaposable a, Semigroup a, N a ~ Double, Monoid a)
  => (b -> a)
  -> t b
  -> a
hori = stack (Pair 1 0)

-- | horizontal separator
sepHori :: Double -> Chart b -> Chart b
sepHori s x = beside (r2 (0, -1)) x (strutX s)

-- | vertical separator
sepVert :: Double -> Chart b -> Chart b
sepVert s x = beside (r2 (1, 0)) x (strutY s)


data UColor a =
  UColor
  { ucred :: a
  , ucgreen :: a
  , ucblue :: a
  , ucopacity :: a
  } deriving (Eq, Ord, Show, Generic)

-- | convert a UColor to an AlphaColour
acolor :: (Floating a, Num a, Ord a) => UColor a -> AlphaColour a
acolor (UColor r g b o) = withOpacity (sRGB r g b) o

-- | convert an AlphaColour to a UColor
ucolor :: (Floating a, Num a, Ord a) => AlphaColour a -> UColor a
ucolor a = let (RGB r g b) = toSRGB (a `over` black) in UColor r g b (alphaChannel a)

-- | convert a Colour to a UColor
ccolor :: (Floating a, Num a, Ord a) => Colour a -> UColor a
ccolor (toSRGB -> RGB r g b) = UColor r g b 1

-- | the official chart-unit blue
ublue :: UColor Double
ublue = UColor 0.365 0.647 0.855 0.5

-- | the official chart-unit grey
ugrey :: UColor Double
ugrey = UColor 0.4 0.4 0.4 1

-- | transparent
utrans :: UColor Double
utrans = UColor 0 0 0 0

-- | black
ublack :: UColor Double
ublack = UColor 0 0 0 1

-- | white
uwhite :: UColor Double
uwhite = UColor 1 1 1 1

-- | These are difficult to avoid
instance R1 Pair where
  _x f (Pair a b) = (`Pair` b) <$> f a

instance R2 Pair where
  _y f (Pair a b) = Pair a <$> f b
  _xy f p = fmap (\(V2 a b) -> Pair a b) . f . (\(Pair a b) -> V2 a b) $ p

eps :: N [Point V2 Double]
eps = 1e-8

-- | the diagrams scaleX with a zero divide guard to avoid error throws
scaleX ::
     (N t ~ Double, Transformable t, R2 (V t), Diagrams.Additive (V t))
  => Double
  -> t
  -> t
scaleX s =
  Diagrams.scaleX
    (if s == zero
       then eps
       else s)

-- | the diagrams scaleY with a zero divide guard to avoid error throws
scaleY ::
     (N t ~ Double, Transformable t, R2 (V t), Diagrams.Additive (V t))
  => Double
  -> t
  -> t
scaleY s =
  Diagrams.scaleY
    (if s == zero
       then eps
       else s)

-- | the diagrams scale with a zero divide guard to avoid error throws
scale ::
     (N t ~ Double, Transformable t, R2 (V t), Diagrams.Additive (V t))
  => Double
  -> t
  -> t
scale s =
  Diagrams.scale
    (if s == zero
       then eps
       else s)
