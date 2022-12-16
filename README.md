# DBT-bench

DBT-bench is a simple benchmarking tool. For now, it runs the
[NBench](https://en.wikipedia.org/wiki/NBench) benchmark suite and a subset
of the tests in the [Perl language](https://www.perl.org/) distribution
under a user-provided executable. This executable can be any program that
takes another executable as an argument, e.g., `/usr/bin/time` or a binary
translator such as `qemu-user`.

## NBench

The scripts attempt to build and run NBench automatically, provided there
is a valid cross-compiler for the target architecture.

Build and benchmark NBench with `make nbench`.

Note that NBench's repo (under `nbench`) is a submodule, so it has to be
checked out first.

## Perl

Build and benchmark Perl with `make perl`.

Note: cross-compilation for Perl is not supported, so this can only run
with a QEMU_ARCH that matches that of the host machine.

## QEMU-user performance

Scripts are provided to invoke `dbt-bench.pl` for different QEMU tags (or
commit id's). See the `QEMU_TAGS` variable in the Makefile. Note that
you will also need to have defined `QEMU_PATH` and `QEMU_ARCH` when running
make, so that the scripts can check out the appropriate tags in the
QEMU git repository and invoke the right `linux-user` binary.

* PNG/txt plots with the integer and floating point NBench results can be
generated with:
```
$ make nbench
```

* PNG/txt plots for Perl benchmarks (built with `make perl-deps` as described
above) can be generated with:
```
$ make perl
```
The Perl suite differs from NBench in that it puts more emphasis on code
translation.

Other output formats are possible, see `Makefile`.

### Notes

* If your `QEMU_ARCH` is not that of the host machine, make sure to have
  cross-compiled NBench as described above.

* QEMU is rebuilt for every tag in `QEMU_TAG`, unless a build for that
  architecture already exists in the `out/` directory.

* Multi-arch builds are possible by setting `QEMU_ARCH`, e.g.
  `QEMU_ARCH="x86_64 aarch64"`.

* Using different compiler options is possible by setting `QEMU_CONF`. The
  parameters set there are passed verbatim to QEMU's `configure` script.
  Note that `--target-list` is already populated from `QEMU_ARCH`.

* In order to distinguish builds of the same tag with different `configure`
  options, you can set `TAG_SUFFIX`.
  Using `TAG_SUFFIX` allows us, for instance, to assign a specific
  "tag" (i.e. a git tag + suffix) to a combination of git tag and
  `--configure` settings. Without the suffix we'd just have the git tag,
  which doesn't allow us to disambiguate config settings. For example,
  to benchmark two tags with two different settings, we can do:
```
$ make -j QEMU_TAGS="foo bar" TAG_SUFFIX="settings0" QEMU_CONF="--conf-settings0" [...]
$ make clean # Deletes just the plot files, not the data files
$ make -j QEMU_TAGS="foo bar" TAG_SUFFIX="settings1" QEMU_CONF="--conf-settings1" [...]
$ make clean # Again, deletes just the plot files, not the data files
$ make -j QEMU_TAGS="foo-settings0 foo-settings1 bar-settings0 bar-settings1" [...]
$ cat nbench-fp.txt
```

* Building with `QEMU_CONF="--disable-werror"` is recommended, particularly
  when building QEMU versions that are older than the compiler being used
  to build them.

* Using the `-j` flag is safe. Tests are run sequentially; QEMU builds are
  run one at a time, and each of them is currently hardcoded to run with
  `make -j 4`.

* Sometimes a build can fail, especially is the tree is not a pristine
  copy. You can fix this manually in the tree; usually `make distclean` and/or
  `git make -f` will do the trick. Note that the latter command can delete
  valuable files that were never meant to be committed (e.g. scripts). For
  this reason it is best to just clone a fresh QEMU repo to be used with
  DBT-bench rather than using your development tree.

## What is the difference between the benchmarks?

NBench programs are small, with execution time dominated by small code loops. Thus,
when run under a DBT engine, the resulting performance depends almost entirely
on the quality of the output code.

The Perl benchmarks compile Perl code. As is common for compilation workloads,
they execute large amounts of code and show no particular code execution
hotspots. Thus, the resulting DBT performance depends largely on code
translation speed.

Quantitatively, the differences can be clearly seen under a profiler. For QEMU
v2.8.0, we get:

* NBench:

```
# Samples: 1M of event 'cycles:pp'
# Event count (approx.): 1111661663176
#
# Overhead  Command       Shared Object        Symbol
# ........  ............  ...................  .........................................
#
     6.26%  qemu-x86_64   qemu-x86_64          [.] float64_mul
     6.24%  qemu-x86_64   qemu-x86_64          [.] roundAndPackFloat64
     4.18%  qemu-x86_64   qemu-x86_64          [.] subFloat64Sigs
     2.72%  qemu-x86_64   qemu-x86_64          [.] addFloat64Sigs
     2.29%  qemu-x86_64   qemu-x86_64          [.] cpu_exec
     1.29%  qemu-x86_64   qemu-x86_64          [.] float64_add
     1.12%  qemu-x86_64   qemu-x86_64          [.] float64_sub
     0.79%  qemu-x86_64   qemu-x86_64          [.] object_class_dynamic_cast_assert
     0.71%  qemu-x86_64   qemu-x86_64          [.] helper_mulsd
     0.66%  qemu-x86_64   perf-23090.map       [.] 0x000055afd37d0b8a
     0.64%  qemu-x86_64   perf-23090.map       [.] 0x000055afd377cd8f
     0.59%  qemu-x86_64   perf-23090.map       [.] 0x000055afd37d019a
     [...]
```

* Perl:

```
# Samples: 90K of event 'cycles:pp'
# Event count (approx.): 97757063053
#
# Overhead  Command       Shared Object            Symbol
# ........  ............  .......................  ...........................................
#
   22.93%  qemu-x86_64   [kernel.kallsyms]        [k] isolate_freepages_block
    9.38%  qemu-x86_64   qemu-x86_64              [.] cpu_exec
    5.69%  qemu-x86_64   qemu-x86_64              [.] tcg_gen_code
    5.30%  qemu-x86_64   qemu-x86_64              [.] tcg_optimize
    3.45%  qemu-x86_64   qemu-x86_64              [.] liveness_pass_1
    3.24%  qemu-x86_64   [kernel.kallsyms]        [k] isolate_migratepages_block
    2.39%  qemu-x86_64   qemu-x86_64              [.] object_class_dynamic_cast_assert
    1.48%  qemu-x86_64   [kernel.kallsyms]        [k] unlock_page
    1.29%  qemu-x86_64   [kernel.kallsyms]        [k] pageblock_pfn_to_page
    1.29%  qemu-x86_64   qemu-x86_64              [.] tcg_out_opc.isra.13
    1.11%  qemu-x86_64   qemu-x86_64              [.] tcg_gen_op2
    0.98%  qemu-x86_64   [kernel.kallsyms]        [k] migrate_pages
    0.87%  qemu-x86_64   qemu-x86_64              [.] qht_lookup
    0.83%  qemu-x86_64   qemu-x86_64              [.] tcg_temp_new_internal
    0.77%  qemu-x86_64   qemu-x86_64              [.] tcg_out_modrm_sib_offset.constprop.37
    0.76%  qemu-x86_64   qemu-x86_64              [.] disas_insn.isra.49
    0.70%  qemu-x86_64   [kernel.kallsyms]        [k] __wake_up_bit
    0.55%  qemu-x86_64   [kernel.kallsyms]        [k] __reset_isolation_suitable
    0.47%  qemu-x86_64   qemu-x86_64              [.] tcg_opt_gen_mov
    [...]
```

### Why don't you just run SPEC06?

SPEC's source code cannot be redistributed. Some of its benchmarks are based
on free software, but the SPEC authors added on top of it non-free code
(usually scripts) that cannot be redistributed.

For this reason we use here benchmarks that are freely redistributable,
while capturing different performance profiles: NBench represents "hotspot
code" and Perl represents a typical "compiler" workload. In fact, Perl's
performance profile under QEMU is very similar to that of SPEC06's perlbench;
compare Perl's profile above with SPEC06 perlbench's below:

```
# Samples: 14K of event 'cycles:pp'
# Event count (approx.): 15657871399
#
# Overhead  Command      Shared Object            Symbol
# ........  ...........  .......................  ...........................................
#
   16.93%  qemu-x86_64  qemu-x86_64              [.] cpu_exec
    9.16%  qemu-x86_64  [kernel.kallsyms]        [k] isolate_freepages_block
    5.47%  qemu-x86_64  qemu-x86_64              [.] tcg_gen_code
    4.82%  qemu-x86_64  qemu-x86_64              [.] tcg_optimize
    4.15%  qemu-x86_64  qemu-x86_64              [.] object_class_dynamic_cast_assert
    3.25%  qemu-x86_64  qemu-x86_64              [.] liveness_pass_1
    1.55%  qemu-x86_64  qemu-x86_64              [.] qht_lookup
    1.23%  qemu-x86_64  qemu-x86_64              [.] tcg_gen_op2
    1.04%  qemu-x86_64  [kernel.kallsyms]        [k] copy_page
    1.00%  qemu-x86_64  qemu-x86_64              [.] tcg_out_opc.isra.13
    0.82%  qemu-x86_64  qemu-x86_64              [.] tcg_temp_new_internal
    0.78%  qemu-x86_64  qemu-x86_64              [.] tcg_out_modrm_sib_offset.constprop.37
    0.72%  qemu-x86_64  qemu-x86_64              [.] tb_cmp
    0.69%  qemu-x86_64  [kernel.kallsyms]        [k] isolate_migratepages_block
    0.67%  qemu-x86_64  qemu-x86_64              [.] disas_insn.isra.49
    0.53%  qemu-x86_64  qemu-x86_64              [.] object_get_class
    0.52%  qemu-x86_64  [kernel.kallsyms]        [k] __wake_up_bit
    [...]
```
