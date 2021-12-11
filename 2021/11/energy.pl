#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use List::Util ();

my @grid;

my $xwide;

while (<>) {
	/^(\d+)$/ or die "Input error";
	my @r = (split //, $_);
	if (defined $xwide && $xwide != $#r) { die "Invalid row"; }
	$xwide = $#r;
	push @r, undef;
	push @grid, \@r;
}
push @grid, [];

my $flashcount = 0;

sub neighbors ($x, $y) {
	return List::Util::pairgrep { defined $grid[$b][$a] } (
		$x - 1, $y - 1, # NW
		$x    , $y - 1, # N
		$x + 1, $y - 1, # NE
		$x - 1, $y,     # W
		                # starting point
		$x + 1, $y,     # E
		$x - 1, $y + 1, # SW
		$x    , $y + 1, # S
		$x + 1, $y + 1, # SE
	);
}

sub findflash {
	for my $y ( 0 .. ($#grid - 1) ) {
		for my $x ( 0 .. $xwide ) {
			if ($grid[$y][$x] > 9) {
				return ($x, $y);
			}
		}
	}
	return;
}

sub step {
	for my $y ( 0 .. ($#grid - 1) ) {
		my \@r = $grid[$y];
		for my $x ( 0 .. $xwide ) {
			++$r[$x];
		}
	}
	# Perform flash checks.
	while (my ($x, $y) = findflash) {
		++$flashcount;
		$grid[$y][$x] = -1;
		my @n = neighbors $x, $y;
		while (@n) {
			my $xn = shift;
			my $yn = shift;
			if ($grid[$yn][$xn] >= 0) { ++$grid[$yn][$xn]; }
		}
	}
}

use constant STEPS => 100;

my $remain = STEPS;

while ($remain--) {
	step;
}

say "Flash count: $flashcount";
