#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %cube_on;

sub assert { shift or Carp::confess "ASSERT FAIL"; }

sub make_cube ($xlo, $xhi, $ylo, $yhi, $zlo, $zhi) {
	assert $xlo <= $xhi;
	assert $ylo <= $yhi;
	assert $zlo <= $zhi;
	return "$xlo:$xhi:$ylo:$yhi:$zlo:$zhi";
}

sub parse_cube ($cube) {
	assert ((my @c = split /:/, $cube) == 6);
	return map { 0 + $_ } @c;
}

sub cube_volume ($cube) {
	my ($x1, $x2, $y1, $y2, $z1, $z2) = parse_cube($cube);
	my $dx = ($x2 - $x1) + 1;
	my $dy = ($y2 - $y1) + 1;
	my $dz = ($z2 - $z1) + 1;
	return $dx * $dy * $dz;
}

# These three operations splits a cuboid into two along a given X, Y, or Z plane.
# This splits a cube on the "right" edge of the indicated X boundary, such that the "left" cube is from $xlo to ($x)
# and the "right" cube is from ($x + 1) to $xhi
# The return value is the two resulting cubes.
sub x_split ($cube, $x) {
	my ($x1, $x2, $y1, $y2, $z1, $z2) = parse_cube($cube);
	if ($x < $x1 || $x >= $x2) {
		# Return cube unchanged if splitting before the left edge of the cube or at or past the right edge.
		#say STDERR "Split $cube on X=$x : no split";
		return $cube;
	}
	my $newcube_l = make_cube $x1, $x, $y1, $y2, $z1, $z2;
	my $newcube_r = make_cube $x + 1, $x2, $y1, $y2, $z1, $z2;
	#say STDERR "Split $cube on X=$x to [ $newcube_l , $newcube_r ]";
	return $newcube_l, $newcube_r;
}
sub y_split ($cube, $y) {
	my ($x1, $x2, $y1, $y2, $z1, $z2) = parse_cube($cube);
	if ($y < $y1 || $y >= $y2) {
		# Return cube unchanged if splitting behind the aft edge of the cube or at or past on the fore edge.
		#say STDERR "Split $cube on Y=$y : no split";
		return $cube;
	}
	my $newcube_a = make_cube $x1, $x2, $y1, $y, $z1, $z2 ;
	my $newcube_f = make_cube $x1, $x2, ($y + 1), $y2, $z1, $z2;
	#say STDERR "Split $cube on Y=$y : [ $newcube_a , $newcube_f ]";
	return $newcube_a, $newcube_f;
}
sub z_split ($cube, $z) {
	my ($x1, $x2, $y1, $y2, $z1, $z2) = parse_cube($cube);
	if ($z < $z1 || $z >= $z2) {
		# Return cube unchanged if splitting below the bottom edge of the cube or at or past on the top edge.
		#say STDERR "Split $cube on Z=$z : no split";
		return $cube;
	}
	my $newcube_b = make_cube $x1, $x2, $y1, $y2, $z1, $z;
	my $newcube_t = make_cube $x1, $x2, $y1, $y2, ($z + 1), $z2;
	#say STDERR "Split $cube on Z=$z : [ $newcube_b, $newcube_t ]";
	return $newcube_b, $newcube_t;
}
# Performs multi-axis split to split one cube into four (two axes) or eight (three axes).
# A plane defined as "undef" does not split on that plane.
sub xyz_split ($cube, $x, $y, $z) {
	my @cubes = ($cube);
	#printf STDERR "Splitting %s on X=%s, Y=%s, Z=%s : [ ", $cube, $x//"--", $y//"--", $z//"--";
	defined $x and @cubes = map { x_split $_, $x } @cubes;
	defined $y and @cubes = map { y_split $_, $y } @cubes;
	defined $z and @cubes = map { z_split $_, $z } @cubes;
	#say STDERR "@cubes ]";
	return @cubes;
}

# Perform a *double* split. The input argument list is designed to be suitable to use the return value from cubes_overlap below.
sub xyz_dsplit ($cube, $x1, $x2, $y1, $y2, $z1, $z2) {
	my @cubes = ($cube);
	@cubes = map { xyz_split $_, $x1, $y1, $z1; } @cubes;
	@cubes = map { xyz_split $_, $x2, $y2, $z2; } @cubes;
	return @cubes;
}

use constant { YES => !0, NO => !1 };

# Determine if two cubes overlap.
# They do if any vertex of one cube is inside the other. If they aren't, then one face will be "past" its counterpart's opposite face.
# Return value is:
# undef -> The cubes do not overlap.
# An array -> The cubes overlap. The array contains a pair of X planes, Y planes, and Z planes at which the two cubes should be split to isolate the "overlapping" region.
# Order is always left, right, aft, fore, bottom, top (right-hand rule)
# If the left, aft, or fore faces of the cubes are aligned, then that coordinate will be given as 1 less than the shared coordinate (resulting in x/y/z_split doing nothing).
# If the right, fore, or top faces of the cubes are aligned, then that coordinate will be given as equal to that coordinate.
# Note that in the case both cubes are equal, this will result in a split arrangement which will not split the cube at all: the number of cubes returned by xyz_split will be 1.
# If a plane pair is both 'undef' it means the cubes are fully aligned on that plane.
# The return value of this function is suitable for passing to xyz_dsplit for each of the two cubes, thus isolating the overlapping region.
sub cubes_overlap ($cube1, $cube2) {
	my ($x1a, $x2a, $y1a, $y2a, $z1a, $z2a) = parse_cube($cube1);
	my ($x1b, $x2b, $y1b, $y2b, $z1b, $z2b) = parse_cube($cube2);
	my ($xl, $xr, $ya, $yf, $zb, $zt);
	# Solve the obvious "outside" situations.
	# x1a .. x2a .. x1b .. x2b :: no intersection
	# x1b .. x2b .. x1a .. x2a :: no intersection
	return () if $x2a < $x1b || $x2b < $x1a;
	return () if $y2a < $y1b || $y2b < $y1a;
	return () if $z2a < $z1b || $z2b < $z1a;
	# Some overlap configurations:
	# x1a .. x1b .. x2b .. x2a (edge or face intersection, or containment) : split on x1b - 1 and x2b
	# x1a .. x1b .. x2a .. x2b (cornder intersection) : split on x1b - 1 and x2a
	# x1b .. x1a .. x2a .. x2b (a inside b) : split on x1a - 1 and x2a
	# x1b .. x1a .. x2b .. x2a (other corner) : split on x1a - 1 and x2b
	$xl = ($x1a < $x1b ? $x1b : $x1a) - 1;
	$xr = $x2a < $x2b ? $x2a : $x2b;
	$ya = ($y1a < $y1b ? $y1b : $y1a) - 1;
	$yf = $y2a < $y2b ? $y2a : $y2b;
	$zb = ($z1a < $z1b ? $z1b : $z1a) - 1;
	$zt = $z2a < $z2b ? $z2a : $z2b;
	return ($xl, $xr, $ya, $yf, $zb, $zt);
}

# True if $cube2 is completely inside $cube1
sub cube_inside ($cube1, $cube2) {
	my ($x1a, $x2a, $y1a, $y2a, $z1a, $z2a) = parse_cube($cube1);
	my ($x1b, $x2b, $y1b, $y2b, $z1b, $z2b) = parse_cube($cube2);
	return ($x1a <= $x1b <= $x2b <= $x2a && $y1a <= $y1b <= $y2b <= $y2a && $z1a <= $z1b <= $z2b <= $z2a);
}

sub union_cube ($cube) {
	say STDERR "> Union $cube";
	my @toadd = ($cube);
	my %already;
	TOADD: while (defined(my $toadd = shift @toadd)) {
		exists $cube_on{$toadd} and next;
		#say "> Trying to add $toadd";
		$already{$toadd} = 1;
		my @cubes = keys %cube_on;
		for my $c2 (@cubes) {
			if (cube_inside($toadd, $c2)) {
				# Absorb the smaller cube into the larger incoming cube.
				#say STDERR "Absorbing $c2 into $toadd";
				delete $cube_on{$c2};
				push @toadd, $toadd;
				next TOADD;
			}
			#say STDERR "> Checking against $c2";
			if (my @planes = cubes_overlap($toadd, $c2)) {
				#say STDERR "Overlap with $c2 found: [ @planes ]";
				delete $cube_on{$c2};
				my @splexisting = xyz_dsplit $c2, @planes;
				#say "Split existing cube to [ @splexisting ]";
				my @splitadd = xyz_dsplit $toadd, @planes;
				$_ = 1 for @cube_on{@splexisting};
				#say "Split incoming cube to [ @splitadd ]";
				#grep { exists $already{$_} and die "Trying to readd already-tried $_"; } @splitadd;
				push @toadd, @splitadd;
				next TOADD;
			}
		}
		$cube_on{$toadd} = 1;
	}
}

sub subtract_cube ($cube) {
	#say STDERR "> Subtract $cube";
	my %already;
	RESTART: {
		my @cubes = keys %cube_on;
		for my $c2 (@cubes) {
			#say STDERR "> Checking against $c2";
			if (my @planes = cubes_overlap($cube, $c2)) {
				if (exists $already{$c2}) { die; }
				$already{$c2} = 1;
				#say STDERR "Overlap found: [ @planes ]";
				delete $cube_on{$c2};
				my @newcubes = xyz_dsplit $c2, @planes;
				#say STDERR "Post split: [ @newcubes ]";
				@newcubes = grep { ( () = cubes_overlap($_, $cube) ) == 0 } @newcubes;
				#say STDERR "Adding cubes: [ @newcubes ]";
				$_ = 1 for @cube_on{@newcubes};
				redo RESTART;
			}
		}
	}
}

use List::Util ();
while (<>) {
	chomp;
	my ($cmd, $x1, $x2, $y1, $y2, $z1, $z2) = /^\s*(on|off)\s+x\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*,\s*y\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*,\s*z\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$/;

	if ($x2 < -50 || $x1 > 50 || $y2 < -50 || $y1 > 50 || $z2 < -50 || $z1 > 50) { next; }
	if ($x1 < -50) { $x1 = -50; }
	if ($x2 > 50 ) { $x2 = 50; }
	if ($y1 < -50) { $y1 = -50; }
	if ($y2 > 50 ) { $y2 = 50; }
	if ($z1 < -50) { $z1 = -50; }
	if ($z2 > 50 ) { $z2 = 50; }

	my @keys;
	
	my $cube = make_cube $x1, $x2, $y1, $y2, $z1, $z2;

	my $current = List::Util::sum0(map { cube_volume $_ } keys %cube_on);
	my $incoming = cube_volume($cube);

	my $changed;

	if ($cmd eq "on" ) { union_cube $cube; }
	else { subtract_cube $cube; }

	my $newcount = List::Util::sum0(map { cube_volume $_ } keys %cube_on);
	my $change = abs($newcount - $current);
	say STDERR "Turned $cmd region $cube ( $change / $incoming cubes changed )";
}


my $cubect = List::Util::sum0 map { cube_volume $_ } keys %cube_on;

say "Cube on count: $cubect";
