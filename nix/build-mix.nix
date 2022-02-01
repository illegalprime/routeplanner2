{ stdenv, elixir, hex, rebar, rebar3, fetchMixDeps, erlang, glibcLocales, esbuild, callPackage }:

{ name ? "${args.pname}-${args.version}"
, mixSha256 ? null
, src ? null
, sourceRoot ? null
, buildInputs ? []
, nativeBuildInputs ? []
, buildType ? "release"
, meta ? {}
, mixEnv ? "prod"
, impureMixRebar ? false
, ... } @ args:

let
  mixDeps = fetchMixDeps {
    inherit src name mixEnv;
    sha256 = mixSha256;
  };
in stdenv.mkDerivation (args // {
  dontStrip = true;

  nativeBuildInputs = nativeBuildInputs ++ [ hex elixir erlang ];

  LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";

  MIX_ENV = mixEnv;
  HEX_OFFLINE = 1;

  setRebar = if impureMixRebar
             then "mix local.rebar --force"
             else ''
             export MIX_REBAR="${rebar}/bin/rebar"
             export MIX_REBAR3="${rebar3}/bin/rebar3"
             '';

  postUnpack = ''
    export HEX_HOME="$TMPDIR/hex"
    export MIX_HOME="$TMPDIR/mix"
    export REBAR_GLOBAL_CONFIG_DIR="$TMPDIR/rebar3"
    export REBAR_CACHE_DIR="$TMPDIR/rebar3.cache"
    export MIX_DEPS_PATH="$TMPDIR/deps"

    export NODE_PATH="$TMPDIR/deps"
    export MIX_XGD=1
    export XDG_CACHE_HOME="$TMPDIR"
    export MIX_ESBUILD_PATH=${esbuild}/bin/esbuild

    $setRebar

    cp --no-preserve=mode -R "${mixDeps}" "$MIX_DEPS_PATH"
  '' + (args.postUnpack or "");

  configurePhase = args.configurePhase or ''
    runHook preConfigure

    # TODO: figure out how to use impureEnvVars here
    source ${../secret/build}

    mix deps.compile --no-deps-check --skip-umbrella-children

    mix assets.deploy

    runHook postConfigure
  '';

  buildPhase = args.buildPhase or ''
    runHook preBuild

    mix do compile --no-deps-check, release --path "$out"

    runHook postBuild
  '';

  installPhase = args.installPhase or ''
    runHook preInstall
    runHook postInstall
  '';

  checkPhase = args.checkPhase or ''
    runHook preCheck
    echo "Running mix test ''${checkFlags} ''${checkFlagsArray+''${checkFlagsArray[@]}}"
    mix test ''${checkFlags} ''${checkFlagsArray+"''${checkFlagsArray[@]}"}
    runHook postCheck
  '';
})
