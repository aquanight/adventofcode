#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;

my $xw = 0;

my @pos;

my @scores;

while (<>) {
	chomp;
	$xw = length if $xw < length;
	push @map, [ split // ];
	for my $x (grep { $map[-1][$_] == 0 } 0 .. ($xw - 1)) {
		push @scores, 0;
		push @pos, [ $x, $#map, 0, $#scores ];
	}
}

while (@pos) {
	my ($sx, $sy, $step, $id) = (shift @pos)->@*;
	next if $sx < 0;
	next if $sx >= $xw;
	next if $sy < 0;
	next if $sy > $#map;
	my $chr = $map[$sy][$sx];
	next unless $chr == $step;
	if ($chr == 9) {
		$scores[$id]++;
	}
	else {
		push @pos, [ $sx - 1, $sy, $step + 1, $id ];
		push @pos, [ $sx + 1, $sy, $step + 1, $id ];
		push @pos, [ $sx, $sy - 1, $step + 1, $id ];
		push @pos, [ $sx, $sy + 1, $step + 1, $id ];
	}
}

use List::Util ();

say List::Util::sum @scores;
