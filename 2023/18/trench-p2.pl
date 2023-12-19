#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @vtx = ( [0, 0] );

my $x = 0;
my $y = 0;

while (<>) {
	my ($cmd, $steps, $clr) = /^([UDLR]) +(\d+) +\(\#([0-9a-f]{6})\)$/;
	defined $cmd or die "Input error";

	if (1) {
		$clr = hex $clr;

		$cmd = $clr & 0x0F;
		$clr >>= 4;

		$cmd = (qw/R D L U/)[$cmd];
		$steps = $clr;
	}
	say STDERR "Decoded command: $cmd $steps";
	my ($ox, $oy);
	if ($cmd eq 'R') {
		($ox, $oy) = ($x + $steps, $y);
	}
	elsif ($cmd eq 'L') {
		($ox, $oy) = ($x - $steps, $y);
	}
	elsif ($cmd eq 'U') {
		($ox, $oy) = ($x, $y - $steps);
	}
	elsif ($cmd eq 'D') {
		($ox, $oy) = ($x, $y + $steps);
	}
	push @vtx, [ $ox, $oy ];
	($x, $y) = ($ox, $oy);
}

my $area = 0;
for my $i ( 0 .. $#vtx ) {
	my ($xc, $yc) = $vtx[$i]->@*;
	my ($xp, $yp) = $vtx[$i - 1]->@*; # At 0, this gets [-1], the last vertex, which we want.
	$area += ($xp * $yc) - (($xc) * $yp) + abs($xp - $xc) + abs($yp - $yc);
	#$area += $vtx[$i][1] * ($vtx[$i - 1][0] - $vtx[($i + 1) % @vtx][0]);
}

$area /= 2;
++$area;

say $area;
