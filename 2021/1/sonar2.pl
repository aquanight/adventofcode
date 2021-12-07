#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $prev;
my @prev;

my $ct = 0;

while (<>) {
	chomp;
	push @prev, 0+$_;
	next unless @prev >= 3;
	while (@prev > 3) { shift @prev; }
	my $sum = $prev[0] + $prev[1] + $prev[2];
	if (defined $prev) {
		if ($sum > $prev) {
			say "$sum (increased)";
			++$ct;
		}
		elsif ($sum < $prev) {
			say "$sum (decreased)";
		}
		else {
			say "$sum (no change)";
		}
	}
	else {
		say "$sum (no previous)";
	}
	$prev = $sum;
}

say "Number of increases: $ct";
