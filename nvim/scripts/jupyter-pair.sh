#!/bin/bash
# Auto-pair Jupyter notebooks with .py files
# Usage: ./jupyter-pair.sh [file.ipynb or directory]

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <file.ipynb or directory>"
    echo "Example: $0 notebook.ipynb"
    echo "Example: $0 ~/Documents/Notebooks/"
    exit 1
fi

if [ -f "$1" ]; then
    # Single file
    if [[ "$1" == *.ipynb ]]; then
        echo "Pairing: $1"
        jupytext --set-formats ipynb,py:percent "$1"
        echo "✓ Created pair: ${1%.ipynb}.py"
    else
        echo "Error: File must be .ipynb"
        exit 1
    fi
elif [ -d "$1" ]; then
    # Directory - pair all .ipynb files
    count=0
    for notebook in "$1"/*.ipynb; do
        if [ -f "$notebook" ]; then
            echo "Pairing: $notebook"
            jupytext --set-formats ipynb,py:percent "$notebook"
            ((count++))
        fi
    done
    echo "✓ Paired $count notebooks"
else
    echo "Error: $1 is not a file or directory"
    exit 1
fi
