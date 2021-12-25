#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @grid;
my $xwide;

while (<>) {
	chomp;
	/^[\.v\>]+$/ or die "Input error";
	if (defined $xwide) {
		die "Input error" unless $xwide == length;
	}
	else {
		$xwide = length;
	}
	push @grid, [ split //, $_ ];
}

sub step {
	my $moves = 0;
	my @eastmove;
	my @southmove;
	# Pass 1: Look to see which east-moving nodes can move.
	for my $y ( 0 .. $#grid ) {
		my \@r = $grid[$y];
		for my $x ( 0 .. $#r ) {
			if ($r[$x] eq '>' && $r[($x + 1) % $xwide] eq '.') {
				push @eastmove, $x, $y;
			}
		}
	}
	# Now actually *do* the east movements.
	while (@eastmove) {
		my ($x, $y) = splice @eastmove, 0, 2;
		$grid[$y][$x] = '.';
		$grid[$y][($x + 1) % $xwide] = '>';
		++$moves;
	}
	# Pass 2: Look for south-moving nodes
	for my $y ( 0 .. $#grid ) {
		my \@r = $grid[$y];
		for my $x ( 0 .. $#r ) {
			if ($r[$x] eq 'v' && $grid[ ($y + 1) % (scalar @grid) ][$x] eq '.') {
				push @southmove, $x, $y;
			}
		}
	}
	while (@southmove) {
		my ($x, $y) = splice @southmove, 0, 2;
		$grid[$y][$x] = '.';
		$grid[($y + 1) % @grid][$x] = 'v';
		++$moves;
	}
	return $moves;
}

my $stepcount = 0;
while (++$stepcount) {
	if (step() == 0) { last; }
}

say "No movement at step $stepcount";
