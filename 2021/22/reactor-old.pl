#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my %cubes;

while (<>) {
	chomp;
	my ($cmd, $x1, $x2, $y1, $y2, $z1, $z2) = /^\s*(on|off)\s+x\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*,\s*y\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*,\s*z\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$/;

	my @keys;

	for my $x ( $x1 .. $x2 ) {
		next if $x < -50 || $x > 50;
		for my $y ( $y1 .. $y2 ) {
			next if $y < -50 || $y > 50;
			for my $z ( $z1 .. $z2 ) {
				next if $z < -50 || $z > 50;
				my $key = "$x:$y:$z";
				if ($cmd eq "on") {
					$cubes{$key} = 1;
				}
				else {
					delete $cubes{$key};
				}
			}
		}
	}
}

my $cubect = scalar keys %cubes;

say "Cube on count: $cubect";
