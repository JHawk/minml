module Unit.Parse.ExprSpec where

import Test.Hspec
import Test.HUnit

import Forml.Parse
import Forml.AST

assertParse :: String -> Either Err Expr -> Assertion
assertParse a b = flip (assertEqual "") (parseForml a) b

spec :: Spec
spec = do

    describe "Forml.Parser" $ do

    	describe "parseForml" $ do

            it "should parse a trivial example " $ assertParse
              
                "   2 + 2.0 == 4.0   "

                (Right (AppExpr (AppExpr (VarExpr (SymVal (Sym "==")))
                                         (AppExpr (AppExpr (VarExpr (SymVal (Sym "+")))
                                                           (VarExpr (LitVal (NumLit 2.0))))
                                                  (VarExpr (LitVal (NumLit 2.0)))))
                                (VarExpr (LitVal (NumLit 4.0)))))

            it "should parse simple type errors" $ assertParse

                "   4 + \"whoops\"   "

                (Right (AppExpr (AppExpr (VarExpr (SymVal (Sym "+")))
                                         (VarExpr (LitVal (NumLit 4.0))))
                                (VarExpr (LitVal (StrLit "whoops")))))

            it "should parse let expressions" $ assertParse

                "   let x = 1.0;     \
                \   x + 1.0 == 2.0   "

                (Right (LetExpr (Sym "x") (VarExpr (LitVal (NumLit 1.0))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "=="))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 1.0))))) (VarExpr (LitVal (NumLit 2.0))))))

            it "should error when trying to parse a missing let continuation" $ assertParse

                "   let x = 1;   "

                (Left (Err "\"Parsing Forml\" (line 1, column 17):\n\
                    \unexpected end of input\n\
                    \expecting Let Expression, Type Kind Expression, Abstraction, Match Expression or Application"))

            it "should parse anonymous functions and application" $ assertParse

                "   (fun x -> x + 4) 2 == 6   "

                $ Right (AppExpr (AppExpr (VarExpr (SymVal (Sym "=="))) (AppExpr (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 4.0))))) (VarExpr (LitVal (NumLit 2.0))))) (VarExpr (LitVal (NumLit 6.0))))

            it "should parse anonymous functions in let bindings" $ assertParse
             
                "   let g = fun x -> x + 4;   \
                \   g 2 == 6                  "

                $ Right (LetExpr (Sym "g") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 4.0))))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "=="))) (AppExpr (VarExpr (SymVal (Sym "g"))) (VarExpr (LitVal (NumLit 2.0))))) (VarExpr (LitVal (NumLit 6.0)))))

            it "should parse match expressions" $ assertParse

                "   let fib = fun n ->                      \
                \       match n with                        \
                \       0 -> 0;                             \
                \       1 -> 1;                             \
                \       n -> fib (n - 1) + fib (n - 2);;    \
                \   fib 7                                   "

                $ Right (LetExpr (Sym "fib") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (LitVal (NumLit 0.0)),VarExpr (LitVal (NumLit 0.0))),(ValPatt (LitVal (NumLit 1.0)),VarExpr (LitVal (NumLit 1.0))),(ValPatt (SymVal (Sym "n")),AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 1.0)))))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 2.0))))))])) (AppExpr (VarExpr (SymVal (Sym "fib"))) (VarExpr (LitVal (NumLit 7.0)))))

            it "should fail to parse match mixed semicolon" $ assertParse

                "   let fib = fun n ->                      \
                \       match n with                        \
                \       0 -> 0;                             \
                \       1 -> 1;                             \
                \       n -> fib (n - 1) + fib (n - 2);     \
                \   fib 7                                   "

                $ Left (Err "\"Parsing Forml\" (line 1, column 223):\nunexpected \"7\"\nexpecting \"->\"")

            it "should parse match expressions with type errors" $ assertParse

                "   match 3 + 3 with \"gotcha\" -> false;   "

                $ Right (MatExpr (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (LitVal (NumLit 3.0)))) (VarExpr (LitVal (NumLit 3.0)))) [(ValPatt (LitVal (StrLit "gotcha")),VarExpr (SymVal (Sym "false")))])

            it "should parse user data types" $ assertParse

                "   data Cons: a -> List a -> List a;        \
                \   data Nil: List a;                        \
                \                                            \
                \   let length = fun n ->                    \
                \       match n with                         \
                \           Nil -> 0;                        \
                \           (Cons _ xs) -> 1 + length xs;;   \
                \                                            \
                \   length (Cons 1 (Cons 2 Nil))             "

                $ Right (TypExpr (TypeSymP "Cons") (TypeAbsP (TypeApp (TypeApp (TypeSym (TypeSymP "->")) (TypeVar (TypeVarP "a"))) (TypeApp (TypeApp (TypeSym (TypeSymP "->")) (TypeApp (TypeSym (TypeSymP "List")) (TypeVar (TypeVarP "a")))) (TypeApp (TypeSym (TypeSymP "List")) (TypeVar (TypeVarP "a")))))) (TypExpr (TypeSymP "Nil") (TypeAbsP (TypeApp (TypeSym (TypeSymP "List")) (TypeVar (TypeVarP "a")))) (LetExpr (Sym "length") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (ConVal (TypeSym (TypeSymP "Nil"))),VarExpr (LitVal (NumLit 0.0))),(ConPatt (TypeSymP "Cons") [ValPatt (SymVal (Sym "_")),ValPatt (SymVal (Sym "xs"))],AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (LitVal (NumLit 1.0)))) (AppExpr (VarExpr (SymVal (Sym "length"))) (VarExpr (SymVal (Sym "xs")))))])) (AppExpr (VarExpr (SymVal (Sym "length"))) (AppExpr (AppExpr (VarExpr (ConVal (TypeSym (TypeSymP "Cons")))) (VarExpr (LitVal (NumLit 1.0)))) (AppExpr (AppExpr (VarExpr (ConVal (TypeSym (TypeSymP "Cons")))) (VarExpr (LitVal (NumLit 2.0)))) (VarExpr (ConVal (TypeSym (TypeSymP "Nil"))))))))))

            it "should parse with generic type errors" $ assertParse

                "   data Just: a -> Maybe a;          \
                \   data None: Maybe a;               \
                \                                     \
                \   match Just 5 with                 \
                \       (Just \"blammo\") -> false;   "

                $ Right (TypExpr (TypeSymP "Just") (TypeAbsP (TypeApp (TypeApp (TypeSym (TypeSymP "->")) (TypeVar (TypeVarP "a"))) (TypeApp (TypeSym (TypeSymP "Maybe")) (TypeVar (TypeVarP "a"))))) (TypExpr (TypeSymP "None") (TypeAbsP (TypeApp (TypeSym (TypeSymP "Maybe")) (TypeVar (TypeVarP "a")))) (MatExpr (AppExpr (VarExpr (ConVal (TypeSym (TypeSymP "Just")))) (VarExpr (LitVal (NumLit 5.0)))) [(ConPatt (TypeSymP "Just") [ValPatt (LitVal (StrLit "blammo"))],VarExpr (SymVal (Sym "false")))])))

            it "should parse partial keywords" $ assertParse

                "   let letly = 4;                    \
                \   (let func = fun x -> x + ((2));   \
                \   func letly)                       "

                $ Right (LetExpr (Sym "letly") (VarExpr (LitVal (NumLit 4.0))) (LetExpr (Sym "func") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 2.0))))) (AppExpr (VarExpr (SymVal (Sym "func"))) (VarExpr (SymVal (Sym "letly"))))))

            it "should parse binding tricks" $ assertParse

                "   let x = 3;                 \
                \   let f = fun y -> y + x;    \
                \   let x = 2;                 \
                \   f 3 == 6                   "

                $ Right (LetExpr (Sym "x")
                                 (VarExpr (LitVal (NumLit 3.0)))
                                 (LetExpr (Sym "f") 
                                          (AbsExpr (Sym "y")
                                                   (AppExpr (AppExpr (VarExpr (SymVal (Sym "+")))
                                                                     (VarExpr (SymVal (Sym "y"))))
                                                            (VarExpr (SymVal (Sym "x")))))
                                          (LetExpr (Sym "x")
                                                   (VarExpr (LitVal (NumLit 2.0)))
                                                   (AppExpr (AppExpr (VarExpr (SymVal (Sym "==")))
                                                                     (AppExpr (VarExpr (SymVal (Sym "f")))
                                                                              (VarExpr (LitVal (NumLit 3.0)))))
                                                            (VarExpr (LitVal (NumLit 6.0)))))))

            describe "function application whitespace" $ do

                it "should fail to parse function application on separate lines" $ assertParse

                    "   f       \n\
                    \   4         "

                    $ Left (Err "\"Parsing Forml\" (line 2, column 4):\nunexpected '4'\nexpecting operator or end of input\nStatement indented (introduced at \"Parsing Forml\" (line 1, column 4))")

                it "should parse function application on separate lines indented" $ assertParse

                    "   f       \n\
                    \       4     "

                    $ Right (AppExpr (VarExpr (SymVal (Sym "f"))) (VarExpr (LitVal (NumLit 4.0))))

            describe "whitespace let" $ do

                it "should parse whitespace statement sep" $ assertParse

                    "   let letly = 4                    \n\
                    \   let func = fun x -> x + ((2))    \n\
                    \   func letly                       \n"

                    $ Right (LetExpr (Sym "letly") (VarExpr (LitVal (NumLit 4.0))) (LetExpr (Sym "func") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 2.0))))) (AppExpr (VarExpr (SymVal (Sym "func"))) (VarExpr (SymVal (Sym "letly"))))))

                it "should parse match expressions with mixed whitespace" $ assertParse

                    "   let fib = fun n ->                     \n\
                    \       match n with                       \n\
                    \       0 -> 0;                            \n\
                    \       1 -> 1;                            \n\
                    \       n -> fib (n - 1) + fib (n - 2);    \n\
                    \   fib 7                                  \n"

                    $ Right (LetExpr (Sym "fib") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (LitVal (NumLit 0.0)),VarExpr (LitVal (NumLit 0.0))),(ValPatt (LitVal (NumLit 1.0)),VarExpr (LitVal (NumLit 1.0))),(ValPatt (SymVal (Sym "n")),AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 1.0)))))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 2.0))))))])) (AppExpr (VarExpr (SymVal (Sym "fib"))) (VarExpr (LitVal (NumLit 7.0)))))

            describe "whitespace match" $ do

                it "should parse match expressions" $ assertParse

                    "   let fib = fun n ->                     \n\
                    \       match n with                       \n\
                    \       0 -> 0                             \n\
                    \       1 -> 1                             \n\
                    \       n -> fib (n - 1) + fib (n - 2)     \n\
                    \   fib 7                                  \n"

                    $ Right (LetExpr (Sym "fib") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (LitVal (NumLit 0.0)),VarExpr (LitVal (NumLit 0.0))),(ValPatt (LitVal (NumLit 1.0)),VarExpr (LitVal (NumLit 1.0))),(ValPatt (SymVal (Sym "n")),AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 1.0)))))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 2.0))))))])) (AppExpr (VarExpr (SymVal (Sym "fib"))) (VarExpr (LitVal (NumLit 7.0)))))

            describe "whitespace data" $ do

                it "should parse with generic type errors" $ assertParse

                    "   data Just: a -> Maybe a           \n\
                    \   data None: Maybe a                \n\
                    \                                     \n\
                    \   match Just 5 with                 \n\
                    \       (Just \"blammo\") -> false    \n"

                    $ Right (TypExpr (TypeSymP "Just") (TypeAbsP (TypeApp (TypeApp (TypeSym (TypeSymP "->")) (TypeVar (TypeVarP "a"))) (TypeApp (TypeSym (TypeSymP "Maybe")) (TypeVar (TypeVarP "a"))))) (TypExpr (TypeSymP "None") (TypeAbsP (TypeApp (TypeSym (TypeSymP "Maybe")) (TypeVar (TypeVarP "a")))) (MatExpr (AppExpr (VarExpr (ConVal (TypeSym (TypeSymP "Just")))) (VarExpr (LitVal (NumLit 5.0)))) [(ConPatt (TypeSymP "Just") [ValPatt (LitVal (StrLit "blammo"))],VarExpr (SymVal (Sym "false")))])))

            describe "without `let` keyword" $ do

                it "should parse whitespace statement sep" $ assertParse

                    "   letly = 4                        \n\
                    \   func = fun x -> x + ((2))        \n\
                    \   func letly                       \n"

                    $ Right (LetExpr (Sym "letly") (VarExpr (LitVal (NumLit 4.0))) (LetExpr (Sym "func") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 2.0))))) (AppExpr (VarExpr (SymVal (Sym "func"))) (VarExpr (SymVal (Sym "letly"))))))

                it "should parse match expressions" $ assertParse

                    "   fib = fun n ->                         \n\
                    \       match n with                       \n\
                    \       0 -> 0                             \n\
                    \       1 -> 1                             \n\
                    \       n -> fib (n - 1) + fib (n - 2)     \n\
                    \   fib 7                                  \n"

                    $ Right (LetExpr (Sym "fib") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (LitVal (NumLit 0.0)),VarExpr (LitVal (NumLit 0.0))),(ValPatt (LitVal (NumLit 1.0)),VarExpr (LitVal (NumLit 1.0))),(ValPatt (SymVal (Sym "n")),AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 1.0)))))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 2.0))))))])) (AppExpr (VarExpr (SymVal (Sym "fib"))) (VarExpr (LitVal (NumLit 7.0)))))

            describe "without `=` reserved operator" $ do

                it "should parse anonymous functions in let bindings" $ assertParse
                 
                    "   let g = fun x = x + 4    \n\
                    \   g 2 == 6                 \n"

                    $ Right (LetExpr (Sym "g") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 4.0))))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "=="))) (AppExpr (VarExpr (SymVal (Sym "g"))) (VarExpr (LitVal (NumLit 2.0))))) (VarExpr (LitVal (NumLit 6.0)))))

                it "should parse whitespace statement sep" $ assertParse

                    "   letly = 4                   \n\
                    \   func = fun x = x + ((2))    \n\
                    \   func letly                  \n"

                    $ Right (LetExpr (Sym "letly") (VarExpr (LitVal (NumLit 4.0))) (LetExpr (Sym "func") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 2.0))))) (AppExpr (VarExpr (SymVal (Sym "func"))) (VarExpr (SymVal (Sym "letly"))))))

                it "should parse match expressions" $ assertParse

                    "   fib = fun n =                          \n\
                    \       match n with                       \n\
                    \       0 -> 0                             \n\
                    \       1 -> 1                             \n\
                    \       n -> fib (n - 1) + fib (n - 2)     \n\
                    \   fib 7                                  \n"

                    $ Right (LetExpr (Sym "fib") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (LitVal (NumLit 0.0)),VarExpr (LitVal (NumLit 0.0))),(ValPatt (LitVal (NumLit 1.0)),VarExpr (LitVal (NumLit 1.0))),(ValPatt (SymVal (Sym "n")),AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 1.0)))))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 2.0))))))])) (AppExpr (VarExpr (SymVal (Sym "fib"))) (VarExpr (LitVal (NumLit 7.0)))))

            describe "with `λ` reserved operator" $ do

                it "should parse anonymous functions in let bindings" $ assertParse
                 
                    "   let g = λ x = x + 4      \n\
                    \   g 2 == 6                 \n"

                    $ Right (LetExpr (Sym "g") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 4.0))))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "=="))) (AppExpr (VarExpr (SymVal (Sym "g"))) (VarExpr (LitVal (NumLit 2.0))))) (VarExpr (LitVal (NumLit 6.0)))))

                it "should parse whitespace statement sep" $ assertParse

                    "   letly = 4                   \n\
                    \   func = λ x = x + ((2))      \n\
                    \   func letly                  \n"

                    $ Right (LetExpr (Sym "letly") (VarExpr (LitVal (NumLit 4.0))) (LetExpr (Sym "func") (AbsExpr (Sym "x") (AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (VarExpr (SymVal (Sym "x")))) (VarExpr (LitVal (NumLit 2.0))))) (AppExpr (VarExpr (SymVal (Sym "func"))) (VarExpr (SymVal (Sym "letly"))))))

                it "should parse match expressions" $ assertParse

                    "   fib = λ n =                            \n\
                    \       match n with                       \n\
                    \       0 -> 0                             \n\
                    \       1 -> 1                             \n\
                    \       n -> fib (n - 1) + fib (n - 2)     \n\
                    \   fib 7                                  \n"

                    $ Right (LetExpr (Sym "fib") (AbsExpr (Sym "n") (MatExpr (VarExpr (SymVal (Sym "n"))) [(ValPatt (LitVal (NumLit 0.0)),VarExpr (LitVal (NumLit 0.0))),(ValPatt (LitVal (NumLit 1.0)),VarExpr (LitVal (NumLit 1.0))),(ValPatt (SymVal (Sym "n")),AppExpr (AppExpr (VarExpr (SymVal (Sym "+"))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 1.0)))))) (AppExpr (VarExpr (SymVal (Sym "fib"))) (AppExpr (AppExpr (VarExpr (SymVal (Sym "-"))) (VarExpr (SymVal (Sym "n")))) (VarExpr (LitVal (NumLit 2.0))))))])) (AppExpr (VarExpr (SymVal (Sym "fib"))) (VarExpr (LitVal (NumLit 7.0)))))

------------------------------------------------------------------------------
