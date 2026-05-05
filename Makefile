BATS      ?= bats
TEST_DIR  := test
BATS_OPTS ?=

# All .bats files under test/
TESTS := $(wildcard $(TEST_DIR)/*.bats)

.PHONY: test test-verbose test-tap check-bats

test: check-bats
	$(BATS) $(BATS_OPTS) $(TESTS)

test-verbose: check-bats
	$(BATS) --verbose-run $(BATS_OPTS) $(TESTS)

test-tap: check-bats
	$(BATS) --formatter tap $(BATS_OPTS) $(TESTS)

# Run a single file: make test-file FILE=test/serving.bats
test-file: check-bats
	$(BATS) $(BATS_OPTS) $(FILE)

check-bats:
	@command -v $(BATS) >/dev/null 2>&1 || { \
		echo "bats not found. Install it with:"; \
		echo "  brew install bats-core          # macOS"; \
		echo "  apt-get install bats            # Debian/Ubuntu"; \
		echo "  https://github.com/bats-core/bats-core"; \
		exit 1; \
	}
