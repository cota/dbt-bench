#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use lib dirname (__FILE__);
use Mean;

my $help;
my %tests = (
    'nbench' => \&run_nbench,
    'perl'   => \&run_perl,
);
my $tests = "nbench";
my $tries = 5; # ignored for NBench

GetOptions(
    'h|help' => sub { pr_usage(); },
    'tests=s' => \$tests,
    'tries=i' => \$tries,
    );

my $tool = $ARGV[0];
if (!$tool) {
    pr_usage();
}

if (! -X $tool) {
    die "Cannot find tool at $tool. Stopped";
}

my $arch = $tool;
$arch =~ s|.*/qemu-([^/]+)$|$1|;
if (!$arch) {
    die "Cannot figure out arch from '$tool'";
}

my @tests = split(',', $tests);
if (!@tests) {
    die "No tests given. Stopped";
}

foreach (@tests) {
    if (!$tests{$_}) {
	die "Unrecognized test '$_'. Stopped";
    }
    $tests{$_}->();
}

sub pr_usage {
    my $usage = "Usage: $0 tool\n";
    print($usage);
    exit 1;
}

sub sys {
    my $cmd = shift(@_);
    system("$cmd") == 0 or die "cannot run '$cmd': $?";
}

sub run_nbench {
    my $nbench = 'nbench';
    my $outdir = "$Bin/out";
    my $binary = "$outdir/nbench.$arch";
    my $origdir = getcwd;

    if (! -X $binary) {
	die "nbench executable not found at '$binary'. Check dbt-bench/Makefile for the rule to build it.";
    }

    chdir("$outdir") or die "cannot chdir($outdir): $!";
    my $cmd = "taskset -c 0 $tool $binary -V";
    sys($cmd);
    chdir($origdir) or die "cannot chdir($origdir): $!";
}

sub run_perl {
    my $plpath = 'perldir';
    my $origdir = getcwd;

    if (! -X "$Bin/$plpath/perl-real") {
	die "$plpath/perl-real executable not found. Build perl with `make perl-deps'. Stopped";
    }
    chdir("$Bin/$plpath") or die "cannot chdir($Bin/$plpath): $!";
    wr_perl_real($plpath, 'miniperl');
    wr_perl_real($plpath, 'perl');
    my @durations;
    # We only run Perl's compilation tests, so that code translation is emphasized
    chdir("$Bin/$plpath/t") or die "cannot chdir($Bin/$plpath/t): $!";
    my $cmd = "taskset -c 0 $tool $Bin/$plpath/perl-real harness $Bin/$plpath/t/comp/*.t";
    for (my $i = 0; $i < $tries; $i++) {
	my $t0 = [gettimeofday];
	sys($cmd);
	my $duration = tv_interval($t0);
	push @durations, $duration;
    }
    my $avg = Mean::arithmetic(\@durations);
    my $stdev = Mean::stdev(\@durations);
    print "dbt-bench: duration: $avg +- $stdev s\n";
    chdir($origdir) or die "cannot chdir($origdir): $!";
}

sub wr_perl_real {
    my ($plpath, $file) = @_;

    open my $fh, '>:encoding(UTF-8)', $file or die "Could not open '$file' for writing $!";
    print $fh "#!/bin/sh\n";
    print $fh "$tool $Bin/$plpath/${file}-real ", '"$@"', "\n";
    close $fh or die "Could not close '$file': $!";
    sys("chmod +x $file");
}

