#!/usr/bin/perl
# Break down nbench results by benchmark, plus geomean.

use warnings;
use strict;
use File::Basename;
use lib dirname (__FILE__);
use Mean;
use Getopt::Long;

my @int_tests = ('NUMERIC SORT',
		 'STRING SORT',
		 'BITFIELD',
		 'FP EMULATION',
		 'ASSIGNMENT',
		 'IDEA',
		 'HUFFMAN');
my @fp_tests = ('FOURIER',
		'NEURAL NET',
		'LU DECOMPOSITION');
my @all_tests = (@int_tests, @fp_tests);

# output in barchart format, see https://github.com/cota/barchart
my $barchart;
my @extra_gnuplot_args;
my $suite = 'all';
my $titles;
GetOptions(
    'barchart' => \$barchart,
    'extra-gnuplot=s' => \@extra_gnuplot_args, # --barchart only
    'suite=s' => \$suite,
    'titles=s' => \$titles,
    );
my @files = @ARGV;

my %suites = (
    'all' => \@all_tests,
    'int' => \@int_tests,
    'fp' => \@fp_tests,
    );

if (!defined($suites{$suite})) {
    die "Invalid suite '$suite'. Options: ", join(', ', sort keys %suites), ".\n";
}
my @tests = @{ $suites{$suite} };

my $res;

for (my $i = 0; $i < @files; $i++) {
    get_val($files[$i]);
}

my @titles = ();

if (defined($titles)) {
    @titles = split(',', $titles);

    die if (scalar(@titles) != scalar(@files));
} else {
    # filenames without extension
    foreach my $f (@files) {
	my @parts = split('\.', $f);

	if (@parts > 1) {
	    pop @parts;
	}
	push @titles, join('.', @parts);
    }
}

my @bars = (@tests, 'gmean');
if ($barchart) {
    print "=cluster;", join(';', @titles), "\n";
    if (@extra_gnuplot_args) {
	print join("\n", map { "extraops=$_" } @extra_gnuplot_args), "\n";
    }
    pr_table(\@bars, 'val', '=table');
    pr_table(\@bars, 'err', '=yerrorbars');
} else {
    print join("\t", '# Benchmark', map { $_, 'err' } @titles), "\n";

    foreach my $t (@bars) {
	my @arr = ();
	for (my $i = 0; $i < @files; $i++) {
	    my $r = $res->{$files[$i]}->{$t};
	    push @arr, $r->{val}, $r->{err};
	}
	print join("\t", "\"$t\"", @arr), "\n";
    }
}

sub pr_table {
    my ($bars, $field, $pr) = @_;
    print "$pr\n";
    foreach my $t (@$bars) {
	my @arr = ();
	for (my $i = 0; $i < @files; $i++) {
	    my $r = $res->{$files[$i]}->{$t};
	    push @arr, $r->{$field};
	}
	print join("\t", "\"$t\"", @arr), "\n";
    }
}

sub get_val {
    my ($file) = @_;
    my $h;
    my $lastname;

    open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
    while (<$in>) {
	my $line = $_;

	chomp $line;

	if ($line =~ /(NUMERIC SORT|STRING SORT|BITFIELD|FP EMULATION|FOURIER|ASSIGNMENT|IDEA|HUFFMAN|NEURAL NET|LU DECOMPOSITION)/) {
	    my $name = $1;
	    if ($line =~ /^[^:]+:\s*[^:\s]+\s*:\s*([^:\s]+)\s*:/) {
		$lastname = $name;
		$h->{$name}->{val} = $1;
	    }
	}
	if ($line =~ /Relative standard deviation:\s*([^\s]*)/) {
	    die if !defined($lastname);
	    my $rel = $1 / 100.0;
	    $h->{$lastname}->{err} = $h->{$lastname}->{val} * $rel;
	}
    }
    close $in or die "Could not close '$file': $!";
    compute_geomean($h, \@tests);
    $res->{$file} = $h;
}

sub compute_geomean {
    my ($h, $tests) = @_;
    my @vals;
    my @errors;

    foreach (@$tests) {
	push @vals,   $h->{$_}->{val};
	push @errors, $h->{$_}->{err};
    }
    ($h->{gmean}->{val}, $h->{gmean}->{err}) = Mean::geometric_err(\@vals, \@errors);
}
