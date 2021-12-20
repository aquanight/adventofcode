#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use constant SIN90 => 1;
use constant COS90 => 0;

# Identity transform
use constant ID => [1, 0, 0, 0,   0, 1, 0, 0,   0, 0, 1, 0,   0, 0, 0, 1];

# Each of these rotates the matrix 1/4 turn (90 degree) along a particular axis.
use constant RX => [1, 0, 0, 0,   0, COS90, -SIN90, 0,   0, SIN90, COS90, 0,   0, 0, 0, 1];
use constant RY => [COS90, 0, SIN90, 0,   0, 1, 0, 0,   -SIN90, 0, COS90, 0,   0, 0, 0, 1];
use constant RZ => [COS90, -SIN90, 0, 0,  SIN90, COS90, 0, 0,    0, 0, 1, 0,   0, 0, 0, 1];

sub make_translate ($dx, $dy, $dz) {
	return [1, 0, 0, $dx,   0, 1, 0, $dy,   0, 0, 1, $dz,   0, 0, 0, 1];
}

# Perform transformation of a point, *or* by provided a 2nd xfrm matrix, combine two transformation matrices.
# When combining matrices vix xfrm($x, $y) the resultiing matrix is the result of applying $y then $x.
# You can combine multiple matrices together, but only one point (at the end) is allowed.
sub xfrm {
	my $result = shift;
	while (@_) {
		my $xfrm = $result;
		my $point = shift;
		ref $xfrm or Carp::confess 'Invalid argument';
		ref $point or Carp::confess 'Invalid argument';
		@$xfrm == 16 or Carp::confess 'Invalid transform matrix';

		$result = [];

		if (@$point == 4) {
			$#$result = 3;
			$result->[0] = ($xfrm->[0] * $point->[0]) + ($xfrm->[1] * $point->[1]) + ($xfrm->[2] * $point->[2]) + ($xfrm->[3] * $point->[3]);
			$result->[1] = ($xfrm->[4] * $point->[0]) + ($xfrm->[5] * $point->[1]) + ($xfrm->[6] * $point->[2]) + ($xfrm->[7] * $point->[3]);
			$result->[2] = ($xfrm->[8] * $point->[0]) + ($xfrm->[9] * $point->[1]) + ($xfrm->[10] * $point->[2]) + ($xfrm->[11] * $point->[3]);
			$result->[3] = ($xfrm->[12] * $point->[0]) + ($xfrm->[13] * $point->[1]) + ($xfrm->[14] * $point->[2]) + ($xfrm->[15] * $point->[3]);
			die "Unexpected point in matrix combination" if @_;
		}
		elsif (@$point == 16) {
			$#$result = 15;
			$result->[0] = ($xfrm->[0] * $point->[0]) + ($xfrm->[1] * $point->[4]) + ($xfrm->[2] * $point->[8]) + ($xfrm->[3] * $point->[12]);
			$result->[1] = ($xfrm->[0] * $point->[1]) + ($xfrm->[1] * $point->[5]) + ($xfrm->[2] * $point->[9]) + ($xfrm->[3] * $point->[13]);
			$result->[2] = ($xfrm->[0] * $point->[2]) + ($xfrm->[1] * $point->[6]) + ($xfrm->[2] * $point->[10]) + ($xfrm->[3] * $point->[14]);
			$result->[3] = ($xfrm->[0] * $point->[3]) + ($xfrm->[1] * $point->[7]) + ($xfrm->[2] * $point->[11]) + ($xfrm->[3] * $point->[15]);
			$result->[4] = ($xfrm->[4] * $point->[0]) + ($xfrm->[5] * $point->[4]) + ($xfrm->[6] * $point->[8]) + ($xfrm->[7] * $point->[12]);
			$result->[5] = ($xfrm->[4] * $point->[1]) + ($xfrm->[5] * $point->[5]) + ($xfrm->[6] * $point->[9]) + ($xfrm->[7] * $point->[13]);
			$result->[6] = ($xfrm->[4] * $point->[2]) + ($xfrm->[5] * $point->[6]) + ($xfrm->[6] * $point->[10]) + ($xfrm->[7] * $point->[14]);
			$result->[7] = ($xfrm->[4] * $point->[3]) + ($xfrm->[5] * $point->[7]) + ($xfrm->[6] * $point->[11]) + ($xfrm->[7] * $point->[15]);
			$result->[8] = ($xfrm->[8] * $point->[0]) + ($xfrm->[9] * $point->[4]) + ($xfrm->[10] * $point->[8]) + ($xfrm->[11] * $point->[12]);
			$result->[9] = ($xfrm->[8] * $point->[1]) + ($xfrm->[9] * $point->[5]) + ($xfrm->[10] * $point->[9]) + ($xfrm->[11] * $point->[13]);
			$result->[10] = ($xfrm->[8] * $point->[2]) + ($xfrm->[9] * $point->[6]) + ($xfrm->[10] * $point->[10]) + ($xfrm->[11] * $point->[14]);
			$result->[11] = ($xfrm->[8] * $point->[3]) + ($xfrm->[9] * $point->[7]) + ($xfrm->[10] * $point->[11]) + ($xfrm->[11] * $point->[15]);
			$result->[12] = ($xfrm->[12] * $point->[0]) + ($xfrm->[13] * $point->[4]) + ($xfrm->[14] * $point->[8]) + ($xfrm->[15] * $point->[12]);
			$result->[13] = ($xfrm->[12] * $point->[1]) + ($xfrm->[13] * $point->[5]) + ($xfrm->[14] * $point->[9]) + ($xfrm->[15] * $point->[13]);
			$result->[14] = ($xfrm->[12] * $point->[2]) + ($xfrm->[13] * $point->[6]) + ($xfrm->[14] * $point->[10]) + ($xfrm->[15] * $point->[14]);
			$result->[15] = ($xfrm->[12] * $point->[3]) + ($xfrm->[13] * $point->[7]) + ($xfrm->[14] * $point->[11]) + ($xfrm->[15] * $point->[15]);
		}
	}

	return $result;
}

sub make_coord ($x, $y, $z) { [ 0+$x, 0+$y, 0+$z, 1 ] }

# Right hand rule: +x is "right", +y is "out", +z is "up".
# The rotation Rn rotates counterclockwise when the +n axis faces the observer.
# This means RX rotates from "out" to "up", RY rotates "right" to "down", and RZ rotates "right" to "out"
# Each rotation swaps the two other axes and also flips axis that was in to the "right" of it (in that y is "right" of x, z is "right" of y, x is "right" of z)
# After RX: swap y with z, flip former y
# After RY: swap x with z, flip former z
# After RZ: swap x with y, flip former x
# Identities:
# RX RX: flip y and z
# RY RY: flip x and y
# RZ RZ: flip x and z
# Apply in right to left order

# The 24 orientations can the be determined by mapping "absolute" axes to the rotated "relative" axes:
# They can be defined by picking which of the 6 axes becomes +x (and its opposite -x), then which of the remaining 4 becomes +y (then only one possible axis can be +z)
# (x, y, z) is what axis moved to +x, +y, +z after the rotation
my %orientations = (
	# (+x, ...
	"+x:+y:+z" => ID,			# (+x, +y, +z)
	"+x:-y:-z" => xfrm(RX, RX),		# (+x, -y, -z)
	"+x:+z:-y" => RX,			# (+x, +z, -y)
	"+x:-z:+y" => xfrm(RX, RX, RX),	# (+x, -z, +y)
	# (-x, ...
	"-x:+y:-z" => xfrm(RY, RY),		# (-x, +y, -z)
	"-x:-y:+z" => xfrm(RZ, RZ),		# (-x, -y, +z)
	"-x:+z:+y" => xfrm(RX, RY, RY),	# (-x, +z, +y)
	"-x:-z:-y" => xfrm(RX, RZ, RZ),	# (-x, -z, -y)
	# (+y, ...
	"+y:+x:-z" => xfrm(RZ, RX, RX),	# (+y, +x, -z)
	"+y:-x:+z" => RZ,			# (+y, -x, +z)
	"+y:+z:+x" => xfrm(RY, RZ),		# (+y, +z, +x)
	"+y:-z:-x" => xfrm(RY, RY, RY, RZ),	# (+y, -z, -x)
	# (-y, ...
	"-y:+x:+z" => xfrm(RZ, RZ, RZ),	# (-y, +x, +z)
	"-y:-x:-z" => xfrm(RX, RX, RZ),	# (-y, -x, -z)
	"-y:+z:-x" => xfrm(RX, RY, RY, RY),	# (-y, +z, -x) 
	"-y:-z:+x" => xfrm(RX, RX, RX, RY),	# (-y, -z, +x)
	# (+z, ...
	"+z:+x:+y" => xfrm(RY, RZ, RY, RZ),	# (+z, +x, +y)
	"+z:-x:-y" => xfrm(RY, RY, RY, RX),	# (+z, -x, -y)
	"+z:+y:-x" => xfrm(RY, RY, RY),	# (+z, +y, -x)
	"+z:-y:+x" => xfrm(RX, RX, RY),	# (+z, -y, +x)
	# (-z, ...
	"-z:+x:-y" => xfrm(RZ, RZ, RZ, RY),	# (-z, +x, -y)
	"-z:-x:+y" => xfrm(RZ, RY),		# (-z, -x, +y)
	"-z:+y:+x" => RY,			# (-z, +y, +x)
	"-z:-y:-x" => xfrm(RY, RX, RX),	# (-z, -y, -x)
);

sub prettymat ($mat) { join(" ", map { sprintf "%2d", $_ } @$mat) }

sub vec_eq ($c1, $c2) {
	my ($x1, $y1, $z1) = @$c1;
	my ($x2, $y2, $z2) = @$c2;
	return ($x1 == $x2) && ($y1 == $y2) && ($z1 == $z2);
}

sub xyz ($c) {
	ref $c or Carp::confess "Bad reference";
	sprintf "%s,%s,%s", $c->@[0 .. 2]
}

# Debug the orientations and make sure I got them right:
{
	my $xu = make_coord(1, 0, 0);
	my $yu = make_coord(0, 1, 0);
	my $zu = make_coord(0, 0, 1);
	my %expect = (
		"+x" => make_coord(1, 0, 0),
		"-x" => make_coord(-1, 0, 0),
		"+y" => make_coord(0, 1, 0),
		"-y" => make_coord(0, -1, 0),
		"+z" => make_coord(0, 0, 1),
		"-z" => make_coord(0, 0, -1)
	);
	next;
}

my %scanners;
my $current;

my %xfrm;

sub distsqr ($c1, $c2) {
	my ($x1, $y1, $z1) = @$c1;
	my ($x2, $y2, $z2) = @$c2;
	my $dx = $x2 - $x1;
	my $dy = $y2 - $y1;
	my $dz = $z2 - $z1;
	return ($dx ** 2) + ($dy ** 2) + ($dz ** 2);
}

sub get_vec ($c1, $c2) {
	my ($x1, $y1, $z1) = @$c1;
	my ($x2, $y2, $z2) = @$c2;
	my $dx = $x1 - $x2;
	my $dy = $y1 - $y2;
	my $dz = $z1 - $z2;
	return make_coord($dx, $dy, $dz);
}

while (<>) {
	chomp;
	if (my ($scnid) = /^\s*---\s*scanner\s+(\d+)\s+---\s*$/) {
		$current = ($scanners{$scnid} = [ { } ]);
	}
	elsif (my ($bx, $by, $bz) = /^\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*$/) {
		my $beacon = make_coord($bx, $by, $bz);
		push $current->@*, $beacon;
		++($current->[0]{xyz $beacon});
	}
}

# Debug reading of the scanners
sub dump_scanners {
	for my $scnid ( keys %scanners  ) {
		my \@c = $scanners{$scnid};
		say STDERR "Scanner #$scnid";
		printf STDERR "Beacons: [ %s ]\n", join(" ],[ ", map { prettymat $_ } @c[1 .. $#c]);
	}
}

# Now attempt to find overlapping scanners.
while (scalar keys %scanners > 1) {
	#dump_scanners;
	my %dist;
	for my $scnid (keys %scanners) {
		my $scn = $scanners{$scnid};
		for my $i ( 1 .. $#$scn ) {
			for my $j ( ($i + 1) .. $#$scn ) {
				my ($c1, $c2) = $scn->@[$i, $j];
				my $dist = distsqr($c1, $c2);
				push $dist{$dist}->@*, [ $scnid, $c1, $c2 ];
			}
		}
	}

	use constant DEBUG_L => -1;
	use constant DEBUG_R => 4;

	my %map;
	for my $dist (sort { $a <=> $b } keys %dist) {
		my $p = $dist{$dist};
		next if @$p < 2;
		for my $i (0 .. $#$p) {
			for my $j ( ($i + 1) .. $#$p ) {
				my ($l, $r) = $p->@[$i, $j];
				($l, $r) = ($r, $l) if $l->[0] > $r->[0];
				my ($lid, $rid) = ($l->[0], $r->[0]);
				next if $lid == $rid;
				my $v1 = get_vec($l->[1], $l->[2]);
				my $v2 = get_vec($r->[1], $r->[2]);
				my $v2alt = get_vec($r->[2], $r->[1]);
				if ($lid == DEBUG_L && $rid == DEBUG_R) {
					printf STDERR "From $lid : $rid : l1 [ %s ] l2 [ %s ] r1 [ %s ] r2 [ %s ], v1 [ %s ], v2 [ %s ], v2alt [ %s ]\n", xyz($l->[1]), xyz($l->[2]), xyz($r->[1]), xyz($r->[2]), xyz($v1), xyz($v2), xyz($v2alt);
				}
				for my $rot (sort keys %orientations) {
					my $or = $orientations{$rot};
					my $v2r = xfrm($or, $v2);
					my $v2ralt = xfrm($or, $v2alt);
					unless (vec_eq($v2r, $v1) || vec_eq($v2ralt, $v1)) {
						if ($lid == DEBUG_L && $rid == DEBUG_R) {
							printf "\tRejecting rotation $rot: v2r [ %s ] v2ralt [ %s ]\n", xyz($v2r), xyz($v2ralt);
						}
						next;
					}
					my $start1 = $l->[1];
					my $start2 = vec_eq($v2r, $v1) ? $r->[1] : $r->[2];
					my $end2 = vec_eq($v2r, $v1) ? $r->[2] : $r->[1];
					my $s2rot = xfrm($or, $start2);
					my $e2rot = xfrm($or, $end2);
					my $delta = get_vec($start1, $s2rot);
					++$map{"$lid : $rid"}{sprintf("%s,%s,%s,%s", $rot, $delta->@[0, 1, 2])};
					if ($lid == DEBUG_L && $rid == DEBUG_R) {
						printf STDERR "\t Match Rotation: %s, v2r [ %s ], v2ralt [ %s ], start1 [ %s ], start2 [ %s ], end2 [ %s ], s2rot [ %s ], e2rot [ %s ], delta [ %s ]\n",
							$rot, map { xyz $_ } ($v2r, $v2ralt, $start1, $start2, $end2, $s2rot, $e2rot, $delta);
					}
				}
			}
		}
	}
	{
		for my $i (sort keys %map) {
			print STDERR "TF = $i\n";
			for my $map (sort keys $map{$i}->%*) {
				print STDERR "\tMap = $map ";
				my $ct = $map{$i}{$map};
				say STDERR "Count = $ct";
			}
		}
	}

	my ($bestct, $bestTF, $bestmap) = (0);
	for my $TF (sort keys %map) {
		my $v = $map{$TF};
		my ($t, $f) = split / : /, $TF;
		for my $map (sort keys %$v) {
			my $count = $v->{$map};
			($bestct, $bestTF, $bestmap) = ($count, $TF, $map) if ($count > $bestct);
		}
	}

	say STDERR "Best Map: To/From: $bestTF, mapped $bestmap, count $bestct";

	die "And it's awful" unless $bestct > 11;

	my ($T, $F) = split / : /, $bestTF;
	my ($or, $delta) = do {
		my ($addr, $x, $y, $z) = split /,/, $bestmap;
		my $aref = $orientations{$addr};
		my $dv = make_translate($x, $y, $z); # Make the delta into a translation matrix
		($aref, $dv);
	};
	my $xfrm = $xfrm{$T}{$F} = xfrm($delta, $or);
	my \@prior = $scanners{$T};
	my \%tohas = $prior[0];
	my @defer;
	for my $coord (keys $scanners{$F}[0]->%*) {
		my $c = make_coord split /,/, $coord;
		my $rc = xfrm($xfrm, $c);
		unless ($tohas{xyz $rc}) {
			push @defer, $rc;
			push @prior, $rc;
		}
	}
	++$tohas{xyz $_} for @defer;

	delete $scanners{$F};

	printf STDERR "\tAnd then there were %d\n", scalar(keys %scanners);
}

my ($scnid) = keys %scanners;

say STDERR "Last remaining scanner is ID $scnid";
say STDERR "It has this many beacons: " . scalar(keys $scanners{$scnid}[0]->%*);

for my $coord (sort keys $scanners{$scnid}[0]->%*) {
	say STDERR "\t$coord";
}

my %xfrmz = (%{delete $xfrm{0}}, 0 => ID);

while (keys %xfrm) {
	for my $id (keys %xfrm) {
		if ($xfrmz{$id}) {
			for my $from (keys $xfrm{$id}->%*) {
				my $base = $xfrm{$id}{$from};
				my $zed = $xfrmz{$id};
				my $xfrm = xfrm($zed, $base);
				$xfrmz{$from} = $xfrm;
			}
			delete $xfrm{$id};
		}
	}
}

say STDERR "Scanner positions:";
for my $id (sort { $a <=> $b } keys %xfrmz) {
	my $xfrm = $xfrmz{$id};
	my $dx = $xfrm->[3];
	my $dy = $xfrm->[7];
	my $dz = $xfrm->[11];
	printf "ID # %d at %d, %d, %d\n", $id, $dx, $dy, $dz;
}

my @scanners = keys %xfrmz;
my $maxdist = 0;
my ($maxfrom, $maxto);
for my $i ( 0 .. $#scanners ) {
	my $xi = $xfrmz{$i};
	for my $j ( ($i + 1) .. $#scanners ) {
		my $xj = $xfrmz{$j};
		my $dx = abs($xi->[3] - $xj->[3]);
		my $dy = abs($xi->[7] - $xj->[7]);
		my $dz = abs($xi->[11] - $xj->[11]);
		my $dist = $dx + $dy + $dz;
		if ($dist > $maxdist ) {
			$maxdist = $dist;
			$maxfrom = $i;
			$maxto = $j;
		}
	}
}
say "Longest distance: $maxdist ($maxfrom - $maxto)";
