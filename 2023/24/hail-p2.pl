#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

use bigrat;

my @hail;

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
	push @hail, $hail;
}

# Rock has position pR and velocity vR
# Each stone N has position p[N] and velocity v[N]
# There exists some t[N} which is the time rock intersects the hailstone N.
# Therefore, pR + vR*t[N] = p[N] + t[N]*v[N]
# Rearrange:
# pR - p[N] = -t[N] * (vR - v[N])
# Vector (pR - p[N]) and (v[N] - vR) are parallel (differ by multiplying by a scalar), so their cross-product is 0:
# (pR - p[N]) x (vR - v[N]) == 0
#
# (pR x vR) == (pyR * vzR - pzR * vyR, pzR * vxR - pxR * vzR, pxR * vyR - pyR * vxR)
# Or: (pyR * vzR - pzR * vyR)X + (pzR * vxR - pxR * vzR)Y + (pxR * vyR - pyR * vxR)Z
# These X/Y/Z terms are important because I am going to want to try to isolate for them below, so splitting them out:
# rx = pyR * vzR - pzR * vyR
# ry = pzR * vxR - pxR * vzR
# rz = pxR * vyR - pyR * vxR

# Rock and first line relates pR and vR to p[N] and v[N] as such:
# (pR - p[N]) x (vR - v[N]) == 0
# px' = px[R] - px[N], py' = py[R] - py[N], ...
# {px', py', pz'} x {vx', vy', vz'} == 0
# sx = py' * vz' - pz' * vy'
# sy = pz' * vx' - px' * vz'
# sz = px' * vy' - py' * vx'
# And it should be noted that sx == sy == sz == 0 therefore:
# py' * vz' == pz' * vy'
# pz' * vx' == px' * vz'
# px' * vy' == py' * vx'
# Fill in the THING' definitions:
# (pyR - py[N]) * (vzR - vz[N]) == (pzR - pz[N]) * (vyR - vy[N])
# (pzR - pz[N]) * (vxR - vx[N]) == (pxR - px[N]) * (vzR - vz[N])
# (pxR - px[N]) * (vyR - vy[N]) == (pyR - py[N]) * (vxR - vx[N])
# FOIL:
# pyR * vzR - pyR * vz[N] - py[N] * vzR + py[N] * vz[N] == pzR * vyR - pzR * vy[N] - pz[N] * vyR + pz[N] * vy[N]
# pzR * vxR - pzR * vx[N] - pz[N] * vxR + pz[N] * vx[N] == pxR * vzR - pxR * vz[N] - px[N] * vzR + px[N] * vz[N]
# pxR * vyR - pxR * vy[N] - px[N] * vyR + px[N] * vy[N] == pyR * vxR - pyR * vx[N] - py[N] * vxR + py[N] * vx[N]
# Now attempt to isolate the (pR x vR) terms
# pyR * vzR - pzR * vyR == pyR * vz[N] + py[N] * vzR - py[N] * vz[N] - pzR * vy[N] - pz[N] * vyR + pz[N] * vy[N]
# pzR * vxR - pxR * vzR == pzR * vx[N] + pz[N] * vxR - pz[N] * vx[N] - pxR * vz[N] - px[N] * vzR + px[N] * vz[N]
# pxR * vyR - pyR * vxR == pxR * vy[N] + px[N] * vyR - px[N] * vy[N] - pyR * vx[N] - py[N] + vxR + py[N] * vx[N]
# Now we can equate the line items for one pair of lines, A and B:
# pyR * vz[A] + py[A] * vzR - py[A] * vz[A] - pzR * vy[A] - pz[A] * vyR + pz[A] * vy[A] == pyR * vz[B] + py[B] * vzR - py[B] * vz[B] - pzR * vy[B] - pz[B] * vyR + pz[B] * vy[B]
# pzR * vx[A] + pz[A] * vxR - pz[A] * vx[A] - pxR * vz[A] - px[A] * vzR + px[A] * vz[A] == pzR * vx[B] + pz[B] * vxR - pz[B] * vx[B] - pxR * vz[B] - px[B] * vzR + px[B] * vz[B]
# pxR * vy[A] + px[A] * vyR - px[A] * vy[A] - pyR * vx[A] - py[A] * vxR + py[A] * vx[A] == pxR * vy[B] + px[B] * vyR - px[B] * vy[B] - pyR * vx[B] - py[B] + vxR + py[B] * vx[B]
# Math time:
# pyR * (vz[A] - vz[B]) - vyR * (pz[A] - pz[B]) - pzR * (vy[A] - vy[B]) + vzR * (py[A] * py[B]) == pz[B] * vy[B] - py[B] * vz[B] + py[A] * vz[A] - pz[A] * vy[A]
# -pxR * (vz[A] - vz[B]) + vxR * (pz[A] - pz[B]) + pzR * (vx[A] - vx[B]) - vzR * (px[A] * px[B]) == pz[A] * vx[A] - px[A] * vz[A] - pz[B] * vx[B] + px[B] * vz[B]
# pxR * (vy[A] - vy[B]) - vxR * (py[A] - py[B]) - pyR * (vx[A] - vx[B]) + vyR * (px[A] - px[B]) == py[A] * vx[A] - px[A] * vy[A] - px[B] * vy[B] + py[B] * vx[B]
# Define:
# dpx = px[A] - px[B], dpy = py[A] - py[B], ...
# Rewritten:
# pyR * dvz - vyR * dpz - pzR * dvy + vzR * dpy ==
# Do this twice and we have 6 equations, 6 variables, and it's SOLVIN TIME

unless (@hail >= 3) {
	die "Gonna need more stones to figure this out";
}

my %hA;
my %hB;
my %hC;
for my $r (\%hA, \%hB, \%hC) {
	my $ix = int rand @hail;
	$r->%* = (splice @hail, $ix, 1)->%*;
}
push @hail, \%hA, \%hB, \%hC;

#my \%hA = $hail[0];
#my \%hB = $hail[1];
#my \%hC = $hail[2];

my %dAB;
$dAB{$_} = $hA{$_} - $hB{$_} for qw/px py pz vx vy vz/;
my %dAC;
$dAC{$_} = $hA{$_} - $hC{$_} for qw/px py pz vx vy vz/;

my $ixA = $hA{py} * $hA{vz} - $hA{vy} * $hA{pz};
my $iyA = $hA{pz} * $hA{vx} - $hA{px} * $hA{vz};
my $izA = $hA{px} * $hA{vy} - $hA{py} * $hA{vx};

my $ixB = $hB{py} * $hB{vz} - $hB{vy} * $hB{pz};
my $iyB = $hB{pz} * $hB{vx} - $hB{px} * $hB{vz};
my $izB = $hB{px} * $hB{vy} - $hB{py} * $hB{vx};

my $ixC = $hC{py} * $hC{vz} - $hC{vy} * $hC{pz};
my $iyC = $hC{pz} * $hC{vx} - $hC{px} * $hC{vz};
my $izC = $hC{px} * $hC{vy} - $hC{py} * $hC{vx};

say STDERR "Hailstones sampled:";
printf STDERR "A : [ % 7d, % 7d, % 7d, % 7d, % 7d, % 7d ]\n", @hA{qw/px py pz vx vy vz/};
printf STDERR "B : [ % 7d, % 7d, % 7d, % 7d, % 7d, % 7d ]\n", @hB{qw/px py pz vx vy vz/};
printf STDERR "C : [ % 7d, % 7d, % 7d, % 7d, % 7d, % 7d ]\n", @hC{qw/px py pz vx vy vz/};


# MATRIX ORDER:
# px, vx, py, vy, pz, vz, T
my @matrix = (
	# EQUATION 1: Y/Z, A/B
	[ 0, 0, $dAB{vz}, -$dAB{pz}, -$dAB{vy}, $dAB{py}, $ixA - $ixB ],
	# EQUATION 2: X/Z, A/B
	[ -$dAB{vz}, $dAB{pz}, 0, 0, $dAB{vx}, -$dAB{px}, $iyA - $iyB ],
	# EQUATION 3: X/Y, A/B
	[ $dAB{vy}, -$dAB{py}, -$dAB{vx}, $dAB{px}, 0, 0, $izA - $izB ],
	# 4-6: as above but A/C
	#
	[ 0, 0, $dAC{vz}, -$dAC{pz}, -$dAC{vy}, $dAC{py}, $ixA - $ixC ],
	[ -$dAC{vz}, $dAC{pz}, 0, 0, $dAC{vx}, -$dAC{px}, $iyA - $iyC ],
	[ $dAC{vy}, -$dAC{py}, -$dAC{vx}, $dAC{px}, 0, 0, $izA - $izC ],
);

# Useful matrix operations:
# Row ordering provider, returns the column # of the first non-zero coefficient
# Returns @$row if all columns are zero
sub row_order ($row) {
	for my $colix ( 0 .. $#$row ) {
		if ($row->[$colix] != 0) { return $colix; }
	}
	return scalar @$row;
}

# Returns the first nonzero leading coefficient, or 0 if none.
# As a special case, returns undef, if it would've returned the last cell in the row, and that cell is nonzero. Such a row [ 0 0 0 0 0 0 NZ ] would mean there is no solution.
sub leading_coeff ($row) {
	for my $colix ( 0 .. ($#$row - 1) ) {
		if ($row->[$colix] != 0) { return $row->[$colix]; }
	}
	if ($row->[-1] == 0) { return 0; }
	else { return undef; }
}

say STDERR "Solution matrix (starting point):";
for my $r (@matrix) {
	print STDERR "[";
	for my $c (@$r) {
		printf STDERR  "% 7d ", $c;
	}
	say STDERR "]";
}

# Apply @rto += (@from * $scale);
sub row_add($rfrom, $scale, $rto) {
	$rto->[$_] += $rfrom->[$_] * $scale for 0 .. $#$rfrom;
}

sub wtf($msg) {
	Carp::cluck $msg;
	for my $r (@matrix) {
		print STDERR "[";
		for my $c (@$r) {
			printf STDERR  "% 7d ", $c;
		}
		say STDERR "]";
	}
	die "Assert failure\n";
}

# Now to build the row echelon form:
# What we want to do is at each row, we need to put a row of that order in that slot, then reduce every row BELOW that row to being at least an order below this one.
# Note: we should be able to have a row of the desired order for EVERY row. If we end up skipping an order, we'll have a problem because that means it's a variable we can't solve!
for my $rix ( 0 .. $#matrix ) {
	# Is the row in this position of the correct order?
	my $ord = row_order($matrix[$rix]);
	if ($ord != $rix) {
		# We need to find a row of the correct order, and emplace it below.
		my $swap = List::Util::first { row_order($matrix[$_]) == $rix } ($rix + 1) .. $#matrix;
		defined $swap or wtf "MASSIVE PROBLEM: NO SUITABLE ROW OF REQUIRED ORDER";
		# Swap the rows.
		(@matrix[$rix, $swap]) = (@matrix[$swap, $rix]);
		$ord = row_order($matrix[$rix]);
		$ord == $rix or wtf "WTF";
	}
	my $lc1 = leading_coeff($matrix[$rix]);
	# Now every row AFTER this one needs to be "reduced" in order. Note that there should never be a row of HIGHER order than this one. If it is, we've got a problem.
	for my $other ( ($rix + 1) .. $#matrix) {
		my $oth = row_order($matrix[$other]);
		$oth < $ord and wtf "MASSIVE PROBLEM: REDUCTION FAILURE";
		$oth > $ord and next; # Already reduced, no need to do anything to this row.
		my $lc2 = leading_coeff($matrix[$other]);
		my $factor = -($lc2 / $lc1);
		row_add($matrix[$rix], $factor, $matrix[$other]);
		$matrix[$other][$oth] == 0 or wtf "Reduction failure";
		row_order($matrix[$other]) > $oth or wtf "Reduction failure check #2";
	}
}

say STDERR "Solution matrix (row echelon form):";
for my $r (@matrix) {
	print STDERR "[";
	for my $c (@$r) {
		printf STDERR  "% 7d ", $c;
	}
	say STDERR "]";
}

# Because of the goal of this matrix, we should NOT have any zero rows. If we did, the sorting system above would put them at the bottom so:
unless (List::Util::any { $_ != 0 } $matrix[-1]->@*) {
	wtf "Problem (zero row exists)";
}

# Now for reduced row echelon form: go back through the rows, and remove right-hand entries:
for my $rix ( reverse 0 .. $#matrix ) {
	row_order($matrix[$rix]) == $rix or wtf "Reduction failure?";
	my $coeff = $matrix[$rix]->[$rix];
	# Rescale this row so that the leading coefficient is "one":
	$_ /= $coeff for $matrix[$rix]->@*;
	for my $oth ( 0 .. ($rix - 1) ) {
		# Solve: OTH + RIX*SCALE = 0 (though RX is just 1 now)
		# OTH + SCALE = 0
		# OTH = -SCALE or SCALE = -OTH
		my $scale = -($matrix[$oth]->[$rix]);
		row_add($matrix[$rix], $scale, $matrix[$oth]);
		$matrix[$oth]->[$rix] == 0 or wtf "HOW?";
	}
}

say STDERR "Solution matrix (reduced row echelon form):";
for my $r (@matrix) {
	print STDERR "[";
	for my $c (@$r) {
		printf STDERR  "% 7d ", $c;
	}
	say STDERR "]";
}

my ($rpx, $rvx, $rpy, $rvy, $rpz, $rvz) = map { $_->[-1] } @matrix;

say STDERR "ROCK THROWING POSITION:";
printf STDERR "X = %d, Y = %d, Z = %d\n", $rpx, $rpy, $rpz;
say STDERR "ROCK THROW DIRECTION:";
printf STDERR "dX = %d, dY = %d, dZ = %d\n", $rvx, $rvy, $rvz;

say ($rpx + $rpy + $rpz);
