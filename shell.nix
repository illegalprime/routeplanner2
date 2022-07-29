{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  elixir = elixir_1_12;
  postgresql = postgresql_10;

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
  shellHook = ''
    export PGDATA="$PWD/db"
    export TSP_BIN_PATH='${tspbin}/bin/solve-tsp'
    source <(sed 's,^,export ,' ${pwd}/../nixops/secrets/routeplanner)
  '';
}
