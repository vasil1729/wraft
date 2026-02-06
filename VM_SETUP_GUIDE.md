# VM Setup and Configuration Guide for Wraft

This guide details the necessary configuration and steps to provision a Virtual Machine (VM) for running the Wraft server.

## 1. System Requirements

*   **Operating System**: Linux (Ubuntu 22.04/24.04 LTS recommended) or macOS.
*   **Hardware Resources**:
    *   **RAM**: Minimum 4GB (8GB recommended) - Elixir, Postgres, MinIO, and Typesense can be memory intensive.
    *   **CPU**: 2+ Cores recommended.
    *   **Storage**: 20GB+ (dependent on document storage needs).

## 2. Software Dependencies

To run Wraft natively (without Docker for the application code), you must install the following specific versions:

*   **Elixir**: 1.18.4
*   **Erlang/OTP**: 27.0.1
*   **PostgreSQL**: 14+
*   **MinIO**: Latest Stable (S3 compatible object storage)
*   **Typesense**: v27.1 (Search Engine)
*   **Pandoc**: 3.6.3
*   **Typst**: 0.13.0
*   **Java**: JDK 17 (Required for PDF signing)
*   **Rust**: Stable toolchain (Required for native Elixir dependencies)
*   **LaTeX**: TeX Live (Full distribution recommended for broad compatibility)
*   **ImageMagick**: Latest Stable
*   **System Tools**: `inotify-tools`, `git`, `build-essential`, `curl`, `wkhtmltopdf` (headless)

## 3. Provisioning the VM

The repository includes a `Makefile` that can automate the installation of dependencies for Ubuntu, macOS, and Windows.

### Step 3.1: Clone the Repository

```bash
git clone https://github.com/wraft/wraft.git
cd wraft
```

### Step 3.2: Install Dependencies

**Option A: Using the Makefile (Recommended for Ubuntu)**

This command installs system packages (Postgres, MinIO, LaTeX, etc.), Rust, asdf (version manager), and the required Erlang/Elixir versions.

```bash
make install-deps-ubuntu
```

*Note: You may need to logout and login again for group changes and path updates (like `asdf` and `cargo`) to take effect.*

**Option B: Manual Installation**

If you prefer to install manually, refer to the `Dockerfile.dev` and `Makefile` for the exact commands used. Key manual steps often include:

1.  **Install System Packages**:
    ```bash
    sudo apt-get update
    sudo apt-get install -y postgresql inotify-tools pandoc texlive-full imagemagick openjdk-17-jdk curl build-essential git
    ```

2.  **Install MinIO**:
    Follow instructions at [MinIO Linux Download](https://min.io/download#/linux).

3.  **Install Typesense**:
    ```bash
    mkdir -p ~/typesense-data
    # Download and install binary or run via Docker
    ```

4.  **Install Rust**:
    ```bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```

5.  **Install Typst**:
    ```bash
    cargo install typst-cli --version 0.13.0
    ```

6.  **Install Elixir & Erlang**:
    Use `asdf` (recommended) or your package manager to install Erlang 27.0.1 and Elixir 1.18.4.

**Option C: Nix Flake (Reproducible Environment)**

If you have [Nix](https://nixos.org/download.html) installed with flakes enabled, you can enter a shell with all dependencies pre-installed:

```bash
nix develop
```

Or if you use `direnv`:

```bash
direnv allow
```

### Step 3.3: Verify Installation

Run the following command to check if all versions match the requirements:

```bash
make check-versions
```

## 4. Configuration

### Step 4.1: Environment Variables

1.  Copy the example environment file:
    ```bash
    cp .env.example .env.dev
    ```

2.  Edit `.env.dev` to match your environment. Key variables to configure:

    *   **Database**:
        ```bash
        export DATABASE_URL=postgres://<user>:<pass>@localhost:5432/wraft_dev
        ```
    *   **MinIO (S3)**:
        ```bash
        export MINIO_URL=http://localhost:9000
        export MINIO_ACCESS_KEY=<your_minio_user>
        export MINIO_SECRET_KEY=<your_minio_password>
        export MINIO_BUCKET=wraft
        ```
    *   **Typesense**:
        ```bash
        export TYPESENSE_API_KEY=<your_api_key>
        export TYPESENSE_HOST=localhost
        export TYPESENSE_PORT=8108
        ```
    *   **Secrets** (Generate these as per comments in the file):
        *   `SECRET_KEY_BASE`
        *   `GUARDIAN_KEY`
        *   `CLOAK_KEY`

### Step 4.2: Load Configuration

Before running any application commands, source the environment file:

```bash
source .env.dev
```

## 5. Starting the Server

### Step 5.1: Infrastructure Services

Ensure PostgreSQL, MinIO, and Typesense are running.

*   **Postgres**: `sudo service postgresql start`
*   **MinIO**: `minio server ~/minio_data --console-address :9001`
*   **Typesense**: `typesense-server --data-dir=~/typesense-data --api-key=$TYPESENSE_API_KEY`

### Step 5.2: Application Setup

Initialize the application (fetches deps, compiles, sets up DB):

```bash
make setup
```
(Or manually: `mix deps.get`, `mix compile`, `mix ecto.setup`)

### Step 5.3: Start Wraft

Start the Phoenix server:

```bash
make run
```
(Or manually: `source .env.dev && mix phx.server`)

The server should now be accessible at `http://localhost:4000`.

## 6. Docker Alternative

If you prefer to run everything in containers on your VM (simplifies dependency management):

1.  Install Docker and Docker Compose.
2.  Configure `.env.dev`.
3.  Run:
    ```bash
    make docker-up
    ```
    This starts Backend, Frontend, DB, MinIO, and Typesense.
