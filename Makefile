# old versions do not compile reliably on modern GCC
QEMU_TAGS := v7.0.0 v7.1.0 master
OUTDIR := out
NBENCH_FILES := $(addprefix $(OUTDIR)/,$(addsuffix .nbench,$(QEMU_TAGS)))
PERL_FILES   := $(addprefix $(OUTDIR)/,$(addsuffix .perl,$(QEMU_TAGS)))
QEMU_FILES := $(NBENCH_FILES) $(PERL_FILES)

PERL_VERSION := 5.36.0
PERL_DIR := perl-$(PERL_VERSION)
PERL_LN := perldir

# Do not run Perl tests by default because building Perl takes a while.
# Moreover, Perl doesn't support cross-compilation.
all: nbench

nbench: nbench-int.png nbench-fp.png
.PHONY: nbench

perl: perl.png
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
# of the -j parameter. However, we want to leverage multiple
# cores to build each of the QEMU versions we're testing.
# To make sure subsequent make invocations pick this up,
# the recipe that calls the Perl script begins with '+'.
.NOTPARALLEL: $(QEMU_FILES)

$(QEMU_FILES):
	+./qemu.pl $@

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
