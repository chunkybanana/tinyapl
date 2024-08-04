module TinyAPL.CoreQuads where

import TinyAPL.ArrayFunctionOperator
import TinyAPL.Error
import qualified TinyAPL.Glyphs as G
import TinyAPL.Interpreter
import TinyAPL.Random

import Data.Complex
import Control.Monad.State
import Control.Monad.Error.Class ( liftEither )
import Data.Time.Clock.POSIX
import Control.Concurrent

io = Nilad (Just $ pure $ scalar $ Number 1) Nothing (G.quad : "io")
ct = Nilad (Just $ pure $ scalar $ Number $ comparisonTolerance :+ 0) Nothing (G.quad : "ct")
u = Nilad (Just $ pure $ vector $ Character <$> ['A'..'Z']) Nothing (G.quad : "u")
l = Nilad (Just $ pure $ vector $ Character <$> ['a'..'z']) Nothing (G.quad : "l")
d = Nilad (Just $ pure $ vector $ Character <$> ['0'..'9']) Nothing (G.quad : "d")
seed = Nilad Nothing (Just $ \x -> do
  let e = DomainError "Seed must be a scalar integer"
  s <- liftEither (asScalar e x) >>= liftEither . asNumber e >>= liftEither . asInt e
  setSeed s) (G.quad : "seed")
ts = Nilad (Just $ scalar . Number . realToFrac <$> liftToSt getPOSIXTime) Nothing (G.quad : "ts")

exists = Function (Just $ \x -> do
  let var = show x
  scope <- gets contextScope
  case scopeLookup var scope of
    Just _ -> return $ scalar $ Number 1
    Nothing -> return $ scalar $ Number 0
  ) Nothing (G.quad : "Exists")
repr = Function (Just $ \x -> return $ vector $ Character <$> arrayRepr x) Nothing (G.quad : "Repr")
delay = Function (Just $ \x -> do
  let err = DomainError "Delay argument must be a nonnegative scalar number"
  n <- asScalar err x >>= asNumber err >>= asReal err
  if n < 0 then throwError err else do
    start <- realToFrac <$> liftToSt getPOSIXTime
    liftToSt $ threadDelay $ floor $ n * 1000 * 1000
    end <- realToFrac <$> liftToSt getPOSIXTime
    pure $ scalar $ Number $ (end - start) :+ 0
  ) Nothing (G.quad : "Delay")

core = quadsFromReprs [ io, ct, u, l, d, seed, ts ] [ exists, repr, delay ] [] []
