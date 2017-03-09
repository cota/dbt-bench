#!/usr/bin/perl

use warnings;
use strict;
use Mean;

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

my @files = @ARGV;
my @vers;
foreach (@files) {
    my $s = $_;
    $s =~ s|.*/([^/]+)$|$1|;
    $s =~ s/\.nbench$//;
    push @vers, $s;
}
die if (!@vers);

my $res;
my $arch;
my $host;

for (my $i = 0; $i < @vers; $i++) {
    get_val($vers[$i], $files[$i]);
}

print "# versions: ", join("\t", @vers), "\n";
print "# arch: $arch\n";
print "# host: $host\n";
for (my $i = 0; $i < @vers; $i++) {
    my $r = $res->{$vers[$i]};
    print join("\t", $i,
	       $r->{int}->{gmean}, $r->{int}->{err},
	       $r->{fp}->{gmean},  $r->{fp}->{err}
    ), "\n";
}

sub get_val {
    my ($ver, $file) = @_;
    my $r;
    my $s;
    my $h;
    my @avgs = ();
    my @errors = ();
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
	    $h->{$lastname}->{rel_err} = $1 / 100.0;
	}
	if ($line =~ /dbt-bench: arch: (\w+)/) {
	    my $a = $1;
	    if (!defined($arch)) {
		$arch = $a;
	    }
	    if ($a ne $arch) {
		die "architecture '$a' in file '$file' does not match that in previous files ('$arch'). Stopped";
	    }
	}
	if ($line =~ /dbt-bench: host: (.+)/) {
	    my $h = $1;
	    if (!defined($host)) {
		$host = $h;
	    }
	    if ($h ne $host) {
		die "Host '$h' in file '$file' does not match that in previous files ('$host'). Stopped";
	    }
	}
    }
    close $in or die "Could not close '$file': $!";

    grab_results($ver, 'int', $h, \@int_tests);
    grab_results($ver, 'fp', $h, \@fp_tests);
}

sub grab_results {
    my ($ver, $type, $h, $tests) = @_;
    my @vals;
    my @errors;

    foreach (@$tests) {
	push @vals,   $h->{$_}->{val};
	push @errors, $h->{$_}->{val} * $h->{$_}->{rel_err};
    }
    my ($gmean, $err) = Mean::geometric_err(\@vals, \@errors);
    $res->{$ver}->{$type}->{gmean} = $gmean;
    $res->{$ver}->{$type}->{err}   = $err;
}
