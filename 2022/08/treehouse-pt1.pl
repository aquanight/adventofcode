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



my @visible;

for my $r (0 .. $#grid) {
	my $lheight = -1;
	my $rheight = -1;
	for my $c (1 .. $width) {
		my \$ltree = \$grid[$r][$c - 1];
		my \$rtree = \$grid[$r][$width - $c];
		if ($ltree > $lheight) {
			$visible[$r][$c - 1] = 1;
			$lheight = $ltree;
		}
		if ($rtree > $rheight) {
			$visible[$r][$width - $c] = 1;
			$rheight = $rtree;
		}
	}
}

for my $c (0 .. ($width - 1)) {
	my $theight = -1;
	my $bheight = -1;
	for my $r (1 .. @grid) {
		my \$ttree = \$grid[$r - 1][$c];
		my \$btree = \$grid[@grid - $r][$c];
		if ($ttree > $theight) {
			$visible[$r - 1][$c] = 1;
			$theight = $ttree;
		}
		if ($btree > $bheight) {
			$visible[@grid - $r][$c] = 1;
			$bheight = $btree;
		}
	}
}

my $score = List::Util::sum0 map { List::Util::sum0 map { $_ ? 1 : 0 } @$_ } @visible;

say $score;
