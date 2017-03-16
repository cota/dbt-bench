#!/usr/bin/perl

use warnings;
use strict;
use Mean;

my @files = @ARGV;
my @vers;
foreach (@files) {
    my $s = $_;
    $s =~ s|.*/([^/]+)$|$1|;
    $s =~ s/\.perl$//;
    push @vers, $s;
}
die if (!@vers);

my $res;
my $arch;
my $host;

for (my $i = 0; $i < @vers; $i++) {
    get_val($vers[$i], $files[$i]);
}

print "# versions: ", join("\t", @vers), "\n";
print "# arch: $arch\n";
print "# host: $host\n";
for (my $i = 0; $i < @vers; $i++) {
    my $r = $res->{$vers[$i]};
    print join("\t", $i, $r->{avg}, $r->{stdev}), "\n";
}

sub get_val {
    my ($ver, $file) = @_;

    open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
    while (<$in>) {
	my $line = $_;

	chomp $line;

	if ($line =~ /dbt-bench: duration: (.+) \+- (.+) s/) {
	    $res->{$ver}->{avg} = $1;
	    $res->{$ver}->{stdev} = $2;
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
	if ($line =~ /dbt-bench: host: (.+)/) {
	    my $h = $1;
	    if (!defined($host)) {
		$host = $h;
	    }
	    if ($h ne $host) {
		die "Host '$h' in file '$file' does not match that in previous files ('$host'). Stopped";
	    }
	}
    }
    close $in or die "Could not close '$file': $!";
}
