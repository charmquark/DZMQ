DC := dmd
DV := 2.060

DOPTS := -Isrc -ofdzmq -op -property -w
MODULES := $(wildcard src/**/*.d)

LBITS := $(shell getconf LONG_BIT)
DVM := $(shell which dvm 2>/dev/null)

LIBS := debug release
debug_OPTS := -debug -g
release_OPTS := -inline -O -release

TEST_DIR := tests
TEST_BIN := $(TEST_DIR)/bin
TESTS := $(basename $(notdir $(wildcard $(TEST_DIR)/*.d)))

DOC_DIR := doc
DOC_OPTS := -c -D -Dd$(DOC_DIR) -o- -X -Xf$(DOC_DIR)/ddox.json

####################################################################################################

all: setup_dvm libs tests

####################################################################################################

setup_dvm: install_dvm install_compiler select_compiler

install_dvm:
ifeq ("$(DVM)","")
	ifeq $(LBITS), 64
		wget -O dvm https://bitbucket.org/doob/dvm/downloads/dvm-0.4.0-linux-64
	else
		wget -O dvm https://bitbucket.org/doob/dvm/downloads/dvm-0.4.0-linux-32
	endif
	chmod +x dvm
	./dvm install dvm
	rm dvm
endif

install_compiler:
ifeq ("$(shell dvm list | grep "$(DC)-$(DV)")","")
	dvm --$(LBITS)bit --force install $(DV)
endif

select_compiler:
	dvm use 2.060

####################################################################################################

libs: $(LIBS)

$(LIBS):
	mkdir -p $@
	$(DC) $(DOPTS) $($(@)_OPTS) -H -Hd$@ -lib -od$@ $(MODULES)
	
####################################################################################################

tests: $(TESTS)

$(TESTS):
	$(DC) $(DOPTS) $(debug_OPTS) $(MODULES) -of$(TEST_BIN)/$@ $(TEST_DIR)/$@.d

####################################################################################################

clean:
	rm -fr debug
	rm -fr release
	rm -fr $(DOC_DIR)
	rm -fr $(TEST_BIN)

####################################################################################################

distclean: clean

check: tests

####################################################################################################

docs: setup_dvm
	$(DC) $(DOPTS) $(DOC_OPTS) $(MODULES)
