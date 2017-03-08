# old versions do not compile reliably on modern GCC
# QEMU_VERSIONS := 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7
QEMU_VERSIONS := 1.7
QEMU_VERSIONS += 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8
QEMU_TAGS := $(addprefix v,$(addsuffix .0,$(QEMU_VERSIONS)))
QEMU_FILES := $(addsuffix .nbench,$(QEMU_TAGS))

all: qemu

qemu: qemu-int.png qemu-fp.png

.PHONY: qemu

qemu-%.png: qemu-%.plt
	gnuplot -e "set term pngcairo" $< > $@.tmp
	mv $@.tmp $@

qemu-%.txt: qemu-%.plt
	gnuplot -e "set term dumb" $< > $@.tmp
	mv $@.tmp $@

qemu-%.svg: qemu-%.plt
	gnuplot -e "set terminal svg size 800,600 enhanced fsize 14 butt" $< > $@.tmp
	mv $@.tmp $@

qemu-int.plt: qemu-plot.pl qemu.dat
	./$< --suite=int qemu.dat > $@

qemu-fp.plt: qemu-plot.pl qemu.dat
	./$< --suite=fp qemu.dat > $@

qemu.dat: qemu-dat.pl $(QEMU_FILES)
	./$< $(QEMU_FILES) > $@.tmp
	mv $@.tmp $@

.NOTPARALLEL: $(QEMU_FILES)

$(QEMU_FILES):
	./qemu.pl $@

clean:
	$(RM) *.tmp
	$(RM) *.dat *.plt
	$(RM) *.png *.txt

distclean: clean
	$(RM) *.nbench

.PHONY: clean distclean all
