{ pkgs ? import <nixpkgs> {} }:

let
  R = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      TSP
      jsonlite
    ];
  };
in
pkgs.writeShellScriptBin "solve-tsp" ''
exec ${R}/bin/Rscript ${./solve.R} "$@"
''
