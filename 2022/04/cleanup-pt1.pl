#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $score = 0;

while (<>) {
	chomp;
	my ($lo1, $hi1, $lo2, $hi2);
	(($lo1, $hi1, $lo2, $hi2) = /^\s*(\d+)\s*-(\d+)\s*,\s*(\d+)\s*-\s*(\d+)\s*$/) or die "Input error";
	assert $lo1 <= $hi1;
	assert $lo2 <= $hi2;
	if ($lo1 == $lo2 || $hi1 == $hi2) {
		++$score;
	}
	elsif ($lo1 < $lo2) {
		if ($hi2 <= $hi1) {
			++$score;
		}
	}
	else {
		if ($hi2 >= $hi1) {
			++$score;
		}
	}
}

say $score;
