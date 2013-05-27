module Unit.Parse.LitSpec where

import Test.Hspec

import Forml.AST
import Forml.Parse.Lit

import Utils

spec :: Spec
spec = do

    describe "Forml.Parser.Lit" $ do

    	describe "litP" $ do

            it "should parse integers" $ assertParse litP
                "1" $ Right (NumLit 1)

            it "should parse floats" $ assertParse litP
                "3.14" $ Right (NumLit 3.14)

            it "should fail to parse negatives" $ assertParse litP
                "-3.14" $ Left (Err "(line 1, column 1):\nunexpected \"-\"\nexpecting literal string or number")

            it "should fail to parse symbols" $ assertParse litP
                "hello" $ Left (Err "(line 1, column 1):\nunexpected \"h\"\nexpecting literal string or number")

            it "should parse strings" $ assertParse litP
                "\"test\"" $ Right (StrLit "test")

            it "should parse stringswith escapes " $ assertParse litP
                "\"te\\\"st\"" $ Right (StrLit "te\"st")


