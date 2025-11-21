{
  description = "Development environment for dotfiles";

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
        packages.default = pkgs.writeShellScriptBin "dotfiles" ''
          echo "Dotfiles management environment (Chezmoi-based)"
        '';

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust-based CLI tools
            starship          # Shell prompt
            git-delta         # Improved git diff viewer
            lsd               # Modern ls replacement
            mcfly             # Terminal history search
            sd                # sed replacement
            jnv               # jq enhancement
            hyperfine         # Benchmarking tool

            # Python ecosystem
            uv                # Fast Python package installer

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
          ];
        };
      }
    );
}
