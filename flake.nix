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
            # WebKitGTK needs these at runtime; DMABUF renderer breaks on some GPUs
            export WEBKIT_DISABLE_DMABUF_RENDERER=1
            export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
          '';
        };
      });
}
