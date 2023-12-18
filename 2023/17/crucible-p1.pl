#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;
my $width;

while (<>) {
	chomp;
	/^\d+$/ or die "Input error";
	push @map, [ split // => $_ ];
	$width //= length;
}

# A state consists of the following parameters:
# x position
# y position
# direction, including the number of steps already moved in that direction
# Each state is associated with the amount of heat lost so far (from entering that state).
# A state ends if either:
# - It has moved four times or more in the same direction
# - It reaches the bottom-right corner
# - It merges with an existing copy of that state with lower heat already
# - It goes off the edge of the grid
# - It reaches a heat loss higher than the heat loss found at the bottom-right corner already.\
# We can't straight-up Dijkstra this because of the restriction on not moving more than 3 times in the same direction.
# This results in a case where a neighboring node would be considered "unconnected" when approached with one path (that already moved three steps) and connected with a different path (that moved only one or two, or entered
# the origin space from a different direction)
# In addition, the starting square has an extra state for the "initial state", though this state can never be revisited.
my %seen;

# The state array is: X, Y, dir (U, L, R, or D), number of consecutive steps (1 after a recent direction change), and heat loss so far
my @states = (
	[ 0, 0, "", 0, 0 ]
);

# Do an naive border crawl to set an initial upper bound.

my $goal_heat = undef;

{
	my $x = 0;
	my $y = 0;
	my $heat = 0;
	my $allow_x = 3;
	my $allow_y = 3;
	until ($x == ($width - 1) && $y == $#map) {
		if ($allow_x > 0 && ($width - 1) - $x > $#map - $y) {
			# Move an X step
			++$x;
			--$allow_x;
			$allow_y = 3;
		}
		elsif ($allow_y > 0) {
			# Move a Y step
			++$y;
			--$allow_y;
			$allow_x = 3;
		}
		elsif ($allow_x > 0) {
			# Can't do any move Y moves but we need more Y moves than X right now.
			if ($x < ($width - 1)) {
				# We still have X moves to do so do one
				++$x;
				--$allow_x;
				$allow_y = 3;
			}
			else {
				# We're at the right edge. Take one step away from it (ugh).
				--$x;
				--$allow_x;
				$allow_y = 3;
			}
		}
		else {
			die "Shouldn't be possible";
		}
		$heat += $map[$y][$x];
	}
	$goal_heat = $heat;
	say STDERR "Horribly ineffecient search sets upper bound at $goal_heat";
}

while (@states) {
	my $state = shift @states;
	my ($x, $y, $dir, $steps, $heat) = @$state;
	#say STDERR "Route: $x, $y, $dir, $steps, $heat";
	# Terminal conditions:
	# It has moved four or more times in the same direction:
	if ($steps > 3) {
		#say STDERR "Route stop - too fast!";
		next;
	}
	# It reaches the bottom-right corner
	if (($x == $width - 1) && ($y == $#map)) {
		if (!defined($goal_heat) || $heat < $goal_heat) {
			$goal_heat = $heat;
		}
		say STDERR "Route stop - goal";
		next;
	}
	# It merges with an existing copy of that state with lower heat already:
	my $key = "$x:$y:${dir}${steps}";
	if (exists $seen{$key}) {
		if ($seen{$key} <= $heat) {
			#say STDERR "Route stop - already seen";
			next;
		}
	}
	# It goes off the edge of the grid
	if ($x < 0 || $x >= $width || $y < 0 || $y > $#map) {
		say STDERR "Route stop - fell off";
		next;
	}
	# It reaches a heat loss higher than the heat loss found at the bottom-right corner already.
	if (defined($goal_heat) && $heat >= $goal_heat) {
		say STDERR "Route stop - too hot";
		next;
	}
	$seen{$key} = $heat;
	if ($y > 0 && $dir ne 'D') {
		push @states, [ $x, $y - 1, "U", ($dir eq "U" ? $steps + 1 : 1), $heat + $map[$y - 1][$x] ];
	}
	if ($y < $#map && $dir ne 'U') {
		push @states, [ $x, $y + 1, "D", ($dir eq "D" ? $steps + 1 : 1), $heat + $map[$y + 1][$x] ];
	}
	if ($x > 0 && $dir ne 'R') {
		push @states, [ $x - 1, $y, "L", ($dir eq "L" ? $steps + 1 : 1), $heat + $map[$y][$x - 1] ];
	}
	if ($x < ($width - 1) && $dir ne 'L') {
		push @states, [ $x + 1, $y, "R", ($dir eq "R" ? $steps + 1 : 1), $heat + $map[$y][$x + 1] ];
	}
}

say $goal_heat;
