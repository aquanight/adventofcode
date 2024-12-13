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
	my ($sy) = grep { grep { length } $map[$_]->@* } keys @map;
	last unless defined $sy;
	my ($sx) = grep { length $map[$sy][$_] } keys $map[$sy]->@*;
	my $area = 0;
	my $perim = 0;
	my @q = [ $sx, $sy ];
	my $region = $map[$sy][$sx];
	while (@q) {
		my ($x, $y) = (shift @q)->@*;
		my $plot = $map[$y][$x];
		next if $plot eq '#';
		$map[$y][$x] = '#';
		++$area;
		for my $dir (DIRS) {
			my ($dx, $dy) = @$dir;
			my $nx = $x + $dx;
			my $ny = $y + $dy;
			if ($nx < 0 || $nx >= $xw || $ny < 0 || $ny > $#map) {
				++$perim;
				next;
			}
			next if $map[$ny][$nx] eq '#';
			if ($map[$ny][$nx] ne $plot) {
				++$perim;
			}
			else {
				push @q, [ $nx, $ny ];
			}
		}
	}
	for my $line (@map) {
		$_ = '' for grep /#/, @$line;
	}
	say STDERR "Region $region with area $area and perimeter $perim";
	$score += ($area * $perim);
}

say $score;
