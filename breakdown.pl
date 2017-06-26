#!/usr/bin/perl
# Break down nbench results by benchmark, plus geomean.

use warnings;
use strict;
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
GetOptions(
    'barchart' => \$barchart,
    );
my @files = @ARGV;

my $res;

for (my $i = 0; $i < @files; $i++) {
    get_val($files[$i]);
}

# filenames without extension
my @clean = ();
foreach my $f (@files) {
    my @parts = split('\.', $f);

    if (@parts > 1) {
	pop @parts;
    }
    push @clean, join('.', @parts);
}

my @titles = (@all_tests, 'gmean');
if ($barchart) {
    print "=cluster;", join(';', @clean), "\n";
    pr_table(\@titles, 'val', '=table');
    pr_table(\@titles, 'err', '=yerrorbars');
} else {
    print join("\t", '# Benchmark', map { $_, 'err' } @clean), "\n";

    foreach my $t (@titles) {
	my @arr = ();
	for (my $i = 0; $i < @files; $i++) {
	    my $r = $res->{$files[$i]}->{$t};
	    push @arr, $r->{val}, $r->{err};
	}
	print join("\t", "\"$t\"", @arr), "\n";
    }
}

sub pr_table {
    my ($titles, $field, $pr) = @_;
    print "$pr\n";
    foreach my $t (@$titles) {
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
    compute_geomean($h, \@all_tests);
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
