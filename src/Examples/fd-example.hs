{-# LANGUAGE CPP #-}
module Main where
import qualified Graphics.UI.FLTK.LowLevel.FL as FL
import Graphics.UI.FLTK.LowLevel.Fl_Types
import Graphics.UI.FLTK.LowLevel.FLTKHS
import Foreign.C.String
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Marshal.Alloc

pingCommand :: String
#ifdef mingw32_HOST_OS
pingCommand = "ping -n 10 localhost" -- 'slow command' under windows
#else
pingCommand = "ping -i 2 -c 10 localhost"
#endif

handleFD :: Ptr () -> Ref Browser -> CInt -> IO ()
handleFD stream b fd =
  getLineShim stream >>= maybe atEOF (add b)
  where
    atEOF = do
      FL.removeFd fd
      pcloseShim stream
      add b ""
      add b "<<DONE>>"

main :: IO ()
main = do
  w <- windowNew (Size (Width 600) (Height 600)) Nothing Nothing
  begin w
  b <- browserNew (toRectangle (10,10,580,580)) Nothing
  setType b MultiBrowserType
  pingCommandPtr <- newCString pingCommand
  stream <- popenShim pingCommandPtr
  fd <- filenoShim stream
  FL.addFd fd (handleFD stream b)
  end w
  setResizable w (Just b)
  showWidget w
  _ <- FL.run
  return ()

-- All of these C shims to popen, pclose etc. are necessary because
-- unfortunately there aren't portable equivalents in the Haskell
-- libraries. They all seem to depend on the `unix` package which
-- will not build on Windows.
getLineShim :: Ptr () -> IO (Maybe String)
getLineShim stream = do
  linePtr <- getLineShim' stream
  if (linePtr == nullPtr)
    then return Nothing
    else do
     line <- peekCString linePtr
     free linePtr
     return (Just line)

foreign import ccall safe "Examples/PopenShim.H popenShim" popenShim ::
    Ptr CChar -> IO (Ptr ())

foreign import ccall safe "Examples/popenShim.H filenoShim" filenoShim ::
    Ptr () -> IO CInt

foreign import ccall safe "Examples/popenShim.H pcloseShim" pcloseShim ::
    Ptr () -> IO ()

foreign import ccall safe "Examples/popenShim.H getLineShim" getLineShim' ::
    Ptr () -> IO (Ptr CChar)
