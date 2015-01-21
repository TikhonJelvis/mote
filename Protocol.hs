{-# LANGUAGE LambdaCase, ViewPatterns, OverloadedStrings #-}
module Protocol where

import qualified Data.Vector as V
import qualified Data.Text as T
import Data.Aeson
import Control.Applicative
import Control.Monad

data ToClient
  = Insert T.Text
  | SetInfoWindow T.Text
  | SetCursor (Int, Int)
  | Ok
  | Error T.Text

instance ToJSON ToClient where
  toJSON = \case
    Insert t        -> Array $ V.fromList [toJSON (str "Insert"), toJSON t]
    SetInfoWindow t -> Array $ V.fromList [toJSON (str "SetInfoWindow"), toJSON t]
    SetCursor pos   -> Array $ V.fromList [toJSON (str "SetCursor"), toJSON pos]
    Ok              -> Array $ V.fromList [toJSON (str "Ok")]
    Error t         -> Array $ V.fromList [toJSON (str "Error"), toJSON t]
    where
    str x = x :: String

type Var = String

data ClientState = ClientState { path :: FilePath, cursorPos :: (Int, Int) }

instance FromJSON ClientState where
  parseJSON (Object v) = ClientState <$> v .: "path" <*> v .: "cursorPos"
  parseJSON _          = mzero

-- Things could be a bit more efficient if the client held on to which hole
-- they're in. Probably not necessary, but if things are slow, consider
-- it.
data FromClient
  = Load FilePath
  | CaseFurther Var
  | CaseOn Var
  | EnterHole ClientState
  | NextHole ClientState
  | PrevHole ClientState
  | HoleContaining (Int, Int)
  | GetEnv ClientState

instance FromJSON FromClient where
  parseJSON = \case
    Array a -> case V.toList a of
      [String "Load", String path]       -> return (Load (T.unpack path))
      [String "CaseFurther", String var] -> return (CaseFurther (T.unpack var))
      [String "NextHole", state]         -> NextHole <$> parseJSON state
      [String "PrevHole", state]         -> PrevHole <$> parseJSON state
      _                                  -> mzero

