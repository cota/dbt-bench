#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";

my $help;
my %tests = (
    'nbench' => \&run_nbench,
);
my $tests = "nbench";

GetOptions(
    'h|help' => sub { pr_usage(); },
    'tests=s' => \$tests,
    );

my $tool = $ARGV[0];
if (!$tool) {
    pr_usage();
}

if (! -X $tool) {
    die "Cannot find tool at $tool. Stopped";
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
    my $origdir = getcwd;

    if (! -X "$Bin/$nbench/nbench") {
	die "nbench executable not found. Build $nbench with make -C $Bin/$nbench (Note: it is a git submodule). Stopped";
    }

    chdir("$Bin/$nbench") or die "cannot chdir($Bin/$nbench): $!";

    my $cmd = "taskset -c 0 $tool ./nbench -V";
    sys($cmd);
    chdir($origdir) or die "cannot chdir($origdir): $!";
}

