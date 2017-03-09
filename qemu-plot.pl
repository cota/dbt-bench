#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $suite = 'int';

GetOptions(
    'suite=s' => \$suite,
    );

my %cols = (
    'int' => 2,
    'fp' => 4,
    );

my %titles = (
    'int' => 'Integer',
    'fp' => 'Floating Point',
    );

die "Invalid test $suite. Stopped" if (!$cols{$suite});

my $file = $ARGV[0];

my @vers;
my $arch;
open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
while (<$in>) {
    if ($_ =~ /^# versions: (.*)/) {
	@vers = split("\t", $1);
    }
    if ($_ =~ /^# arch: (\w+)/) {
	$arch = $1;
    }
}
close $in or die "Could not close '$file': $!";

die if (!@vers);
die if (!defined($arch));

my @arr;
for (my $i = 0; $i < @vers; $i++) {
    my $ver = $vers[$i];
    $arr[$i] = "'$ver' $i";
}

$arch =~ s/_/\\_/g;
print "set border linewidth 2.0\n";
print "set title '$arch NBench ", $titles{$suite}, " Performance'\n";
print "set xrange [-1:", scalar(@vers), "]\n";
print "set xtics (", join(", ", @arr), ")\n";
print "set xtics rotate\n";
print "set ylabel 'Score'\n";
print "set xlabel 'QEMU version'\n";
my $col = $cols{$suite};
my $col2 = $col + 1;
my $ls = 'lw 1.5 pi -1 ps 1.2';
my @pr;
push @pr, "'$file' using 1:$col:$col2 notitle with errorbars $ls";
push @pr, "'$file' using 1:$col notitle with linespoints $ls";
print "plot ", join(", \\\n", @pr), "\n";
