#!/bin/sh
# Experiment 3b: rebuild and re-run everything from scratch. Written by the lead; the builder may not change it.
cd "$(dirname "$0")" && exec python3 acceptance/measure.py "$@"
