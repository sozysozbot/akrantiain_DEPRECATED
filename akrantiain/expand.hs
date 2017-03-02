{-# OPTIONS -Wall -fno-warn-unused-do-bind #-}

module Akrantiain.Expand
(SemanticError(..)
,expand
,Conv2(..)
,Orthography'
) where

import Akrantiain.Structure
import qualified Data.Set as S
import qualified Data.Map as M

data SemanticError = E {errNum :: Int, errStr :: String} deriving(Show, Eq, Ord)
data Conv2 = Conv [Orthography'] [Phoneme] deriving(Show, Eq, Ord)
data Orthography' = Boundary' | Neg' Quote | Pos' Quote deriving(Show, Eq, Ord)

expand :: [Sentence] -> Either SemanticError [Conv2]
expand sents = do 
 (orthoset, identmap) <- split sents
 newMap <- candids_to_quotes identmap
 undefined newMap orthoset
 

candids_to_quotes :: M.Map Identifier [Candidates] -> Either SemanticError (M.Map Identifier [Quote])
candids_to_quotes old_map = c_to_q2 (old_map, M.empty)

type Temp = (M.Map Identifier [Candidates], M.Map Identifier [Quote]) 
c_to_q2 :: Temp -> Either SemanticError (M.Map Identifier [Quote])
c_to_q2 (cand_map, quot_map) = case M.lookupGE (Id "") cand_map of 
 Nothing -> return quot_map -- Any identifier is greater than (Id ""); if none, the cand_map must be empty
 Just (ident, candids) -> do
  ident_target {-:: [Quote]-} <- foo ident candids cand_map quot_map
  let cand_map' = M.delete ident cand_map
  let quot_map' = M.insert ident ident_target quot_map
  c_to_q2 (cand_map', quot_map')


foo = undefined
  

split :: [Sentence] -> Either SemanticError (S.Set([Orthography],[Phoneme]),M.Map Identifier [Candidates])
split [] = Right (S.empty, M.empty)
split (Conversion orthos phonemes : xs) = do 
  (s,m) <- split xs 
  return (S.insert (orthos, phonemes) s , m) -- duplicate is detected later
split (Define ident@(Id i) cands : xs) = do 
  (s,m) <- split xs 
  if ident `M.member` m 
   then Left $ E{errNum = 0, errStr = "duplicate definition of identifier {"++ i ++ "}"} 
   else Right (s, M.insert ident cands m)

