{
  description = "WASM + WASI Demo";
  inputs = {
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          (final: prev: {
            wit-deps = final.callPackage ./nix/wit-deps.nix {
              inherit system;
              fenix = inputs.fenix;
            };
            wac = final.callPackage ./nix/wac.nix {
              inherit system;
              fenix = inputs.fenix;
            };
          })
          (prev: _: { fenix = import inputs.fenix { system = prev.system; }; })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustBuildTarget = "wasm32-wasip2";
        rustToolchain =
          with inputs.fenix.packages.${system};
          combine [
            stable.rustc
            stable.cargo
            targets.wasm32-wasip1.stable.rust-std
            targets.wasm32-wasip2.stable.rust-std
          ];
        wit = pkgs.stdenv.mkDerivation {
          pname = "wit";
          version = "0.1";
          src = ./wit;
          installPhase = ''
            mkdir -p $out
            cp -r ./* $out/
          '';
        };
      in
      rec {
        packages.rust-handler =
          (pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          }).buildRustPackage
            {
              name = "rust-handler";
              src = ./rust-handler;
              cargoLock.lockFile = ./rust-handler/Cargo.lock;

              buildInputs = [
                wit
              ];

              buildPhase = ''
                cp ${wit}/greeter.wit ./wit/greeter.wit
                cp ${wit}/handler.wit ./wit/handler.wit

                cargo build --release --target ${rustBuildTarget}
              '';

              installPhase = ''
                mkdir -p $out/lib
                cp target/${rustBuildTarget}/release/*.wasm $out/lib/
              '';
            };

        packages.rust-hello =
          (pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          }).buildRustPackage
            {
              name = "rust-hello";
              src = ./rust-hello;
              cargoLock.lockFile = ./rust-hello/Cargo.lock;

              buildInputs = [ wit ];

              buildPhase = ''
                cp ${wit}/greeter.wit ./wit/greeter.wit

                cargo build --release --target ${rustBuildTarget}
              '';

              installPhase = ''
                mkdir -p $out/lib
                cp target/${rustBuildTarget}/release/*.wasm $out/lib/
              '';
            };

        packages.go-hello = pkgs.stdenv.mkDerivation {
          name = "go-hello";
          version = "0.1";

          src = ./go-hello;

          buildInputs = [
            wit
          ];

          nativeBuildInputs = [
            pkgs.go
            pkgs.tinygo
            pkgs.wasm-tools
            pkgs.wkg
          ];

          buildPhase = ''
            cp ${wit}/greeter.wit wit/
            cp ${wit}/greeter-go.wit wit/


            export HOME=$PWD  # workaround for Go wanting a writable HOME
            export GOMODCACHE=$TMPDIR/go-mod
            export GOCACHE=$TMPDIR/go-cache
            mkdir -p $GOMODCACHE $GOCACHE

            wkg wit build
            go generate

            tinygo build \
              -target=wasip2 \
              -o hello.wasm \
              --wit-package component:hello.wasm \
              --wit-world greeter-go main.go
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp hello.wasm $out/lib/
          '';
        };

        packages.linked = pkgs.stdenv.mkDerivation {
          name = "linked";

          phases = [
            "buildPhase"
            "installPhase"
          ];

          buildInputs = [
            packages.go-hello
            packages.rust-handler
            packages.rust-hello
          ];

          nativeBuildInputs = [
            pkgs.wac
          ];

          buildPhase = ''
            wac plug ${packages.rust-handler}/lib/rust_handler.wasm \
              --plug ${packages.go-hello}/lib/hello.wasm \
              -o linked.wasm
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp linked.wasm $out/lib/
          '';
        };

        packages.default = pkgs.writeShellScriptBin "run" ''
          ${pkgs.wasmtime}/bin/wasmtime serve --wasi cli=y,http=y ${packages.linked}/lib/linked.wasm
        '';

        devShells.default = pkgs.mkShell {
          inputsFrom = [
            self.packages."${system}".go-hello
            self.packages."${system}".rust-handler
            self.packages."${system}".rust-hello
          ];

          packages = with pkgs; [
            rust-analyzer
            wac
            wasm-pack
            wasm-tools
            wasmtime.out
            wit-bindgen
            wit-deps
          ];

        };
      }
    );
}
