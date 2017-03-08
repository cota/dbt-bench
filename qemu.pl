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
$tag =~ s/\.nbench$//;

my $origdir = getcwd;
chdir($path) or die "cannot chdir($path): $!";
my $origtag = `git rev-parse HEAD`;
die "cannot invoke git at $path: $?" if ($?);

sys("git checkout $tag");
sys("make clean && make");
my $cmd = "$origdir/dbt-bench.pl $path/$arch-linux-user/qemu-$arch 1>$origdir/$outfile.tmp";
print "$cmd\n";
sys($cmd);
sys("echo \"dbt-bench: arch: $arch\" >> $origdir/$outfile.tmp");
sys("git checkout $origtag");
chdir($origdir) or die "cannot chdir($origdir): $!";
sys("mv $outfile.tmp $outfile");

sub sys {
    my $cmd = shift(@_);
    system("$cmd") == 0 or die "cannot run '$cmd': $?";
}
