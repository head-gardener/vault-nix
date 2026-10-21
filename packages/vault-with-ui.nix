{
  lib,
  stdenv,
  buildGo127Module,
  fetchFromGitHub,
  installShellFiles,
  makeWrapper,
  gawk,
  glibc,
  callPackage,
}:
let
  version = "2.2.0";

  # https://github.com/hashicorp/vault/issues/32164
  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "vault";
    rev = "481a15d9cd9fee25dbc61f82cbbd1db315591e86";
    hash = "sha256-DBX1OJmxDOpd5sxOwqiU4L2aBIJ28EctPiYjEB+aJ2M=";
  };

  vault-ui = callPackage ./vault-ui.nix {
    inherit src version;
  };
in
buildGo127Module (finalAttrs: {
  pname = "vault-with-ui";
  inherit version;
  inherit src;

  vendorHash = "sha256-/ZlreILqoWPOOCObWIQD4Zc5RYJUL6NdZYXe3FmxL8A=";
  proxyVendor = true;
  subPackages = [ "." ];

  tags = [
    "vault"
    "ui"
  ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  passthru.vault-ui = vault-ui;

  postPatch = ''
    mkdir -p http/web_ui
    cp -r ${vault-ui}/. http/web_ui/
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/hashicorp/vault/sdk/version.GitCommit=${finalAttrs.src.rev}"
    "-X github.com/hashicorp/vault/sdk/version.Version=${finalAttrs.version}"
    "-X github.com/hashicorp/vault/sdk/version.VersionPrerelease="
  ];

  postInstall = ''
    echo "complete -C $out/bin/vault vault" > vault.bash
    installShellCompletion vault.bash
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/bin/vault \
      --prefix PATH ${
        lib.makeBinPath [
          gawk
          glibc
        ]
      }
  '';

  meta = {
    homepage = "https://developer.hashicorp.com/vault";
    description = "Tool for managing secrets, with the web UI built in";
    changelog = "https://github.com/hashicorp/vault/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.bsl11;
    mainProgram = "vault";
    platforms = lib.platforms.unix;
  };
})
