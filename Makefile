# Mandatory
QEMU_PATH := $HOME/src/qemu
QEMU_ARCH := x86_64
QEMU_TAGS := master

# Optional
QEMU_CONF :=
TAG_SUFFIX :=

# Check that the mandatory variables are set
ifeq ($(QEMU_PATH),)
  $(error Missing QEMU_PATH)
endif
ifeq ($(QEMU_ARCH),)
  $(error Missing QEMU_ARCH)
endif
ifeq ($(QEMU_TAGS),)
  $(error Missing QEMU_TAGS)
endif

# Probably no need to change any of the remaining variables.
QEMU_FINAL_TAGS := $(addsuffix $(TAG_SUFFIX),$(QEMU_TAGS))
MKFILE_PATH = $(abspath $(lastword $(MAKEFILE_LIST)))
OUTDIR := $(dir $(MKFILE_PATH))out
ROOT_FILES := $(foreach arch,$(QEMU_ARCH),$(addsuffix -$(arch),$(QEMU_FINAL_TAGS)))
OUT_ROOT_FILES := $(addprefix $(OUTDIR)/,$(ROOT_FILES))
NBENCH_FILES := $(addsuffix .nbench,$(OUT_ROOT_FILES))
PERL_FILES   := $(addsuffix .perl,$(OUT_ROOT_FILES))
OUT_FILES := $(NBENCH_FILES) $(PERL_FILES)

QEMU_BINARIES := $(addprefix $(OUTDIR)/,$(foreach arch,$(QEMU_ARCH),$(addsuffix /bin/qemu-$(arch),$(QEMU_FINAL_TAGS))))

PERL_VERSION := 5.36.0
PERL_DIR := perl-$(PERL_VERSION)
PERL_LN := perldir

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COMMA := ,

# Do not run Perl tests by default because building Perl takes a while.
# Moreover, Perl doesn't support cross-compilation.
all: nbench

nbench: $(foreach ext,png txt,nbench-int.$(ext) nbench-fp.$(ext))
.PHONY: nbench

perl: $(foreach ext,png txt,perl.$(ext))
.PHONY: perl

%.png: %.plt
	gnuplot -e "set term pngcairo" $< > $@.tmp
	mv $@.tmp $@

%.txt: %.plt
	gnuplot -e "set term dumb" $< > $@.tmp
	mv $@.tmp $@

%.svg: %.plt
	gnuplot -e "set terminal svg size 800,600 enhanced fsize 14 butt" $< > $@.tmp
	mv $@.tmp $@

nbench-int.plt: plot.pl nbench.dat
	./$< --xlabel='QEMU version' --suite=int nbench.dat > $@.tmp
	mv $@.tmp $@

nbench-fp.plt: plot.pl nbench.dat
	./$< --xlabel='QEMU version' --suite=fp nbench.dat > $@.tmp
	mv $@.tmp $@

nbench.dat: dat.pl $(NBENCH_FILES)
	./$< $(NBENCH_FILES) > $@.tmp
	mv $@.tmp $@

perl.plt: plot.pl perl.dat
	./$< --xlabel='QEMU version' --suite=perl perl.dat > $@.tmp
	mv $@.tmp $@

perl.dat: dat-perl.pl $(PERL_FILES)
	./$< $(PERL_FILES) > $@.tmp
	mv $@.tmp $@

# This makes sure we generate one file at a time, regardless
# of the -j parameter.
.NOTPARALLEL: $(OUT_FILES) $(QEMU_BINARIES)

BIN_PICK_TAG =  $(shell echo $@ | perl -pe 's|^$(OUTDIR)/([^/]+)$(TAG_SUFFIX).*|$$1|')
BIN_PICK_PFX =  $(shell echo $@ | perl -pe 's|(.*)/bin/qemu-.*|$$1|')
MAKE_TARGET_LIST = $(subst $(SPACE),$(COMMA),$(addsuffix -linux-user,$(QEMU_ARCH)))

qemu_binaries: $(QEMU_BINARIES)
.PHONY: qemu_binaries

$(QEMU_BINARIES):
	mkdir -p $(QEMU_PATH)/build
	cd $(QEMU_PATH)/build && \
	git checkout $(BIN_PICK_TAG) && \
	../configure --target-list=$(MAKE_TARGET_LIST) \
		--prefix=$(BIN_PICK_PFX) $(QEMU_CONF)
	$(MAKE) -C $(QEMU_PATH)/build clean
# This is a .NOTPARALLEL target, so we pass -j 4 hoping the host won't
# run out of memory.
	$(MAKE) -j 4 -C $(QEMU_PATH)/build install

$(OUT_FILES): $(QEMU_BINARIES)
	./qemu.pl $@

# Ignore `make test' failure: it's OK if some of the tests fail
perl-deps:
	wget -nc http://www.cpan.org/src/5.0/$(PERL_DIR).tar.gz
	tar xzf $(PERL_DIR).tar.gz
	cd $(PERL_DIR) && ./Configure -des
	ln -sf $(PERL_DIR) $(PERL_LN)
	$(MAKE) -C $(PERL_DIR)
	-$(MAKE) -C $(PERL_DIR) test
	mv $(PERL_DIR)/miniperl $(PERL_DIR)/miniperl-real
	mv $(PERL_DIR)/perl $(PERL_DIR)/perl-real
.PHONY: perl-deps

clean:
	$(RM) *.tmp
	$(RM) *.dat *.plt
	$(RM) *.png *.txt *.svg

distclean: clean
	$(RM) $(OUTDIR)/*.nbench
	$(RM) $(PERL_DIR).tar.gz
	$(RM) -r $(PERL_DIR)
	$(RM) -r $(PERL_LN)

.PHONY: clean distclean all
