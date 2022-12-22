#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @grid;

my $width = undef;

while (<>) {
	chomp;
	my $c = length;
	$width //= $c;
	$width == $c or die "Irregular grid";
	push @grid, [ split // ];
}



my $maxc = $width - 1;

my $best = -1;

for my $r (0 .. $#grid) {
	for my $c (0 .. $maxc) {
		my $value = $grid[$r][$c];
		my $north = 0;
		my $east = 0;
		my $south = 0;
		my $west = 0;
		for (my $r2 = ($r - 1); $r2 >= 0; --$r2) {
			++$north;
			if ($value <= $grid[$r2][$c]) {
				last;
			}
		}
		for (my $r2 = ($r + 1); $r2 < @grid; ++$r2) {
			++$south;
			if ($value <= $grid[$r2][$c]) {
				last;
			}
		}
		for (my $c2 = ($c - 1); $c2 >= 0; --$c2) {
			++$west;
			if ($value <= $grid[$r][$c2]) {
				last;
			}
		}
		for (my $c2 = ($c + 1); $c2 < $width; ++$c2) {
			++$east;
			if ($value <= $grid[$r][$c2]) {
				last;
			}
		}
		my $scenic = $north * $east * $south * $west;
		if ($scenic > $best) {
			say STDERR "Tree at ($r, $c) has scores north: $north, east: $east, south: $south, west: $west, total: $scenic";
			$best = $scenic;
		}
	}
}

say $best;
