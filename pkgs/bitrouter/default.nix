# common/ai/bitrouter/package.nix
# BitRouter derivation — prebuilt release binary from GitHub.
#
# Pinned to v1.0.0-alpha.27 (x86_64-linux). The release tarball is a
# dynamically-linked glibc binary, so autoPatchelfHook re-points the
# interpreter/libs at the Nix store.

{ lib, stdenv, fetchurl, autoPatchelfHook, libgcc }:

stdenv.mkDerivation rec {
  pname = "bitrouter";
  version = "1.0.0-alpha.27";

  src = fetchurl {
    url = "https://github.com/bitrouter/bitrouter/releases/download/v${version}/bitrouter-x86_64-unknown-linux-gnu.tar.xz";
    sha256 = "40828c9c9a45d068d3305cfb4f2f1a2e84e968ebcfdcb27e3121363543105c9f";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ libgcc ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    # unpackPhase already extracted the tarball into the build dir
    find . -name bitrouter -type f -exec install -m755 {} $out/bin/bitrouter \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "Self-improving LLM router for agentic workflows (OpenAI/Anthropic/Gemini-compatible)";
    homepage = "https://github.com/bitrouter/bitrouter";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bitrouter";
  };
}
