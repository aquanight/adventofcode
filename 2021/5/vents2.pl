#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my %grid;

while (<>) {
	chomp;

	my ($x1, $y1, $x2, $y2) = /^\s*(\d+)\s*,\s*(\d+)\s*->\s*(\d+)\s*,\s*(\d+)\s*$/ or die "Invalid input";

	if ($x1 == $x2) {
		# Vertical line
		my @y = ($y2 > $y1) ? $y1 .. $y2 : $y2 .. $y1;
		my @keys = map { "$x1,$_" } @y;
		$grid{$_}++ for @keys;
	}
	elsif ($y1 == $y2) {
		# Horizontal line
		my @x = ($x2 > $x1) ? $x1 .. $x2 : $x2 .. $x1;
		my @keys = map { "$_,$y1" } @x;
		$grid{$_}++ for @keys;
	}
	else {
		# Diagonal
		if (abs($x1 - $x2) != abs($y1 - $y2)) { die "Invalid diagonal"; }
		my @x = ($x2 > $x1) ? $x1 .. $x2 : reverse $x2 .. $x1;
		my @y = ($y2 > $y1) ? $y1 .. $y2 : reverse $y2 .. $y1;
		$#x == $#y or die "Uh oh";
		for my $i (0 .. $#x) {
			my $key = "$x[$i],$y[$i]";
			$grid{$key}++;
		}
	}
}

for my $k (sort keys %grid) {
	my $v = $grid{$k};
	say STDERR "$k -> $v";
}

my $overlaps = grep { $_ > 1 } values %grid;

say "Overlaps: $overlaps";
