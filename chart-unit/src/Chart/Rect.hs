{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE CPP #-}
#if ( __GLASGOW_HASKELL__ < 820 )
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
#endif
{-# OPTIONS_GHC -Wno-unused-top-binds #-}

-- | rectangular chart elements
module Chart.Rect
  ( RectOptions(..)
  , defaultRectOptions
  , blob
  , box
  , clear
  , bound
  , rect_
  , rects
  , rectChart
  , rectChart_
  , Pixel(..)
  , pixel_
  , pixels
  , pixelChart
  , pixelChart_
  , PixelationOptions(..)
  , defaultPixelationOptions
  , pixelate
  , pixelateChart
  ) where

import Chart.Core
import Diagrams.Prelude hiding (Color, D, (<>), scaleX, scaleY)
import NumHask.Pair
import NumHask.Prelude
import NumHask.Range
import NumHask.Rect
import NumHask.Space

-- | Just about everything on a chart is a rectangle.
data RectOptions = RectOptions
  { borderSize :: Double
  , borderColor :: UColor Double
  , color :: UColor Double
  } deriving (Show, Eq, Generic)

defaultRectOptions :: RectOptions
defaultRectOptions = RectOptions 0.005 ugrey ublue

-- | solid rectangle, no border
blob :: UColor Double -> RectOptions
blob c = RectOptions 0 utrans c

-- | clear and utrans rect
clear :: RectOptions
clear = RectOptions 0 utrans utrans

-- | clear rect, with border
box :: UColor Double -> RectOptions
box c = RectOptions 0.015 c utrans

-- | place a rect around an Chart, with a size equal to the chart range
bound :: RectOptions -> Double -> Chart b -> Chart b
bound (RectOptions bs bc c) p x =
  (boundingRect x' # lcA (acolor bc) # lwN bs # fcA (acolor c)) <> x'
  where
    x' = pad p x

-- | A single rectangle specified using a Rect x z y w where
-- (x,y) is location of lower left corner
-- (z,w) is location of upper right corner
--
-- > rect_Example :: Double -> Chart b
-- > rect_Example n =
-- >   labelled (opts (Pair n 1)) "z,w" $
-- >   labelled (opts (Pair n -1)) "z,y" $
-- >   labelled (opts (Pair (-n) 1)) "x,w" $
-- >   labelled (opts (Pair (-n) -1)) "x,y" $
-- >   rect_ def (Ranges (n *. one) one)
-- >   where
-- >     opts :: Pair Double -> LabelOptions
-- >     opts o =
-- >       #text %~
-- >         ( (#color .~ black `withOpacity` 0.8) .
-- >           (#size .~ 0.3)) $
-- >       #orientation .~ o $
-- >       def
--
-- ![rect_ example](other/rect_Example.svg)
--
rect_ ::
     ( N b ~ Double
     , V b ~ V2
     , Transformable b
     , HasOrigin b
     , TrailLike b
     , HasStyle b
     )
  => RectOptions
  -> Rect Double
  -> b
rect_ (RectOptions bs bc c) (Rect x z y w) =
  unitSquare # moveTo (p2 (0.5, 0.5)) # scaleX (z - x) # scaleY (w - y) #
  moveTo (p2 (x, y)) #
  fcA (acolor c) #
  lcA (acolor bc) #
  lwN bs

-- | Create rectangles (with the same configuration).
--
-- > rects def (rectBars 0 [1, 2, 3, 5, 8, 0, -2, 11, 2, 1])
--
-- ![rects example](other/rectsExample.svg)
--
rects ::
     ( V a ~ V2
     , N a ~ Double
     , Functor t
     , HasStyle a
     , TrailLike a
     , HasOrigin a
     , Transformable a
     , Foldable t
     , Monoid a
     )
  => RectOptions
  -> t (Rect Double)
  -> a
rects opts xs = mconcat $ toList $ rect_ opts <$> xs

-- | A chart of rects
rectChart ::
     (Traversable f)
  => [RectOptions]
  -> Rect Double
  -> Rect Double
  -> [f (Rect Double)]
  -> Chart b
rectChart optss asp r rs =
  mconcat . zipWith rects optss $ fmap (projectRect r asp) <$> rs

-- | A chart of rectangles scaled to its own range
--
-- > ropts :: [RectOptions]
-- > ropts =
-- >   [ #borderSize .~ 0 $ def
-- >   , #borderSize .~ 0 $ #color .~ ucolor 0.3 0.3 0.3 0.2 $ def
-- >   ]
-- >
-- > rss :: [[Rect Double]]
-- > rss =
-- >   [ rectXY (\x -> exp (-(x ** 2) / 2)) (Range -5 5) 50
-- >   , rectXY (\x -> 0.5 * exp (-(x ** 2) / 8)) (Range -5 5) 50
-- >   ]
-- >
-- > rectChart_Example :: Chart b
-- > rectChart_Example = rectChart_ ropts widescreen rss
--
-- ![rectChart_ example](other/rectChart_Example.svg)
--
rectChart_ ::
     (Traversable f)
  => [RectOptions]
  -> Rect Double
  -> [f (Rect Double)]
  -> Chart b
rectChart_ optss asp rs = rectChart optss asp (fold $ fold <$> rs) rs

-- | At some point, a color of a rect becomes more about data than stylistic option, hence the pixel.  Echewing rect border leaves a Pixel with no stylistic options to choose.
data Pixel = Pixel
  { pixelRect :: Rect Double
  , pixelColor :: UColor Double
  } deriving (Show, Eq, Generic)

-- | A pixel is a rectangle with a color.
--
-- > pixel_Example :: Chart b
-- > pixel_Example = text_ opt "I'm a pixel!" <> pixel_ (Pixel one ublue)
-- >   where
-- >     opt =
-- >       #color .~ withOpacity black 0.8 $
-- >       #size .~ 0.2 $
-- >       def
--
-- ![pixel_ example](other/pixel_Example.svg)
--
pixel_ :: Pixel -> Chart b
pixel_ (Pixel (Rect x z y w) c) =
  unitSquare # moveTo (p2 (0.5, 0.5)) # scaleX (z - x) # scaleY (w - y) #
  moveTo (p2 (x, y)) #
  fcA (acolor c) #
  lcA (acolor utrans) #
  lw 0

-- | Render multiple pixels
--
-- > pixelsExample :: Chart b
-- > pixelsExample =
-- >   pixels
-- >     [ Pixel
-- >       (Rect (5 * x) (5 * x + 0.1) (sin (10 * x)) (sin (10 * x) + 0.1))
-- >       (dissolve (2 * x) ublue)
-- >     | x <- grid OuterPos (Range 0 1) 100
-- >     ]
--
-- ![pixels example](other/pixelsExample.svg)
--
pixels :: (Traversable f) => f Pixel -> Chart b
pixels ps = mconcat $ toList $ pixel_ <$> ps

-- | A chart of pixels
pixelChart ::
     (Traversable f) => Rect Double -> Rect Double -> [f Pixel] -> Chart b
pixelChart asp r pss = mconcat $ pixels . projectPixels r asp . toList <$> pss
  where
    projectPixels r0 r1 ps =
      zipWith Pixel (projectRect r0 r1 . pixelRect <$> ps) (pixelColor <$> ps)

-- | A chart of pixels scaled to its own range
--
-- > pixelChart_Example :: Chart b
-- > pixelChart_Example =
-- >   pixelChart_ asquare
-- >   [(\(r,c) ->
-- >       Pixel r
-- >       (blend c
-- >        (ucolor 0.47 0.73 0.86 1)
-- >        (ucolor 0.01 0.06 0.22 1)
-- >       )) <$>
-- >    rectF (\(Pair x y) -> (x+y)*(x+y))
-- >    one (Pair 40 40)]
--
-- ![pixelChart_ example](other/pixelChart_Example.svg)
--
pixelChart_ :: (Traversable f) => Rect Double -> [f Pixel] -> Chart b
pixelChart_ asp ps = pixelChart asp (fold $ fold . map pixelRect <$> ps) ps

-- | Options to pixelate a Rect using a function
data PixelationOptions = PixelationOptions
  { pixelationGradient :: Range (AlphaColour Double)
  , pixelationGrain :: Pair Int
  }

defaultPixelationOptions :: PixelationOptions
defaultPixelationOptions =
    PixelationOptions
      (Range (acolor $ UColor 0.47 0.73 0.86 1) (acolor $ UColor 0.01 0.06 0.22 1))
      (Pair 40 40)

-- | Transform a Rect into Pixels using a function over a Pair
pixelate ::
     PixelationOptions -> Rect Double -> (Pair Double -> Double) -> [Pixel]
pixelate (PixelationOptions (Range lc0 uc0) grain) xy f = zipWith Pixel g (ucolor <$> cs)
  where
    g = gridSpace xy grain
    xs = f . mid <$> g
    (Range lx ux) = space xs
    cs = (\x -> blend ((x - lx) / (ux - lx)) lc0 uc0) <$> xs

-- | Chart pixels using a function
-- This is a convenience function, and the example below is equivalent to the pixelChart_ example
--
-- > pixelateChart def asquare one (\(Pair x y) -> (x+y)*(x+y))
--
pixelateChart ::
     PixelationOptions
  -> Rect Double
  -> Rect Double
  -> (Pair Double -> Double)
  -> Chart b
pixelateChart opts asp xy f = pixelChart asp xy [pixelate opts xy f]
