{
  description = "termic dev shell (Tauri 2 + React/Vite + Rust)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Linux-only native deps for Tauri 2 (WebKitGTK backend)
        linuxDeps = with pkgs; [
          webkitgtk_4_1
          gtk3
          libsoup_3
          glib
          cairo
          pango
          gdk-pixbuf
          librsvg
          libayatana-appindicator
          openssl
          dbus
          xdotool
        ];

        darwinDeps = with pkgs; lib.optionals stdenv.isDarwin [
          libiconv
        ];
      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "termic";
          version = "0.24.0";
          src = self;

          cargoRoot = "src-tauri";
          buildAndTestSubdir = "src-tauri";
          cargoLock.lockFile = ./src-tauri/Cargo.lock;

          npmDeps = pkgs.fetchNpmDeps {
            name = "${pname}-${version}-npm-deps";
            src = self;
            hash = "sha256-yRPzIVWG9qmPzaMs7/l8yzIFgHd9O2KmPqSyJZimMLg=";
          };

          # No updater artifacts in the Nix build: they must be signed with the
          # maintainer's TAURI_SIGNING_PRIVATE_KEY, and Nix-installed copies
          # update through Nix anyway.
          tauriBuildFlags = [ "--config" ''{"bundle":{"createUpdaterArtifacts":false}}'' ];

          nativeBuildInputs = with pkgs; [
            cargo-tauri.hook
            nodejs_22
            npmHooks.npmConfigHook
            pkg-config
            wrapGAppsHook3
          ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux linuxDeps ++ darwinDeps;

          # Unit tests shell out to a real git with identity/network assumptions;
          # they run via `cargo test` in the dev shell, not inside the sandbox.
          doCheck = false;

          meta = {
            description = "One window, many parallel coding agents, each in its own git-worktree task";
            mainProgram = "termic";
          };
        };
        packages.termic = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22
            rustc
            cargo
            rust-analyzer
            clippy
            rustfmt
            pkg-config
            cargo-tauri
            gnumake
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux linuxDeps
            ++ darwinDeps;

          shellHook = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # NOTE: do NOT set WEBKIT_DISABLE_DMABUF_RENDERER=1 here.
            # It forces software rendering; xterm.js WebGL then lags ~500ms per keystroke.
            export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
          '';
        };
      });
}
