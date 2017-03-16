# old versions do not compile reliably on modern GCC
# QEMU_VERSIONS := 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7
QEMU_VERSIONS := 1.7
QEMU_VERSIONS += 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8
OUTDIR := out
QEMU_TAGS := $(addprefix v,$(addsuffix .0,$(QEMU_VERSIONS)))
NBENCH_FILES := $(addprefix $(OUTDIR)/,$(addsuffix .nbench,$(QEMU_TAGS)))
QEMU_FILES := $(NBENCH_FILES)

all: nbench

nbench: nbench-int.png nbench-fp.png
.PHONY: nbench

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

# This makes sure we generate one file at a time, regardless
# of the -j parameter. However, we want to leverage multiple
# cores to build each of the QEMU versions we're testing.
# To make sure subsequent make invocations pick this up,
# the recipe that calls the Perl script begins with '+'.
.NOTPARALLEL: $(QEMU_FILES)

$(QEMU_FILES):
	+./qemu.pl $@

clean:
	$(RM) *.tmp
	$(RM) *.dat *.plt
	$(RM) *.png *.txt

distclean: clean
	$(RM) $(OUTDIR)/*.nbench

.PHONY: clean distclean all
