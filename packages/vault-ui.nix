{
  lib,
  stdenvNoCC,
  nodejs_24,
  pnpm_10_latest,
  fetchPnpmDeps,
  pnpmConfigHook,
  src, # Vault source tree (from fetchFromGitHub)
  version,
}:
let
  pname = "vault-ui";
  uiSrc = "${src}/ui";
  pnpmDeps = fetchPnpmDeps {
    inherit pname version;
    src = uiSrc;
    pnpm = pnpm_10_latest;
    fetcherVersion = 4;
    hash = "sha256-Ay9FYofcE6gPF951OhkSaihLGWnKfHS+CfozxZbjETw=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version;
  src = uiSrc;

  nativeBuildInputs = [
    nodejs_24
    pnpm_10_latest
    pnpmConfigHook
  ];

  inherit pnpmDeps;

  passthru.pnpmDeps = pnpmDeps;

  # `pnpm run build` = `pnpm build:jsondiffpatch && ember build --environment=production`
  buildPhase = ''
    runHook preBuild

    # @hashicorp/vault-client-typescript is a git (tarball) dependency that
    # builds its dist/ via its `prepare` script, which pnpmConfigHook skips
    # (--ignore-scripts). It ships TypeScript sources only and has no runtime
    # deps, so the root project's typescript (a devDependency) can compile it.
    # NB: don't prepend node_modules/.bin to PATH -- it contains a broken
    # `node` shim that shadows the real nodejs. Run tsc.js via node directly;
    # tsconfig outDir is relative to the tsconfig, so -p keeps output in the
    # package dir.
    node node_modules/typescript/lib/tsc.js -p node_modules/@hashicorp/vault-client-typescript/tsconfig.json
    node node_modules/typescript/lib/tsc.js -p node_modules/@hashicorp/vault-client-typescript/tsconfig.esm.json

    pnpm run build
    runHook postBuild
  '';

  # .ember-cli sets "output-path": "../http/web_ui"
  installPhase = ''
    runHook preInstall
    mkdir $out
    cp -r ../http/web_ui/. $out/
    runHook postInstall
  '';

  meta = {
    description = "Web UI for HashiCorp Vault";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.all;
  };
})
