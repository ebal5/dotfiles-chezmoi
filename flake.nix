{
  description = "User-wide CLI tools managed by Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rtkManifest = builtins.fromJSON (builtins.readFile ./rtk/manifest.json);
        rtkPlatform = rtkManifest.platforms.${system} or null;
        rtk =
          if rtkPlatform == null then null
          else pkgs.stdenvNoCC.mkDerivation {
            pname = "rtk";
            version = rtkManifest.version;
            src = pkgs.fetchurl {
              url = "${rtkManifest.repository}/releases/download/${rtkManifest.tag}/rtk-${rtkPlatform.target}.tar.gz";
              sha256 = rtkPlatform.sha256;
            };
            sourceRoot = ".";
            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
            installPhase = ''
              runHook preInstall
              install -Dm755 rtk $out/bin/rtk
              runHook postInstall
            '';
            meta = with pkgs.lib; {
              description = "Rust Token Killer - reduce LLM token consumption via command rewriting";
              homepage = rtkManifest.repository;
              license = licenses.asl20;
              platforms = builtins.attrNames rtkManifest.platforms;
              mainProgram = "rtk";
            };
          };
      in
      {
        # Main package output for user-wide installation
        packages.default = pkgs.buildEnv {
          name = "user-cli-tools";
          paths = with pkgs; [
            # Rust-based CLI tools
            starship          # Shell prompt
            delta             # Improved git diff viewer
            lsd               # Modern ls replacement
            mcfly             # Terminal history search
            sd                # sed replacement
            hyperfine         # Benchmarking tool
            xh                # HTTP client (httpie replacement)
            watchexec         # File-watch command executor

            # Python ecosystem
            uv                # Fast Python package installer

            # JavaScript/TypeScript ecosystem
            bun               # Fast JS/TS runtime and package manager
            pnpm              # Fast, disk space efficient package manager

            # Build tools
            zig               # Zig build environment

            # Directory navigation
            zoxide            # Smart cd replacement

            # Additional utilities
            fzf               # Fuzzy finder
            ripgrep           # Fast grep
            fd                # Fast find
            bat               # Syntax-highlighted cat
            hexyl             # Hex viewer
            curl              # Data transfer
            jq                # JSON processor
            python3Packages.yq # YAML/XML/TOML processor (jq wrapper)
            dasel             # Multi-format data query/update (JSON/YAML/TOML/XML/CSV)
            aria2             # Download utility
            miller            # Data processing tool
            htop              # Process monitor
            scc               # Fast code counter (Sloc Cloc and Code)

            # TUI tools
            oxker             # Docker container TUI manager
            ov                # Feature-rich terminal pager
            glow              # Terminal Markdown renderer
            zellij            # Terminal workspace / multiplexer

            # Editors
            neovim            # Hyperextensible Vim-based editor

            # Task management
            pueue             # CLI task queue manager

            # Version control & dotfiles
            git               # Version control (latest from nixos-unstable)
            gh                # GitHub CLI
            chezmoi           # Dotfiles manager
            bitwarden-cli     # Bitwarden CLI client
            prek              # Fast pre-commit replacement (Rust)

            # Linters
            actionlint        # GitHub Actions workflow linter
          ] ++ pkgs.lib.optional (rtk != null) rtk;
        };
      }
    );
}
