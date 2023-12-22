#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;
my $width;

my $steps = shift @ARGV;

while (<>) {
	chomp;
	/^[\.\#S]+$/ or die "Input error";
	push @map, [ map { $_ eq '#' ? -100 : $_ eq 'S' ? 1 : 0 } split //, $_ ];
	$width //= length;
}

sub display_map {
	say STDERR join "\n", map { join("", map { $_ < 0 ? '#' : $_ > 0 ? 'O' : '.' } @$_) . "  " . scalar(grep { $_ > 0 } @$_) } @map;
	say STDERR "---";
}

display_map;

for my $step (1 .. $steps) {
	my @newmap;
	for my $y (0 .. $#map) {
		for my $x (0 .. ($width - 1)) {
			if ($map[$y][$x] < 0) {
				$newmap[$y][$x] = -100;
			}
			elsif ($map[$y][$x] == 0) {
				$newmap[$y][$x] //= 0;
			}
			elsif ($map[$y][$x] > 0) {
				$newmap[$y][$x] //= 0;
				$newmap[$y - 1][$x]++ if $y > 0;
				$newmap[$y + 1][$x]++ if $y < $#map;
				$newmap[$y][$x - 1]++ if $x > 0;
				$newmap[$y][$x + 1]++ if $x < ($width - 1);
			}
		}
	}
	@map = @newmap;
	display_map;
}

use List::Util ();

my $ct = List::Util::sum0 map { scalar grep { $_ > 0 } @$_ } @map;

say $ct;
