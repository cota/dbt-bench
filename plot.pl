#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $suite = 'int';
my $xlabel = 'Version';

GetOptions(
    'xlabel=s' => \$xlabel,
    'suite=s' => \$suite,
    );

my %cols = (
    'int' => 2,
    'fp' => 4,
    'perl' => 2,
    );

my %titles = (
    'int' => 'NBench Integer Performance',
    'fp' => 'NBench Floating Point Performance',
    'perl' => 'Perl Compilation Performance',
    );

my %ylabel = (
    'int' => 'Score\n(Higher is better)',
    'fp'  => 'Score\n(Higher is better)',
    'perl' => 'Execution Time (s)\n(Lower is better)',
    );

die "Invalid test $suite. Stopped" if (!$cols{$suite});

my $file = $ARGV[0];

my @vers;
my $arch;
my $host;
open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
while (<$in>) {
    if ($_ =~ /^# versions: (.*)/) {
	@vers = split("\t", $1);
    }
    if ($_ =~ /^# arch: (\w+)/) {
	$arch = $1;
    }
    if ($_ =~ /^# host: (.+)/) {
	$host = $1;
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

print "set border linewidth 2.0\n";

print "set title \"$arch ", $titles{$suite};
if ($host) {
    print "\\nHost: $host";
}
print "\" noenhanced\n";
print "set xrange [-1:", scalar(@vers), "]\n";
print "set xtics (", join(", ", @arr), ")\n";
print "set xtics rotate\n";
print "set ylabel \"", $ylabel{$suite}, "\"\n";
print "set xlabel '$xlabel'\n";
my $col = $cols{$suite};
my $col2 = $col + 1;
my $ls = 'lw 1.5 pi -1 ps 1.2';
my @pr;
push @pr, "'$file' using 1:$col:$col2 notitle with errorbars $ls";
push @pr, "'$file' using 1:$col notitle with linespoints $ls";
print "plot ", join(", \\\n", @pr), "\n";
