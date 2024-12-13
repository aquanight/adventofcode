#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;

my $xw = 0;

use constant DIRS => [-1, 0], [1, 0], [0, -1], [0, 1];

while (<>) {
	chomp;
	$xw = length if $xw < length;
	push @map, [ split //, $_ ];
}

my $score = 0;

while (1) {
	my ($sy) = grep { grep /\w/, $map[$_]->@* } keys @map;
	last unless defined $sy;
	my ($sx) = grep { $map[$sy][$_] =~ /\w/ } keys $map[$sy]->@*;
	my $area = 0;
	my $corner = 0;
	my @q = [ $sx, $sy ];
	my $region = $map[$sy][$sx];
	while (@q) {
		my ($x, $y) = (shift @q)->@*;
		my $plot = $map[$y][$x];
		next if $plot eq '#';
		$map[$y][$x] = '#';
		++$area;
		my $up = $y > 0 ? $map[$y - 1][$x] : '';
		my $left = $x > 0 ? $map[$y][$x - 1] : '';
		my $down = $y < $#map ? $map[$y + 1][$x] : '';
		my $right = ($x + 1) < $xw ? $map[$y][$x + 1] : '';
		my $ul = $up && $left && $map[$y - 1][$x - 1];
		my $ur = $up && $right && $map[$y - 1][$x + 1];
		my $dl = $down && $left && $map[$y + 1][$x - 1];
		my $dr = $down && $right && $map[$y + 1][$x + 1];
		say STDERR "At $x,$y $plot: $up, $left, $down, $right, $ul, $ur, $dl, $dr";
		for ($up, $left, $down, $right, $ul, $ur, $dl, $dr) {
			$_ = ($_ eq $plot || $_ eq '#');
		}
		say STDERR "At $x,$y $plot: $up, $left, $down, $right, $ul, $ur, $dl, $dr";
		my $here = 0;
		++$here for grep { $_ } (
			!($up || $left),
			!($up || $right),
			!($down || $left),
			!($down || $right),
			($up && $left && !$ul),
			($up && $right && !$ur),
			($down && $left && !$dl),
			($down && $right && !$dr),
		);
		say STDERR "At $x,$y is $here corners";
		$corner += $here;
		push @q, [$x, $y - 1] if $up;
		push @q, [$x, $y + 1] if $down;
		push @q, [$x + 1, $y] if $right;
		push @q, [$x - 1, $y] if $left;
	}
	for my $line (@map) {
		$_ = ' ' for grep /#/, @$line;
	}
	say STDERR "Region $region with area $area and sides $corner";
	$score += ($area * $corner);
}

say $score;
