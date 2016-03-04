{-# LANGUAGE OverloadedStrings #-}
module Main where

import Network.Wai
import Network.Wai.Application.Static (staticApp, defaultFileServerSettings, ssGetMimeType)
import Network.Wai.Handler.Warp

import Data.String.Utils (rstrip)
import Data.IORef
import Data.Time (getCurrentTime, diffUTCTime, Day(ModifiedJulianDay), UTCTime(UTCTime))
import Control.Monad (when)
import Control.Monad.Extra (whenM)
import System.Process (readProcess)
import System.Directory
import System.Posix.Files (createSymbolicLink)
import System.FilePath ((</>), dropDrive)
import System.Environment (getEnv)
import Text.Printf (printf)

cachingSeconds = 5

variateFolder :: FilePath -> FilePath -> IO ()
variateFolder nixfile varfolder = do
  storePath <- rstrip <$> readProcess "nix-build" ["--no-out-link", nixfile] ""
  whenM (doesDirectoryExist varfolder)
    $ removeFile varfolder
  createSymbolicLink storePath varfolder


app :: IORef UTCTime -> FilePath -> FilePath -> FilePath -> Application
app timeoutRef nixfile varfolder root = \req respond -> do
    currentTime <- getCurrentTime
    lastTime <- readIORef timeoutRef

    when ((diffUTCTime currentTime lastTime) > cachingSeconds) $ do

      home <- getHomeDirectory
      variateFolder nixfile varfolder
      atomicWriteIORef timeoutRef currentTime

    let set = defaultFileServerSettings $ varfolder </> (dropDrive root)
    staticApp set req respond


main = do
  port <- read <$> getEnv "port" :: IO Port
  varfolder <- getEnv "varfolder"
  root <- getEnv "root"
  nixfile <- getEnv "nixfile"
  timeoutRef <- newIORef $ UTCTime (ModifiedJulianDay 0) 0
  run port $ app timeoutRef nixfile varfolder root
