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

* PNG plots with the integer and floating point NBench results can be
generated with:
```
$ make nbench
```

* PNG plots for Perl benchmarks (built with `make perl-deps` as described
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
