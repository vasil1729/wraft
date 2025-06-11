#!/bin/bash

# Build and test script for PDF signature placement functionality

echo "=== Building PDF Analyzer with Signature Placement ==="

# Navigate to the native directory
cd native/pdf_analyzer

echo "Building Rust NIF..."
cargo build --release

if [ $? -eq 0 ]; then
    echo "✓ Rust NIF built successfully"
else
    echo "✗ Failed to build Rust NIF"
    exit 1
fi

# Go back to project root
cd ../..

echo ""
echo "=== Compiling Elixir Project ==="

# Compile the Elixir project
mix deps.get
mix compile

if [ $? -eq 0 ]; then
    echo "✓ Elixir project compiled successfully"
else
    echo "✗ Failed to compile Elixir project"
    exit 1
fi

echo ""
echo "=== Running Tests ==="

# Create test directories
mkdir -p test_files

# Run the test script
elixir test_signature_placement.exs

echo ""
echo "=== Build and Test Complete ==="
