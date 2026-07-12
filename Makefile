.PHONY: test clean install-deps help

# Default target
help:
	@echo "Available targets:"
	@echo "  test            - Run all tests (or specific tests with PATTERN=...)"
	@echo "  clean           - Clean test cache files and downloaded dependencies"
	@echo "  install-deps    - Download all test dependencies (luaunit)"
	@echo ""
	@echo "Examples:"
	@echo "  make test                                     # Run all tests"
	@echo "  make test PATTERN=example                     # Match test/**/*example*_spec.lua"
	@echo "  make test PATTERN=test/example_spec.lua       # Full path"

# Install all test dependencies (cross-platform, uses Lua)
install-deps:
	@echo "Installing test dependencies..."
	@nvim --headless -u test/minimal_init.lua -c "lua dofile('test/install_deps.lua')" -c "qa!"

# Run tests with nvim headless
# Supports PATTERN parameter to run specific test file(s)
# Examples:
#   make test PATTERN=test/example_spec.lua
#   make test PATTERN=example  (shorthand for test/**/*example*_spec.lua)
test: install-deps
	@echo "Running tests with nvim --headless..."
	@nvim --headless -u test/minimal_init.lua \
		-c "lua _G.TEST_PATTERN = '$(PATTERN)'" \
		-c "lua dofile('test/run.lua')" \
		-c "qa!"

# Clean generated files and downloaded dependencies
clean:
	@echo "Cleaning up..."
	@rm -rf test/.deps
	@rm -rf test/*.out
	@rm -rf *.swp
	@rm -rf /tmp/tasks_nvim_test_* 2>/dev/null || true

