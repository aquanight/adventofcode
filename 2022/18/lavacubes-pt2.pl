#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %cubes;

my ($min_x, $min_y, $min_z);
my ($max_x, $max_y, $max_z);

while (<>) {
	chomp;
	my ($x, $y, $z) = split /\s*,\s*/;

	$min_x = defined($min_x) && $min_x < $x ? $min_x : $x;
	$max_x = defined($max_x) && $max_x > $x ? $max_x : $x;
	$min_y = defined($min_y) && $min_y < $y ? $min_y : $y;
	$max_y = defined($max_y) && $max_y > $y ? $max_y : $y;
	$min_z = defined($min_z) && $min_z < $z ? $min_z : $z;
	$max_z = defined($max_z) && $max_z > $z ? $max_z : $z;

	$cubes{"$x,$y,$z"} = 1;
}

--$min_x;
--$min_y;
--$min_z;
++$max_x;
++$max_y;
++$max_z;

my $score = 0;

my %seen;

my @next = ($min_x, $min_y, $min_z);

while (@next > 0) {
	my ($x, $y, $z) = splice @next, 0, 3;
	next if $x < $min_x || $x > $max_x;
	next if $y < $min_y || $y > $max_y;
	next if $z < $min_z || $z > $max_z;
	my $check = sprintf "%d,%d,%d", $x, $y, $z;
	if ($cubes{$check}) {
		++$score;
		next;
	}
	next if $seen{$check};
	$seen{$check} = 1;
	push @next, $x + 1, $y, $z;
	push @next, $x - 1, $y, $z;
	push @next, $x, $y + 1, $z;
	push @next, $x, $y - 1, $z;
	push @next, $x, $y, $z + 1;
	push @next, $x, $y, $z - 1;
}

say $score;


__DATA__

my $test_x = $min_x - 1;
my $test_y = $min_y - 1;
my $test_z = $min_z - 1;

# Points we've already tested, 0 if it's inside, 1 if it's outside
my %outside_cache;

# Try to do this nonrecursively
sub is_outside ($from_x, $from_y, $from_z) {
	my %seen;
	my @check = ($from_x, $from_y, $from_z);
	my $result = !1;
	while (@check) {
		my ($x, $y, $z) = splice @check, 0, 3;
		my $check = sprintf "%d,%d,%d", $x, $y, $z;
		#print STDERR "$check : ";
		if ($cubes{$check}) {
			#say STDERR "cube";
			next;
		}
		if ($seen{$check}) {
			#say STDERR "repeat";
			next;
		}
		$seen{$check} = 1;
		my $cache = $outside_cache{$check};
		if (defined($cache)) {
			#say STDERR "cached";
			next unless $cache;
			$result = 1;
			last;
		}
		if ($x == $min_x && $y == $min_y && $z == $min_z) {
			#say STDERR "target";
			$result = 1;
			last;
		}
		#say STDERR "searching";
		push @check, $x - 1, $y, $z;
		push @check, $x, $y - 1, $z;
		push @check, $x, $y, $z - 1;
		push @check, $x + 1, $y, $z;
		push @check, $x, $y + 1, $z;
		push @check, $x, $y, $z + 1;
	}
	# Remember this result for every space we tested.
	for my $seen (keys %seen) { $outside_cache{$seen} = 1; }
	#say STDERR "Result for $from_x, $from_y, $from_z : [$result]";
	return $result;
}

my $filled = 0;
for my $x ($min_x .. $max_x) {
	for my $y ($min_y .. $max_y) {
		for my $z ($min_z .. $max_z) {
			next if $cubes{"$x,$y,$z"};
			next if is_outside($x, $y, $z);
			++$filled;
			#print STDERR "Filling $x,$y,$z";
			$cubes{"$x,$y,$z"} = 1;
		}
	}
}

say STDERR "Filled $filled interior spaces";

my $score = 0;

my @test = (
	1, 0, 0,
	-1, 0, 0,
	0, 1, 0,
	0, -1, 0,
	0, 0, 1,
	0, 0, -1,
);

for my $cube (keys %cubes) {
	my ($x, $y, $z) = split /,/, $cube;
	next unless $cubes{$cube};
	print STDERR "Cube x=$x, y=$y, z=$z :";
	my $sides = 0;
	for (my $tix = 0; $tix < @test; $tix += 3) {
		my ($dx, $dy, $dz) = @test[$tix .. (2 + $tix)];
		my $check = sprintf("%d,%d,%d", ($x + $dx), ($y + $dy), ($z + $dz));
		$cubes{$check} or ++$sides;
	}
	say STDERR " $sides sides not adjacent";
	#assert $sides < 6;
	$score += $sides;

}

say $score;
