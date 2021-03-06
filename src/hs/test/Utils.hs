{-# OPTIONS_GHC -fno-warn-orphans #-}

module Utils where

import System.IO
import System.Process
import System.Exit
import Test.HUnit
import Text.Parsec
import Test.QuickCheck
import Language.Javascript.JMacro

import Minml.AST
import Minml.Parse.Token
import Minml.Prelude
import Minml.RenderText


import Control.Monad

instance Arbitrary Sym where

    arbitrary = (Sym . (:[])) `fmap` choose ('a', 'z')

instance Arbitrary Lit where

    arbitrary = oneof [ StrLit `fmap` oneof (return `fmap` [ "string1", "string2", "string3" ])
                      , NumLit `fmap` oneof (return `fmap` [ 1, 2, 3, 4, 5, 6, 7 ]) ]

instance Arbitrary Val where

    arbitrary = oneof [ SymVal `fmap` arbitrary
                      , LitVal `fmap` arbitrary ]

instance Arbitrary Expr where

    arbitrary = sized expr'
        where
            expr' 0 = VarExpr `fmap` arbitrary
            expr' n = oneof [ liftM3 LetExpr arbitrary subExprr (Just `fmap` subExprr)
                            , liftM2 AppExpr subExprr subExprr
                            , liftM2 AbsExpr arbitrary subExprr
                            , liftM  VarExpr arbitrary ]

                where subExprr = expr' (n `div` 10)

assertParse :: (Eq a, Show a) => Parser a -> String -> Either Err a -> Assertion
assertParse p a b = assertEqual "" b parseResult
    where
        parseResult = case runParser p emptyState "" a of
            Left x -> Left . Err . show $ x
            Right x -> Right x

assertGenerate :: (ToJExpr a) => a -> Either Err String -> Assertion
assertGenerate a = assertEqual "" gen
    where
        gen = renderText $ toJExpr a 


nodejs :: String -> IO String
nodejs js = do

    (Just std_in', Just std_out', Just std_err', p) <-
        createProcess (proc "node" []) { std_in = CreatePipe, std_out = CreatePipe, std_err = CreatePipe }

    hPutStrLn std_in' $ js ++ ";process.exit(0);\n"

    z <- waitForProcess p
    status <- hGetContents std_out'
    errs <- hGetContents std_err'
    
    case z of
        ExitFailure n -> return $ "FATAL: error code " ++ show n ++ "\n" ++ errs
        ExitSuccess   -> return status
    


