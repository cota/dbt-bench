#!/usr/bin/perl
# Given an output filename, run the appropriate QEMU binary under dbt-bench.pl.

use warnings;
use strict;
use Cwd;
use File::Basename;

my $outfile = $ARGV[0] or die "No output file given. Stopped";
my $tag_suffix = "";
if (@ARGV > 1) {
    $tag_suffix = $ARGV[1];
}

my $outdir = dirname($outfile);
my $origdir = dirname($outdir);
my $outbasename = basename($outfile);

my $match = $outbasename =~ m/(.*)$tag_suffix-(.*)\.([^.]+)/;
if (!$match) {
    die "Cannot find out tag/arch/testname triple from '$outbasename'";
}
my $tag = $1;
my $arch = $2;
my $testname = $3;

my $binary = "$outdir/$tag$tag_suffix/bin/qemu-$arch";
my $cmd = "$origdir/dbt-bench.pl --tests=$testname $binary 1>$outfile.tmp";
print "$cmd\n";
sys($cmd);
sys("echo \"dbt-bench: arch: $arch\" >> $outfile.tmp");
my $host = `cat /proc/cpuinfo | grep 'model name' | head -1`;
chomp($host);
if ($?) {
    undef $host;
}
if ($host) {
    $host =~ s/[^:]*:\s*(.*)\s*$/$1/;
    sys("echo \"dbt-bench: host: $host\" >> $outfile.tmp");
}
chdir($origdir) or die "cannot chdir($origdir): $!";
sys("mv $outfile.tmp $outfile");

sub sys {
    my $cmd = shift(@_);
    system("$cmd") == 0 or die "cannot run '$cmd': $?";
}
