#!/usr/bin/perl
# invoke qemu's linux-user for a certain tag.
# env variables: QEMU_PATH, QEMU_ARCH

use warnings;
use strict;
use Cwd;

if (!defined($ENV{'QEMU_PATH'})) {
    die "Define QEMU_PATH environment variable. Stopped";
}
my $path = $ENV{'QEMU_PATH'};
if (! -d $path) {
    die "$path is not a directory. Stopped";
}

if (!defined($ENV{'QEMU_ARCH'})) {
    die "Define QEMU_ARCH environment variable, e.g. x86_64. Stopped";
}
my $arch = $ENV{'QEMU_ARCH'};

my $outfile = $ARGV[0] or die "No output file given. Stopped";

my $tag = $outfile;
my $testname;
$tag =~ s|.*/([^/]+)$|$1|;
if ($tag =~ /\.([^.]+)$/) {
    $testname = $1;
}
if (!defined($testname)) {
    die "Filename not recognized; missing file extension. Stopped";
}
$tag =~ s/\.$testname$//;

my $origdir = getcwd;
chdir($path) or die "cannot chdir($path): $!";
my $origtag = `git rev-parse HEAD`;
die "cannot invoke git at $path: $?" if ($?);

sys("make clean");
sys("git checkout $tag");
# The first make can fail if we had to re-run ./configure
if (system("make")) {
    sys("make");
}
my $cmd = "$origdir/dbt-bench.pl --tests=$testname $path/$arch-linux-user/qemu-$arch 1>$origdir/$outfile.tmp";
print "$cmd\n";
sys($cmd);
sys("echo \"dbt-bench: arch: $arch\" >> $origdir/$outfile.tmp");
my $host = `cat /proc/cpuinfo | grep 'model name' | head -1`;
chomp($host);
if ($?) {
    undef $host;
}
if ($host) {
    $host =~ s/[^:]*:\s*(.*)\s*$/$1/;
    sys("echo \"dbt-bench: host: $host\" >> $origdir/$outfile.tmp");
}
sys("git checkout $origtag");
chdir($origdir) or die "cannot chdir($origdir): $!";
sys("mv $outfile.tmp $outfile");

sub sys {
    my $cmd = shift(@_);
    system("$cmd") == 0 or die "cannot run '$cmd': $?";
}
