#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $index = 0;

my $score = 0;

sub compare_lists ($l, $r) {
	my @left = @$l;
	my @right = @$r;
	while (@left || @right) {
		my $lv = shift @left;
		my $rv = shift @right;
		if (defined($lv) != defined($rv)) {
			return defined($lv) - defined($rv);
		}
		if (!defined($lv)) {
			assert !defined($rv);
			next;
		}
		if (!ref($lv) != !ref($rv)) {
			if (ref($lv)) { $rv = [ $rv ]; }
			else { $lv = [ $lv ]; }
		}
		if (ref($lv)) {
			assert ref($rv);
			if ($#$lv < $#$rv) {
				$#$lv = $#$rv;
			}
			elsif ($#$lv > $#$rv) {
				$#$rv = $#$lv;
			}
			unshift @left, @$lv;
			unshift @right, @$rv;
			next;
		}
		if ($lv < $rv) {
			return -1;
		}
		elsif ($lv > $rv) {
			return 1;
		}
	}
	return 0;
}

while (1) {
	++$index;
	chomp(my $left = <>);
	defined $left or last;
	chomp(my $right = <>);
	defined $right or die "Incomplete record!";
	my $blank = <>;
	assert (($blank//"")=~m/^$/);
	assert($left =~ m/^[\[,\d\]]+$/);
	assert($right =~ m/^[\[,\d\]]+$/);

	my $left_val = eval "$left";
	my $right_val = eval "$right";

	my $r = compare_lists $left_val, $right_val;
	if ($r < 0) { $score += $index; }
	last unless defined $blank;
}

say $score;
