.PHONY: help lint lint-fix format clean build test

help:
	@echo "Available commands:"
	@echo "  make lint       - Run SwiftLint to check code style"
	@echo "  make lint-fix   - Run SwiftLint and automatically fix issues"
	@echo "  make format     - Format Swift code using SwiftLint"
	@echo "  make build      - Build the Xcode project"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make test       - Run unit tests"

lint:
	@echo "Running SwiftLint..."
	@swiftlint lint --config .swiftlint.yml

lint-fix:
	@echo "Running SwiftLint with autocorrect..."
	@swiftlint lint --config .swiftlint.yml --fix

format:
	@echo "Formatting Swift code..."
	@swiftlint lint --config .swiftlint.yml --fix --format

build:
	@echo "Building OscDrax..."
	@xcodebuild -project OscDrax.xcodeproj \
		-scheme OscDrax \
		-configuration Debug \
		-destination 'platform=macOS' \
		build

clean:
	@echo "Cleaning build artifacts..."
	@xcodebuild -project OscDrax.xcodeproj \
		-scheme OscDrax \
		clean
	@rm -rf build/
	@rm -rf DerivedData/

test:
	@echo "Running tests..."
	@xcodebuild -project OscDrax.xcodeproj \
		-scheme OscDrax \
		-destination 'platform=macOS' \
		test