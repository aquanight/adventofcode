#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $sum = 0;

while (<>) {
	while (/mul\((\d+),(\d+)\)/g) {
		my ($x, $y) = ($1, $2);
		$sum += $x * $y;
	}
}

say $sum;
