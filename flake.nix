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
            aria2             # Download utility
            miller            # Data processing tool
            htop              # Process monitor

            # TUI tools
            oxker             # Docker container TUI manager
            ov                # Feature-rich terminal pager
            glow              # Terminal Markdown renderer

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
          ];
        };
      }
    );
}
