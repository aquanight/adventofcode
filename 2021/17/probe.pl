#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

my ($txmin, $txmax, $tymin, $tymax) = (<> =~ /^\s*target\s+area\s*:\s*x\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*,\s*y\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$/);

say "Target: X [ $txmin .. $txmax ] Y [ $tymin .. $tymax ]";

my $besty_init;
my $besty_height;

sub triangle ($x) { $x * ($x + 1) / 2; }

# For the Y aspect, finding the peak height is a simple triangle number
# but we also have to determine if the Y value "overshoots" the target.
sub is_tri ($n) { $n < 0 and Carp::confess("wut");  my $r = sqrt(8 * $n + 1); $r == int($r); }
sub tri_root ($n) { $n < 0 and Carp::confess("wut"); (sqrt(8 * $n + 1) - 1) / 2; }
# tri_root finds the "triangle root" and is_tri tells if a number is triangular.
# Basically we take our peak height, subtract each bound of the target zone.
# If either result is a triangle number then we'll land on the edge of the target zone.
# If the results have triangle roots that are on opposite sides of an integer, then there's
# a point we'll be inside the target zone.
# Otherwise, we'll miss the target.
sub is_hit ($from, $min, $max) {
	my $tri_min = abs($from - $min);
	my $tri_max = abs($from - $max);
	if ($tri_max < $tri_min) {
		($tri_min, $tri_max) = ($tri_max, $tri_min);
	}
	is_tri($tri_min) and return 1;
	is_tri($tri_max) and return 1;
	return int(tri_root($tri_min)) != int(tri_root($tri_max));
}

if (is_hit 0, $txmin, $txmax) {
	say STDERR "Free X search";
	# We can forget about X and just try to dial in Y.
	for my $vy ( 0 .. 100_000 ) {
		my $peak = triangle $vy;
		say STDERR "Peak: $peak";
		if (defined($besty_height) && $peak < $besty_height) {
			next;
		}
		if (is_hit($peak, $tymin, $tymax)) {
			$besty_height = $peak;
			$besty_init = $vy;
		}
	}
}
else {
	...;
	# Y bound is tightly constrained due to no settling in the X zone.
	# Must first determine which X solutions will "touch" the X range...
	# $vxmin gives the most possible steps to get a good arc
	my $trimax = triange($txmax);
	my @dx = map { $trimax - triangle($_) } reverse(0 .. $txmax);
	my @vxcand;
	for my $vx (reverse 0 .. $txmax) {
		if (List::Util::any { $txmin <= $_ <= $txmax } @dx) {
			push @vxcand, $vx;
		}
		shift @vxcand;
		$_ -= $vx for @vxcand;
	}
}


say "Best Y height: $besty_height";
say "Best Y speed : $besty_init";
