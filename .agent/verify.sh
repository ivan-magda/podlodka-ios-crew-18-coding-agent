#!/bin/bash
set -e

swift build
git diff --check HEAD
