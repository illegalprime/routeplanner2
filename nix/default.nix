with import (builtins.fetchTarball {
  name = "nixos-unstable-2022-02-01";
  url = "https://github.com/nixos/nixpkgs/archive/3adc92feb3dc69578b1e40b948629747417cae02.tar.gz";
  sha256 = "14jl3zxdn5n4wwcfy78hh8w5x06c34diz9qpbzvb748dly67r65n";
}) {};

let
  fetchMixDeps = callPackage ./fetch-mix-deps.nix {
    inherit (beam.packages.erlangR24) hex rebar rebar3;
    elixir = beam.packages.erlangR24.elixir_1_12;
  };

  buildMix = callPackage ./build-mix.nix {
    inherit (beam.packages.erlangR24) hex rebar rebar3;
    elixir = beam.packages.erlangR24.elixir_1_12;
    inherit fetchMixDeps;
  };
in
buildMix {
  pname = "routeplanner";
  version = "0.5.0";
  mixSha256 = "0hidvkdm5fhp9gl8ln71k5zn50f5g83xpari23qly65gm0hgkmsq";
  src = builtins.fetchGit ../.;

  impureEnvVars = [
    "DATABASE_URL" "SECRET_KEY_BASE"
  ];
}
