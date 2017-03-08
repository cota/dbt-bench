#!/usr/bin/perl

use warnings;
use strict;

my @vers = map { (my $s = $_) =~ s/\.nbench$//; $s } @ARGV;
die if (!@vers);

my $res;
my $arch;

foreach my $ver (@vers) {
    get_val($ver);
}

print "# versions: ", join("\t", @vers), "\n";
print "# arch: $arch\n";
for (my $i = 0; $i < @vers; $i++) {
    print join("\t", $i, $res->{$vers[$i]}->{int}, $res->{$vers[$i]}->{fp}), "\n";
}

sub get_val {
    my ($ver) = @_;
    my $file = "$ver.nbench";
    my $r;

    open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
    while (<$in>) {
	my $line = $_;

	chomp $line;
	if (!defined($r->{int}) && $line =~ /INTEGER INDEX\s+:\s+([.0-9]+)/) {
	    $r->{int} = $1;
	}
	if (!defined($r->{fp}) && $line =~ /FLOATING-POINT INDEX:\s+([.0-9]+)/) {
	    $r->{fp} = $1;
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
    }
    close $in or die "Could not close '$file': $!";

    $res->{$ver} = $r;
}
