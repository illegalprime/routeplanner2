{ pkgs ? import <nixpkgs> {} }:

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

  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";

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
