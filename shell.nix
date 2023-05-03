{ pkgs ? import (builtins.fetchTarball {
  name = "nixpkgs-darwin-21.11-routeplanner";
  sha256 = "0gqzshg6xlkv11v8p23fyj4h5bi7kh0zfygh7rd1y77y716cm8xi";
  url = let rev = "5dab6490fe6d72b3f120ae8660181e20f396fbdf"; in
    "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
}) {}}:

with pkgs;

let
  inherit (lib) optional optionals;

  elixir = elixir_1_12;
  postgresql = postgresql_13;

  pwd = toString ./.;
  tspbin = callPackage ./tsp {};
in

mkShell {
  buildInputs = [
    elixir
    git
    postgresql
    tspbin
  ]
  # For file_system on Linux.
  ++ optional stdenv.isLinux inotify-tools
  # For file_system on macOS.
  ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    CoreFoundation
    CoreServices
  ]);

  # Put the PostgreSQL databases in the project diretory.
  # NOTE: the following secrets are dev only, not used in prod
  shellHook = ''
    export PGDATA="$PWD/db"
    export TSP_BIN_PATH='${tspbin}/bin/solve-tsp'
    export SECRET_KEY_BASE='IMWUvsjUr7Z+he8kkdEM44oHMJD0YBXB4mUibiF26Q/7dhxspFuFDmUgk78rPabQ'
    export LIVE_SIGNING_KEY='qRzDgAbNUfWc/CzhYglGl1zy/Vf6p8mM6CM64+GEJT//CeZ6I5MOIYbNcBuof2wd'
    export GUARDIAN_SECRET_KEY='bVXN1JqsDxmMcmAV7k4rnHDLwq0ZPkGAQQzLr4etBuF5C/jvX0iiCmT3sjR1W+xZ'
    export API_KEY='f9965f24-d941-11ed-a3a0-7b869d1e4a4e'
  '';
}
