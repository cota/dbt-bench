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
    'fp' => 3,
    );

my %titles = (
    'int' => 'Integer',
    'fp' => 'Floating Point',
    );

die "Invalid test $suite\n" if (!$cols{$suite});

my $file = $ARGV[0];

my @vers;
open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
while (<$in>) {
    if ($_ =~ /^# (.*)/) {
	@vers = split("\t", $1);
    }
}
close $in or die "Could not close '$file': $!";

die if (!@vers);

my @arr;
for (my $i = 0; $i < @vers; $i++) {
    my $ver = $vers[$i];
    $arr[$i] = "'$ver' $i";
}

print "set title 'NBench ", $titles{$suite}, " Performance'\n";
print "set xrange [-1:", scalar(@vers), "]\n";
print "set xtics (", join(", ", @arr), ")\n";
print "set ylabel 'NBench Score'\n";
print "plot '$file' using 1:$cols{$suite} title '' with linespoints\n";
