{
  lib,
  makeRustPlatform,
  fetchFromGitHub,
  fenix,
  system,
  ...
}:
let
  toolchain = fenix.packages."${system}".stable.toolchain;
in
(makeRustPlatform {
  cargo = toolchain;
  rustc = toolchain;
}).buildRustPackage
  rec {
    pname = "wac";
    version = "0.8.0";

    src = fetchFromGitHub {
      owner = "bytecodealliance";
      repo = "wac";
      rev = "v${version}";
      hash = "sha256-PjJL5+slMZ+sQhDDhUQdbeVP3N9scTJjktLhSmK88qw=";
    };

    cargoHash = "sha256-91kOyH26Ydq2QJRdDiXZrIT37DsmVM1fXV2Txk6SQZc=";

    # Some tests fail because they need network access to install the `wasm32-unknown-unknown` target.
    # However, GitHub Actions ensures a proper build.
    # See also:
    #   https://github.com/bytecodealliance/wit-deps/actions
    #   https://github.com/bytecodealliance/wit-deps/blob/main/.github/workflows/main.yml
    doCheck = false;

    meta = with lib; {
      description = "WebAssembly Composition (WAC) tooling";
      homepage = "https://github.com/bytecodealliance/wit-deps";
      license = licenses.asl20;
      maintainers = with maintainers; [ xrelkd ];
      mainProgram = "wac";
    };
  }
