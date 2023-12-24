#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

use bigrat;

my @hail;

BEGIN {
	require constant;
	my $t1 = shift(@ARGV);
	my $t2 = shift(@ARGV);
	if ($t2 < $t1) {
		($t1, $t2) = ($t2, $t1);
	}
	constant->import(TEST_LO => $t1);
	constant->import(TEST_HI => $t2);
}

while (<>) {
	my ($px, $py, $pz, $vx, $vy, $vz) = map { Math::BigRat->new($_) } m/^(\d+), +(\d+), +(\d+) +@ +(-?\d+), +(-?\d+), +(-?\d+)$/;
	defined $px or die "Input error: $_";
	# Per part 1, the z axis can be ignored. I'm sure it'll matter in part 2 though.
	my $hail = {
		px => $px,
		py => $py,
		pz => $pz,
		vx => $vx,
		vy => $vy,
		vz => $vz,
	};
	# A hailstone's position creates a line through the X/Y axis, which can of course be described with the linear equation:
	# A x + B y = C
	# It can also be expressed as the parametric equations:
	# x(t) = vx * t + px
	# y(t) = vy * t + py
	# However, we only need to solve for the basic version.
	$hail->{A} = $vy;
	$hail->{B} = -$vx;
	$hail->{C} = ($vy * $px) + (-$vx * $py);
	# This will be needed to do intersect testing later.
	push @hail, $hail;
}

# Test two lines if the paths cross. If they do, the return value is:
# x, y of the intersect point
# t1 -> the time where l1 passes x, y
# t2 -> the time where l2 passes x, y
# Noteably, if t1 == t2 then the paths collide.
# Returns empty list if the lines don't cross (are parallel).
sub intersect ($l1, $l2) {
	my $det = $l1->{A} * $l2->{B} - $l1->{B} * $l2->{A};
	if ($det == 0) { return (); }
	my $x = ($l2->{B} * $l1->{C} - $l1->{B} * $l2->{C}) / $det;
	my $y = ($l1->{A} * $l2->{C} - $l2->{A} * $l1->{C}) / $det;
	my $t1x = ($x - $l1->{px}) / $l1->{vx};
	my $t1y = ($y - $l1->{py}) / $l1->{vy};
	abs($t1x - $t1y) < 0.00001 or die "Linear x Assert fail (t1=$t1x, $t1y, diff=" . abs($t1x - $t1y) . ")";
	my $t2 = ($x - $l2->{px}) / $l2->{vx};
	abs($t2 - ($y - $l2->{py}) / $l2->{vy}) < 0.00001 or die "Linear y Assert fail";
	return ($x, $y, $t1x, $t2);
}

my $ct = 0;
while (defined(my $l1 = shift(@hail))) {
	for my $l2 (@hail) {
		next if $l1 == $l2;
		my ($x, $y, $t1, $t2) = intersect($l1, $l2);
		#printf STDERR "Hailstone A: %d, %d, %d @ %d, %d, %d\n", $l1->@{qw/px py pz vx vy vz/};
		#printf STDERR "Hailstone B: %d, %d, %d @ %d, %d, %d\n", $l2->@{qw/px py pz vx vy vz/};
		if (defined $x) {
			#printf STDERR "Intersect result: (%f, %f, %f, %f)\n", $x, $y, $t1, $t2;
			if ($x < TEST_LO || $x > TEST_HI || $y < TEST_LO || $y > TEST_HI) {
				#say STDERR "Paths cross outside the test area";
			}
			elsif ($t1 < 0 && $t2 < 0) {
				#say STDERR "Paths crossed in the past for both stones";
			}
			elsif ($t1 < 0) {
				#say STDERR "Path crossed in the past for stone A";
			}
			elsif ($t2 < 0) {
				#say STDERR "Path crossed in the past for stone B";
			}
			else {
				#printf STDERR "Paths cross in the future and inside the test area (x=%d, y=%d)\n", $x, $y;
				++$ct;
			}
			#say STDERR "---";
		}
		else {
			#say STDERR "Paths are parallel";
			#say STDERR "---";
		}
	}
}

say $ct;
