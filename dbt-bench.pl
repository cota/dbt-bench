#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";

my $tool = $ARGV[0];
my $help;

GetOptions(
    'h|help' => sub { pr_usage(); },
    );

if (!$tool) {
    pr_usage();
}

if (! -X $tool) {
    die "Cannot find tool at $tool. Stopped";
}

run_nbench();

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

    my $cmd = "taskset -c 0 $tool ./nbench";
    sys($cmd);
    chdir($origdir) or die "cannot chdir($origdir): $!";
}

