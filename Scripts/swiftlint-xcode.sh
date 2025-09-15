#!/bin/bash

# SwiftLint Build Phase Script for Xcode
# Add this script as a Run Script Build Phase in Xcode

# Check if SwiftLint is installed
if which swiftlint >/dev/null; then
    # Run SwiftLint
    swiftlint lint --config "${SRCROOT}/.swiftlint.yml"
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    exit 0
fi