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

####################################################################################################

_default_:
	@echo "USAGE: make <choice>"
	@echo "	setup_dvm	Install DVM and the $(DC)-$(DV) compiler."
	@echo "	clean		Cleanup files created by past builds."
	@echo "	tests		Build test programs."
	@echo "	docs		Build documentation."
	@echo "	libs		Build interface modules and static libraries."

####################################################################################################

setup_dvm:
ifeq ("$(DVM)","")
@echo " ** Fetching DVM $(LBITS)-bit installer."
ifeq $(LBITS), 64
@wget -O dvm https://bitbucket.org/doob/dvm/downloads/dvm-0.4.0-linux-64
else
@wget -O dvm https://bitbucket.org/doob/dvm/downloads/dvm-0.4.0-linux-32
endif
@echo " ** Installing DVM for current user."
@chmod +x dvm
@./dvm install dvm
@rm dvm
endif
ifeq ("$(shell dvm list | grep "$(DC)-$(DV)")","")
@echo " ** Fetching and installing compiler."
@dvm --$(LBITS)bit --force install $(DV)
endif

####################################################################################################

libs: setup_dvm $(LIBS)

$(LIBS):
	@dvm use $(DV)
	@mkdir -p $@
	$(DC) $(DOPTS) $($(@)_OPTS) -H -Hd$@ -lib -od$@ $(MODULES)
	
####################################################################################################

tests: setup_dvm $(TESTS)

$(TESTS):
	@dvm use $(DV)
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
	@dvm use $(DV)
	$(DC) $(DOPTS) -c -D -Dd$(DOC_DIR) -o- -X -Xf$(DOC_DIR)/ddox.json $(MODULES)
	@-rm -f dzmq
