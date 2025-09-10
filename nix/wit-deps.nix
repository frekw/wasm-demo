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
    pname = "wit-deps";
    version = "0.5.0";

    src = fetchFromGitHub {
      owner = "bytecodealliance";
      repo = "wit-deps";
      rev = "v${version}";
      hash = "sha256-tbHAvdDN2qkJRRfy9L3apBULRVttb7Jh00bDlb1OKJ4=";
    };

    cargoHash = "sha256-54TK9ZeRZ7PPA/8DQ6sH60LLIdgSG+hV+HI0zg1IxJI=";

    # Some tests fail because they need network access to install the `wasm32-unknown-unknown` target.
    # However, GitHub Actions ensures a proper build.
    # See also:
    #   https://github.com/bytecodealliance/wit-deps/actions
    #   https://github.com/bytecodealliance/wit-deps/blob/main/.github/workflows/main.yml
    doCheck = false;

    meta = with lib; {
      description = "Language binding generator for WebAssembly interface types";
      homepage = "https://github.com/bytecodealliance/wit-deps";
      license = licenses.asl20;
      maintainers = with maintainers; [ xrelkd ];
      mainProgram = "wit-deps";
    };
  }
