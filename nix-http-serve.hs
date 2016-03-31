{-# LANGUAGE OverloadedStrings #-}
module Main where

import Network.Wai
import Network.Wai.Application.Static (staticApp, defaultFileServerSettings)
import WaiAppStatic.Types (ssUseHash)
import Network.Wai.Handler.Warp

import Data.Maybe (fromMaybe)
import Data.String.Utils (rstrip)
import Data.IORef
import Data.Time (getCurrentTime, diffUTCTime, Day(ModifiedJulianDay), UTCTime(UTCTime))
import Control.Monad (when)
import Control.Monad.Extra (whenM)
import System.Process (readProcess)
import System.Directory
import System.Posix.Files (createSymbolicLink)
import System.FilePath ((</>), dropDrive)
import System.Posix.Env (getEnv)
import Text.Printf (printf)

cachingSeconds = 5

variateFolder :: FilePath -> String -> FilePath -> IO ()
variateFolder nixfile attr varfolder = do
  storePath <- rstrip <$> readProcess "nix-build" ["--no-out-link", nixfile, "--attr", attr] ""
  whenM (doesDirectoryExist varfolder)
    $ removeFile varfolder
  createSymbolicLink storePath varfolder


app :: IORef UTCTime -> FilePath -> String -> FilePath -> FilePath -> Application
app timeoutRef nixfile attr varfolder root = \req respond -> do
    currentTime <- getCurrentTime
    lastTime <- readIORef timeoutRef

    when ((diffUTCTime currentTime lastTime) > cachingSeconds) $ do

      home <- getHomeDirectory
      variateFolder nixfile attr varfolder
      atomicWriteIORef timeoutRef currentTime

    let set = (defaultFileServerSettings $ varfolder </> (dropDrive root))
                 { ssUseHash = True }
    staticApp set req respond


main = do
  port <- read <$> required "port" :: IO Port
  varfolder <- required "varfolder"
  root <- required "root"
  nixfile <- required "nixfile"
  attr <- optional "" "attribute"
  timeoutRef <- newIORef $ UTCTime (ModifiedJulianDay 0) 0
  run port $ app timeoutRef nixfile attr varfolder root
    where
      optional opt env = fromMaybe opt <$> getEnv env
      required env = optional (error "Environment variable \"" ++ env ++ "\" is needed.") env
