BATS      ?= bats
TEST_DIR  := test
BATS_OPTS ?=

# All .bats files under test/
TESTS := $(wildcard $(TEST_DIR)/*.bats)

.PHONY: test test-verbose test-tap test-coverage check-bats

test: check-bats
	$(BATS) $(BATS_OPTS) $(TESTS)

test-verbose: check-bats
	$(BATS) --verbose-run $(BATS_OPTS) $(TESTS)

test-tap: check-bats
	$(BATS) --formatter tap $(BATS_OPTS) $(TESTS)

# Run a single file: make test-file FILE=test/serving.bats
test-file: check-bats
	$(BATS) $(BATS_OPTS) $(FILE)

# Report how many execs/ scripts have at least one matching .bats file.
# Mapping: execs/barista-brew → test/brew.bats, execs/barista → test/barista.bats
test-coverage:
	@total=0; covered=0; \
	for f in execs/barista execs/barista-*; do \
	  base=$$(basename "$$f"); \
	  name=$${base#barista}; name=$${name#-}; \
	  [ -z "$$name" ] && name="barista"; \
	  total=$$((total + 1)); \
	  if [ -f "$(TEST_DIR)/$$name.bats" ]; then \
	    covered=$$((covered + 1)); \
	  else \
	    printf '  uncovered: %s  (%s)\n' "$$name" "$$f"; \
	  fi; \
	done; \
	echo "Coverage: $$covered/$$total execs have a .bats file"

check-bats:
	@command -v $(BATS) >/dev/null 2>&1 || { \
		echo "bats not found. Install it with:"; \
		echo "  brew install bats-core          # macOS"; \
		echo "  apt-get install bats            # Debian/Ubuntu"; \
		echo "  https://github.com/bats-core/bats-core"; \
		exit 1; \
	}
