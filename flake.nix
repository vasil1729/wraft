{
  description: "Wraft development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # Allow unfree packages if needed (e.g. for some fonts or specific tools)
        };

        # Define dependencies based on the project requirements
        libraries = with pkgs; [
          # System deps
          inotify-tools
          gnumake
          gcc
          zlib
          openssl
          git
          curl

          # Runtime deps
          imagemagick
          wkhtmltopdf
          xorg.xvfb # For headless wkhtmltopdf wrapper if needed
        ];

        packages = with pkgs; [
          # Elixir & Erlang
          beam.packages.erlang_27.elixir_1_18

          # Database & Storage
          postgresql_14
          minio
          minio-client
          typesense

          # Document Processing
          pandoc
          typst

          # Java for PDF signing
          jdk17

          # Rust for native deps
          cargo
          rustc
          rust-analyzer
          rustfmt

          # LaTeX
          texlive.combined.scheme-full
        ] ++ libraries;

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = packages;

          # Set environment variables
          shellHook = ''
            echo "🚀 Welcome to the Wraft development environment!"
            echo "------------------------------------------------"
            echo "Packages installed:"
            echo "  Elixir: $(elixir --version | tail -n 1)"
            echo "  Erlang: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell)"
            echo "  Postgres: $(postgres --version)"
            echo "  MinIO: $(minio --version | head -n 1)"
            echo "  Typst: $(typst --version)"
            echo "  Pandoc: $(pandoc --version | head -n 1)"
            echo "------------------------------------------------"

            # Setup local data directories if they don't exist
            mkdir -p .nix-data/postgres
            mkdir -p .nix-data/minio
            mkdir -p .nix-data/typesense

            export PGDATA=$PWD/.nix-data/postgres
            export MINIO_DATA_DIR=$PWD/.nix-data/minio

            # Add local mix bin to path
            export PATH=$PWD/_build/dev/lib/wraft/bin:$HOME/.mix/escripts:$PATH
            export ERL_AFLAGS="-kernel shell_history enabled"

            # Hint for database init
            if [ ! -d "$PGDATA" ]; then
              echo "Initializing PostgreSQL data directory..."
              initdb -D $PGDATA --no-locale --encoding=UTF8
            fi

            echo "To start services locally, you can use:"
            echo "  postgres -D .nix-data/postgres"
            echo "  minio server .nix-data/minio"
            echo "  typesense-server --data-dir .nix-data/typesense --api-key=xyz"
          '';

          # Fix for library paths if needed for native extensions
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libraries;
        };
      }
    );
}
