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
		next;
	}
}

while (my ($k, $v) = each %grid) {
	say STDERR "$k -> $v";
}

my $overlaps = grep { $_ > 1 } values %grid;

say "Overlaps: $overlaps";
