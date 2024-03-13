module Main where

import TinyAPL.ArrayFunctionOperator
import TinyAPL.Error
import qualified TinyAPL.Glyphs as G
import qualified TinyAPL.Primitives as P
import TinyAPL.Interpreter

import Data.Complex
import System.Environment
import Control.Monad (void)
import System.IO
import Data.Functor (($>))
import Data.List (singleton)
import Data.Maybe (fromJust)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8

  let a = vector $ Number <$> [1, 2, -1]
  let b = vector $ Number <$> [5, 2.1, 3 :+ (-0.5)]

  let i = fromJust $ arrayReshaped [3, 3] $ Number <$> [ 1, 0, 0
                                                       , 0, 1, 0
                                                       , 0, 0, 1 ]

  let inc = BindRight P.plus (scalar $ Number 1)
  
  putStrLn "a"; print a
  putStrLn "b"; print b
  putStrLn "i"; print i
  putStrLn "I"; print inc

  let scope = Scope [("a", a), ("b", b), ("i", i)] [("I", inc)] [] [] Nothing

  args <- getArgs
  case args of
    []     -> repl scope
    [path] -> do
      code <- readFile path
      void $ runCode False path code scope
    _      -> do
      hPutStrLn stderr "Usage:"
      hPutStrLn stderr "tinyapl         Start a REPL"
      hPutStrLn stderr "tinyapl path    Run a file"

runCode :: Bool -> String -> String -> Scope -> IO Scope
runCode output file code scope = do
  result <- runResult $ run file code scope
  case result of
    Left err -> hPrint stderr err $> scope
    Right (res, scope) -> if output then print res $> scope else return scope

repl :: Scope -> IO ()
repl scope = let
  go :: Scope -> IO Scope
  go scope = do
    putStr "> "
    hFlush stdout
    line <- getLine
    if line == "" then return scope
    else runCode True "<repl>" line scope >>= go
  in do
    putStrLn "TinyAPL REPL, empty line to exit"
    putStrLn "Supported primitives:"
    putStrLn $ "  " ++ unwords (singleton . fst <$> P.arrays)
    putStrLn $ "  " ++ unwords (singleton . fst <$> P.functions)
    putStrLn $ "  " ++ unwords (singleton . fst <$> P.adverbs)
    putStrLn $ "  " ++ unwords (singleton . fst <$> P.conjunctions)
    putStrLn "Supported features:"
    putStrLn $ "* dfns " ++ [fst G.braces] ++ "code" ++ [snd G.braces] ++ ", d-monadic-ops " ++ [G.underscore, fst G.braces] ++ "code" ++ [snd G.braces] ++ ", d-dyadic-ops " ++ [G.underscore, fst G.braces] ++ "code" ++ [snd G.braces, G.underscore]
    putStrLn $ "  " ++ [G.alpha] ++ " left argument, " ++ [G.omega] ++ " right argument,"
    putStrLn $ "  " ++ [G.alpha, G.alpha] ++ " left array operand, " ++ [G.alphaBar, G.alphaBar] ++ " left function operand, " ++ [G.omega, G.omega] ++ " right array operand, " ++ [G.omegaBar, G.omegaBar] ++ " right function operand,"
    putStrLn $ "  " ++ [G.del] ++ " recurse function, " ++ [G.underscore, G.del] ++ " recurse monadic op, " ++ [G.underscore, G.del, G.underscore] ++ " recurse dyadic op"
    putStrLn $ "  " ++ [G.exit] ++ " early exit, " ++ [G.guard] ++ " guard"
    putStrLn $ "  " ++ [G.separator] ++ " multiple statements"
    putStrLn $ "* numbers: " ++ [G.decimal] ++ " decimal separator, " ++ [G.negative] ++ " negative sign, " ++ [G.exponent] ++ " exponent notation, " ++ [G.imaginary] ++ " complex separator"
    putStrLn $ "* character literals: " ++ [G.charDelimiter] ++ "abc" ++ [G.charDelimiter]
    putStrLn $ "* string literals: " ++ [G.stringDelimiter] ++ "abc" ++ [G.stringDelimiter] ++ " with escapes using " ++ [G.stringEscape]
    putStrLn $ "* names: abc array, Abc function, _Abc monadic op, _Abc_ dyadic op, assignment with " ++ [G.assign]
    putStrLn $ "* get " ++ [G.quad] ++ " read evaluated input, get " ++ [G.quadQuote] ++ " read string input, set " ++ [G.quad] ++ " print with newline, set " ++ [G.quadQuote] ++ " print without newline"
    void $ go scope 
