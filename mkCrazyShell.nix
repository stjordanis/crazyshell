{ pkgs
, name ? "crazy-shell"
, promptFunction ? ''
    :{
    promptFunction :: [String] -> Int -> IO String
    promptFunction _modules _line = do
      d <- getEnv "PWD"
      setCurrentDirectory d
      pure $ "\ESC[31m\STXC\ESC[32m\STXr\ESC[33m\STXa\ESC[34m\STXz\ESC[35m\STXy\ESC[m\STX: "
    :}
    ''
, haskellPackages

, ghciOptions ? [
    "-XDataKinds"
    "-XExtendedDefaultRules"
    "-XGHC2021"
    "-XOverloadedStrings"
    "-XOverloadedLabels"
    "-Wall"
    "-Wno-type-defaults"
  ]

, header ? ''
   \ESC[31m\STX #####  \ESC[32m\STX######  \ESC[33m\STX   #    \ESC[34m\STX####### \ESC[35m\STX#     #    \ESC[36m\STX #####  \ESC[31m\STX#     # \ESC[32m\STX####### \ESC[33m\STX#       \ESC[34m\STX#       
   \ESC[31m\STX#     # \ESC[32m\STX#     # \ESC[33m\STX  # #   \ESC[34m\STX     #  \ESC[35m\STX #   #     \ESC[36m\STX#     # \ESC[31m\STX#     # \ESC[32m\STX#       \ESC[33m\STX#       \ESC[34m\STX#       
   \ESC[31m\STX#       \ESC[32m\STX#     # \ESC[33m\STX #   #  \ESC[34m\STX    #   \ESC[35m\STX  # #      \ESC[36m\STX#       \ESC[31m\STX#     # \ESC[32m\STX#       \ESC[33m\STX#       \ESC[34m\STX#       
   \ESC[31m\STX#       \ESC[32m\STX######  \ESC[33m\STX#     # \ESC[34m\STX   #    \ESC[35m\STX   #       \ESC[36m\STX #####  \ESC[31m\STX####### \ESC[32m\STX#####   \ESC[33m\STX#       \ESC[34m\STX#       
   \ESC[31m\STX#       \ESC[32m\STX#   #   \ESC[33m\STX####### \ESC[34m\STX  #     \ESC[35m\STX   #       \ESC[36m\STX      # \ESC[31m\STX#     # \ESC[32m\STX#       \ESC[33m\STX#       \ESC[34m\STX#       
   \ESC[31m\STX#     # \ESC[32m\STX#    #  \ESC[33m\STX#     # \ESC[34m\STX #      \ESC[35m\STX   #       \ESC[36m\STX#     # \ESC[31m\STX#     # \ESC[32m\STX#       \ESC[33m\STX#       \ESC[34m\STX#       
   \ESC[31m\STX #####  \ESC[32m\STX#     # \ESC[33m\STX#     # \ESC[34m\STX####### \ESC[35m\STX   #       \ESC[36m\STX #####  \ESC[31m\STX#     # \ESC[32m\STX####### \ESC[33m\STX####### \ESC[34m\STX#######\ESC[m\STX
 ''

, notice ? ''
    \ESC[1mNOTICE: This is version 0.0.1 of Crazy Shell\ESC[m\STX
  ''

, base-libraries ? (p : 
    [ p.bytestring
      p.text
    ]
    )

, libraries ? (p : 
  [ p.aeson
    p.dhall
    p.http-conduit
    p.lens
    p.lens-aeson
    p.procex
  ]
  )

, ghci-script ? ''
  :{
    ls :: IO [FilePath]
    ls = listDirectory "."
  :}
  ''

, module-imports ? ''
      import qualified Control.Lens         as L
      import qualified Data.Aeson           as A
      import qualified Data.Aeson.KeyMap    as A
      import qualified Data.Aeson.Lens      as L
      import qualified Data.ByteString      as BS
      import qualified Data.Text            as T
      import qualified Data.Text.Encoding   as T
      import qualified Dhall                
      import qualified Dhall.Core           as Dhall
      import qualified Dhall.Pretty         as Dhall
      import qualified Network.HTTP.Simple  as HTTP
      import           Procex.Shell         (cd, initInteractive)
      import qualified Procex.Shell         as P ()
      import           System.Directory     (listDirectory, setCurrentDirectory)
      import           System.Environment   (getEnv, setEnv)
   ''

, advice ? ''
    This is the default crazy shell, but you can make your own!

    You can cd around with \ESC[1mcd \"..\"\ESC[m\STX etc.

    The following commands are available:

      ls
      cd
  ''

}:

let

  libs = libraries haskellPackages;

  ghc = haskellPackages.ghcWithPackages (p: libs ++ base-libraries p );

  args = builtins.concatStringsSep " " ghciOptions;

  mapPutStrLn = f: z: builtins.concatStringsSep "\n" (map (x: "putStrLn \"  ${f x}\"") z);

  mapPutStrLnInd = f: z: builtins.concatStringsSep "\n" (map (x: "putStrLn \"    ${f x}\"") z);
  
  onPutStrLn = z: mapPutStrLn (x: x) (pkgs.lib.splitString "\n" z);

  onPutStrLnInd = z: mapPutStrLnInd (x: x) (pkgs.lib.splitString "\n" z);

  init = pkgs.runCommand "ghci-init" { } ''
    cat > $out <<END
      ${module-imports}

      :set +m -interactive-print Text.Pretty.Simple.pPrint

      ${promptFunction}

      initInteractive

      getEnv "REALHOME" >>= setEnv "HOME"

      import Procex.Shell.Labels

      :set prompt-function promptFunction

      ${module-imports}

      putStrLn ""

      ${onPutStrLn header}

      putStrLn ""

      ${onPutStrLn notice}

      putStrLn ""

      putStrLn "  The following haskell libraries are available:"

      putStrLn ""

      ${mapPutStrLnInd (x: x.name) libs}

      putStrLn ""

      putStrLn "  The following modules are loaded:"

      putStrLn ""

      ${onPutStrLnInd module-imports}

      putStrLn ""

      ${onPutStrLn advice}

      ${module-imports}

      ${ghci-script}
    END
  '';

in

(pkgs.writeShellScriptBin name ''

  home="$HOME/.local/share/ghci-shell"

  mkdir -p "$home"

  exec env GHCRTS="-c" HOME="$home" REALHOME="$HOME" ${ghc}/bin/ghci ${args} -ignore-dot-ghci -i -ghci-script ${init} "$@"

'').overrideAttrs (old: old // { passthru = { shellPath = "/bin/${name}"; }; })
