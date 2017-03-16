# DBT-bench

DBT-bench is a simple benchmarking tool. For now, it runs the
[NBench](https://en.wikipedia.org/wiki/NBench) benchmark suite under a
user-provided executable. This executable can be any program that takes another
executable as an argument, e.g., `/usr/bin/time` or a binary translator such
as `qemu-user`.

## NBench

Build NBench with `make -C nbench`. Define the `CROSS_COMPILE` variable
to cross-compile.

Note that NBench's repo (under `nbench`) is a submodule.

## Perl

Build perl with `make perl-deps`. The makefile will download the Perl sources,
build them and test them. Note that cross-compilation for Perl is not
supported.

## QEMU-user performance

Scripts are provided to invoke `dbt-bench.pl` for different QEMU tags (or
commit id's). See the `QEMU_VERSIONS` variable in the Makefile. Note that
you will need to have defined `QEMU_PATH` and `QEMU_ARCH` as environment
variables, so that the scripts can check out the appropriate tags in the
QEMU git repository and invoke the right `linux-user` binary.

PNG plots with the integer and floating point NBench results can be
generated with `make nbench`. (Other output formats are possible, see
`Makefile`.)

### Notes

* If your `QEMU_ARCH` is not that of the host machine, make sure to have
  cross-compiled NBench as described above.

* The scripts do not reconfigure QEMU. They do call `make clean`, however.
  Make sure the tree pointed at by `QEMU_PATH` is properly configured for the
  architecture you want. Configuring with `--disable-werror` is recommended.

* Using the `-j` flag is safe. Tests are run sequentially; however, the
  parent `-j` parameter is used when QEMU is built.

* Sometimes a build can fail, especially is the tree is not a pristine
  copy. You can fix this manually in the tree; usually `make distclean` and/or
  `git make -f` will do the trick. Note that the latter command can delete
  valuable files that were never meant to be committed (e.g. scripts). For
  this reason it is best to just clone a fresh QEMU repo to be used with
  DBT-bench rather than using your development tree.
