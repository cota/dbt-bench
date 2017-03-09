# Mean.pm
# roll our own basic stats to avoid CPAN dependencies
package Mean;

use warnings;
use strict;
use Exporter qw(import);
use Carp;

our @EXPORT_OK = qw(arithmetic geometric geometric_err harmonic stdev);

sub arithmetic {
    my ($data) = @_;

    if (not @$data) {
	croak "Empty array";
    }
    my $total = 0;
    foreach (@$data) {
	$total += $_;
    }
    my $mean = $total / @$data;
    return $mean;
}

# corrected sample standard deviation
# http://en.wikipedia.org/wiki/Standard_deviation
sub stdev {
    my ($data) = @_;

    if (@$data == 1) {
	return 0;
    }
    my $mean = &arithmetic($data);
    my $sqtotal = 0;
    foreach (@$data) {
	$sqtotal += ($mean-$_) ** 2;
    }
    my $std = ($sqtotal / (@$data-1)) ** 0.5;
    return $std;
}

sub geometric {
    my ($data) = @_;

    if (not @$data) {
	croak "Empty array";
    }
    my $total = 1;
    foreach (@$data) {
	if ($_ < 0) {
	    croak "Cannot use geometric mean on negative values (val: $_)";
	}
	$total *= $_;
    }
    my $mean = $total ** (1 / scalar(@$data));
    return $mean;
}

sub geometric_err {
    my ($data, $errs) = @_;

    if (not @$data or not @$errs) {
	croak "Empty array";
    }
    if (scalar(@$data) != scalar(@$errs)) {
	croak "data != errs";
    }
    my $total = 1;

    for (my $i = 0; $i < @$data; $i++) {
	my $v = $data->[$i];
	if ($v < 0) {
	    croak "Cannot use geometric mean on negative values (val: $v)";
	}
	$total *= $v;
    }
    my @rels = ();
    for (my $i = 0; $i < @$errs; $i++) {
	my $v = $data->[$i];
	my $e = $errs->[$i];
	my $rel = $e / $v;
	push @rels, $rel;
    }
    my $rel = sqrt_sum(\@rels);

    my $mean = $total ** (1.0 / scalar(@$data));
    $rel *= 1.0 / scalar(@$data);
    my $err = $rel * $mean;
    return ($mean, $err);
}

sub inv_err {
    my ($v, $err) = @_;

    my $rel = $err / $v;
    my $r = 1.0 / $v;
    return ($r, $rel * $r);
}

sub sqrt_sum {
    my ($data) = @_;

    my $v = 0;
    foreach (@$data) {
	$v += $_ * $_;
    }
    return sqrt($v);
}

sub sum_err {
    my ($data, $err) = @_;

    my $r = 0;
    foreach (@$data) {
	$r += $_;
    }
    return ($r, sqrt_sum($err));
}

sub harmonic {
    my ($data, $err) = @_;

    if (not @$data) {
	croak "Empty array";
    }

    if ($err) {
	my @values = ();
	my @errors = ();
	for (my $i = 0; $i < scalar(@$data); $i++) {
	    my ($v, $e) = inv_err($data->[$i], $err->[$i]);
	    push @values, $v;
	    push @errors, $e;
	}
	my ($v, $e) = sum_err(\@values, \@errors);
	($v, $e) = inv_err($v, $e);
	my $rel = $e / $v;
	$v *= scalar(@$data);
	return ($v, $rel * $v);
    } else {
	my $v = 0;
	foreach (@$data) {
	    $v += 1.0 / $_;
	}
	return scalar(@$data) / $v;
    }
}

1;
