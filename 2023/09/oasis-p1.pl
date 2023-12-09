#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

my $sum = 0;

while (<>) {
	my @hist = [ split / +/ ];
	until (List::Util::all { $_ == 0 } $hist[-1]->@*) {
		my @prev = $hist[-1]->@*;
		my @next;
		for (my $ix = 1; $ix < @prev; ++$ix) {
			my $x = $prev[$ix - 1];
			my $y = $prev[$ix];
			my $diff = $y - $x;
			push @next, $diff;
		}
		push @hist, [ @next ];
	}
	push $hist[-1]->@*, 0; # Add another zero to the last line to represent the prediction step.
	while (@hist > 1) {
		my @step = (pop @hist)->@*;
		my $prev = $hist[-1];
		my $predix = $#step;
		my $solve = $prev->[$predix] + $step[$predix];
		push @$prev, $solve;
	}
	$sum += $hist[0][-1];
}

say $sum;
