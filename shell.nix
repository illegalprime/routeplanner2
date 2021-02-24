{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  elixir = beam.packages.erlangR21.elixir_1_8;
  nodejs = nodejs-10_x;
  postgresql = postgresql_10;

  tspbin = callPackage ./tsp {};
in

mkShell {
  buildInputs = [
    elixir
    nodejs
    git
    postgresql
    tspbin
  ]
  ++ optional stdenv.isLinux inotify-tools # For file_system on Linux.
  ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    # For file_system on macOS.
    CoreFoundation
    CoreServices
  ]);

  # Put the PostgreSQL databases in the project diretory.
  shellHook = ''
    export PGDATA="$PWD/db"
    export TSP_BIN_PATH='${tspbin}/bin/solve-tsp'
  '';
}
