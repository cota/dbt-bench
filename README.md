# dbt-bench

dbt-bench is a simple benchmarking tool. For now, it runs the
[NBench](https://en.wikipedia.org/wiki/NBench) benchmark suite under a
user-provided executable. This executable can be any program that takes another
executable as an argument, e.g., `/usr/bin/time` or a binary translator such
as `qemu-user`.

## NBench

Build NBench with `make -C nbench`. Define the `CROSS_COMPILE` variable
to cross-compile.

Note that NBench's repo (under `nbench`) is a submodule.

## QEMU-user performance

Scripts are provided to invoke `dbt-bench.pl` for different QEMU tags (or
commit id's). See the `QEMU_VERSIONS` variable in the Makefile. Note that
you will need to have defined `QEMU_PATH` and `QEMU_ARCH` as environment
variables, so that the scripts can check out the appropriate tags in the
QEMU git repository and invoke the right `linux-user` binary.

PNG plots with the integer and floating point NBench results can be
generated with `make qemu`. (Other output formats are possible, see
`Makefile`.)

N.B. If your `QEMU_ARCH` is not that of the host machine, make sure to have
cross-compiled NBench as described above.
