------------------------------------------------------------------------------

-- | Notation parsing

------------------------------------------------------------------------------

{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Forml.Parse.Macro(
    macroPRec,
    filterP
) where

import Control.Arrow
import Control.Applicative
import Text.Parsec hiding ((<|>), many)

import Forml.AST
import Forml.Macro.LetPatt
import Forml.Macro.Replace
import Forml.Parse.Indent
import Forml.Parse.Syntax
import Forml.Parse.Val()
import Forml.Parse.Patt()
import Forml.Parse.Token

------------------------------------------------------------------------------

-- TODO this can be simplified alot

type PartMacro a = (a -> a, MacList a)

macroPRec :: (Syntax a, Replace LetPatt a, Replace Sym a, Replace Expr a, Replace Patt a, Syntax Expr) => 
    MacList a -> Parser (PartMacro a)

macroPRec = 
    merge rootP
    where

        merge f (MacList ms) =
            foldl (<|>) parserZero (fmap f ms)

        rootP (Term Sep xs) = 
            withSep (merge rootP xs)

        rootP (Leaf x) = 
            return (const x, undefined)

        rootP x = 
            bothP rootP x

        scopeP (Term Sep xs) = 
            return (id, xs)

        scopeP (Leaf _) = 
            parserZero

        scopeP x = 
            bothP scopeP x

        bothP m (Term Scope xs) = do
            (ap, cont) <- withCont (merge scopeP xs)
            first (ap .) <$> withSep (merge m cont)

        bothP m (Term (Token "<") exs) =
            reservedOp "<" >> merge m exs

        bothP m (Term (Token "</") exs) = 
            reservedOp "</" >> merge m exs

        bothP m (Term (Token x) exs) = 
            reserved x >> merge m exs

        bothP m (Term (Pat a) exs) = 
            wrap (syntax :: Parser Patt) a m exs

        bothP m (Term (Arg a) exs) =
            wrap (syntax :: Parser Expr) a m exs

        bothP m (Term (Let a) exs) =
            try (wrap (syntax :: Parser Sym) a m exs <|> wrap letPattP a m exs)
            where
                letPattP = LetPatt <$> syntax <* indented

        bothP _ _ = 
            error "Unimplemented"

        wrap p a m exs = 
            first . (.) . replace a <$> p <*> merge m exs

filterP :: MacList Expr -> MacList Expr

filterP (MacList (Term (Arg _) _ : ms)) =
    filterP (MacList ms)

filterP (MacList (x : ms)) =
    case filterP (MacList ms) of
        (MacList mss) -> MacList (x : mss)

filterP x =
    x

------------------------------------------------------------------------------
