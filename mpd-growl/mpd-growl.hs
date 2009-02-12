-- mpd-growl: Simple MPD monitor
-- ghc -package libmpd -O2 mpd-growl.hs -o mpd-growl

import qualified Network.MPD as MPD
import Control.Concurrent (threadDelay)
import System.Process (runCommand, runInteractiveCommand)
import System.IO (hGetLine, hIsEOF, Handle)

main :: IO a
main = monitor (Right Nothing) (Nothing)

monitor :: MPD.Response (Maybe MPD.Song) -> Maybe MPD.State -> IO a
monitor lastResponse lastState =
  do response <- MPD.withMPD $ MPD.currentSong
     status <- MPD.withMPD $ MPD.status

     let Right maybeSong = response
         Just song = maybeSong
         state = Just $ getState status

     if response /= lastResponse || (state /= lastState && state == Just MPD.Playing)
       then growl song
       else threadDelay 3000000 -- wait 3 seconds

     monitor response state -- loop forever

getState :: Either a MPD.Status -> MPD.State
getState (Right status) = MPD.stState status

prefix = "/usr/local/bin"
growlCommand = prefix ++ "/growlnotify -n mpd-growl -w "
albumArtCommand = prefix ++ "/fetch-albumart "

growl :: MPD.Song -> IO ()
growl song =
  do image <- getAlbumArt song
     let imageFlag = " --image '" ++ image ++ "'"
     runCommand $ growlCommand ++ args ++ imageFlag
     return ()
  where args = growlArgs song

growlArgs :: MPD.Song -> String
growlArgs MPD.Song {MPD.sgTitle=title, MPD.sgArtist=artist, MPD.sgAlbum=album} =
  escaped title ++ " -m " ++ escaped dashedName
  where dashedName = separate album " - " artist

getAlbumArt :: MPD.Song -> IO String
getAlbumArt MPD.Song {MPD.sgArtist=artist, MPD.sgAlbum=album} =
  do (_,stdout,_,_) <- runInteractiveCommand command
     safeGetLine stdout
  where albumAndArtist = separate (escaped album) " " (escaped artist)
        command = albumArtCommand ++ albumAndArtist

safeGetLine :: Handle -> IO String
safeGetLine h =
  do isEOF <- hIsEOF h
     case isEOF of
       True -> return ""
       False -> hGetLine h
       
separate :: String -> String -> String -> String
separate s1 sep s2 
  | s1 == ""  = s2
  | s2 == ""  = s1
  | otherwise = s1 ++ sep ++ s2

escaped :: String -> String
escaped s = "'" ++ (replace '\'' "\'\\\'\'" s) ++ "'"

replace :: (Eq a) => a -> [a] -> [a] -> [a]
replace o n h = _replace o n (length n) h

_replace :: (Eq a) => a -> [a] -> Int -> [a] -> [a]
_replace o n ns (x:xs)
  | x == o    = n ++ xs
  | otherwise = _replace o newn ns xs
  where newn = insertAt x n (length n - ns + 1)
_replace _ n ns xs = take (length n - ns) n ++ xs

insertAt :: a -> [a] -> Int -> [a]
insertAt x ys     1 = x:ys
insertAt x (y:ys) n = y:insertAt x ys (n-1)
