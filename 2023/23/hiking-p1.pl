#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;
my $width;

while (<>) {
	chomp;
	/^[\.\#\<\>v\^]+$/ or die "Input error: $_";
	push @map, $_;
	$width //= length;
}

my $sty = 0;
my $stx;
if ($map[0] =~ /\./) {
	$stx = $-[0];
}
else {
	die "Input error - no starting point";
}
my $goal_x;
if ($map[-1] =~ /\./) {
	$goal_x = $-[0];
}
else {
	die "Input error - cannot find goal tile";
}

my @rts = {
	x => $stx,
	y => $sty,
	visit => {},
	steps => 0,
};

my $goal = 0;

my sub _tile($x, $y) { substr($map[$y], $x, 1) }

while (@rts) {
	my $rt = shift @rts;
	my ($x, $y, $visit, $steps) = $rt->@{qw/x y visit steps/};
	if ($visit->{"$x,$y"}) {
		# We've already visited this tile.
		next;
	}
	# Mark as visited
	$visit->{"$x,$y"} = 1;
	if ($y == $#map && $x == $goal_x) {
		# Reached the goal.
		$steps > $goal and $goal = $steps;
		next;
	}
	# Unfortunately, because we are looking for a path MAXIMUM, no easy "cut off longer paths" option.
	my @newrts;
	# Can we go up?
	if ($y > 0 && _tile($x, $y - 1) !~ m/[\#v]/) {
		push @newrts, {
			x => $x,
			y => ($y - 1),
			steps => ($steps + 1)
		};
	}
	# Can we go down?
	if ($y < $#map && _tile($x, $y + 1) !~ m/[\#\^]/) {
		push @newrts, {
			x => $x,
			y => ($y + 1),
			steps => ($steps + 1)
		};
	}
	# Can we go left?
	if ($x > 0 && _tile($x - 1, $y) !~ m/[\#\>]/) {
		push @newrts, {
			x => ($x - 1),
			y => $y,
			steps => ($steps + 1)
		}
	}
	# Can we go right?
	if ($x < ($width - 1) && _tile($x + 1, $y) !~ m/[\#\<]/) {
		push @newrts, {
			x => ($x + 1),
			y => $y,
			steps => ($steps + 1)
		};
	}
	# Remove any option we already visisted:
	@newrts = grep { my ($_x, $_y) = $_->@{qw/x y/}; !$visit->{"$_x,$_y"} } @newrts;
	next unless @newrts; # No options left, move on.
	# If there is only one option, we can reuse the visited hash. Otherwise we must clone it.
	if (@newrts == 1) {
		$newrts[0]->{visit} = $visit;
	}
	else {
		$_->{visit} = { %$visit } for @newrts;
	}
	push @rts, @newrts;
}

say $goal;
