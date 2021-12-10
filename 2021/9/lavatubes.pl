#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use List::Util ();

my @hmap;

while (<>) {
	chomp;
	/^\d+$/ or die "Invalid input";
	push @hmap, $_;
}

sub height ($x, $y) {
	if ($y < 0 || $y > $#hmap) { return; }
	my $r = $hmap[$y];
	if ($x < 0 || $x >= length($r)) { return; }
	0 + substr($r, $x, 1);
}

sub neighbors ($x, $y) {
	# height returns empty list if we go off the edge.
	my @r = (height($x - 1, $y), height($x + 1, $y), height($x, $y - 1), height($x, $y + 1));
	return @r;
}

sub is_low ($x, $y) {
	my $h = height($x, $y);
	my @n = neighbors($x, $y);
	return List::Util::all { $h < $_ } @n;
}

my $risk = 0;

for my $y (0 .. $#hmap) {
	for my $x (0 .. length($hmap[$y]) - 1) {
		if (is_low($x, $y)) {
			my $h = height($x, $y);
			say STDERR "Low point at ($x, $y) : $h";
			$risk += (1 + $h);
		}
	}
}

say "Total risk value is $risk";
