#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

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

my sub _tile($x, $y) {
	$x < 0 and return "#";
	$x >= $width and return "#";
	$y < 0 and return "#";
	$y > $#map and return "#";
	return substr($map[$y], $x, 1)
}

my @rts = {
	x => $stx,
	y => $sty,
	visit => {},
	steps => 0,
	split => [ ], # Each time the route splits, a unique identifier is added to this list.
};

my $goal = 0;


my $next_split = 0;

while (@rts) {
	my $rt = shift @rts;
	my ($x, $y, $visit, $steps, $split) = $rt->@{qw/x y visit steps split/};
	# If the split ref was deleted, it's because this route was marked for pruning due to blocked exit intersection, so skip it.
	next unless defined $split;
	if ($visit->{"$x,$y"}) {
		# We've already visited this tile.
		next;
	}
	# Mark as visited
	$visit->{"$x,$y"} = 1;
	if ($y == $#map && $x == $goal_x) {
		# Reached the goal.
		# Prune the remaining routes of all routes that followed the same split route: these paths can't make it back to the goal because the last intersection from the goal is blocked!
		for my $ort (@rts) {
			next unless defined $ort->{split};
			if ($ort->{split}->@* >= $split->@* && List::Util::all { $split->[$_] == $ort->{split}[$_] } 0 .. $split->$#*) {
				delete $ort->{split};
			}
		}
		if ($steps > $goal) {
			$goal = $steps;
			say STDERR "New high score: $goal";
		}
		next;
	}
	# Unfortunately, because we are looking for a path MAXIMUM, no easy "cut off longer paths" option.
	my @newrts;
	# Can we go up?
	if ($y > 0 && _tile($x, $y - 1) ne '#') {
		push @newrts, {
			x => $x,
			y => ($y - 1),
			steps => ($steps + 1)
		};
	}
	# Can we go down?
	if ($y < $#map && _tile($x, $y + 1) ne '#') {
		push @newrts, {
			x => $x,
			y => ($y + 1),
			steps => ($steps + 1)
		};
	}
	# Can we go left?
	if ($x > 0 && _tile($x - 1, $y) ne '#') {
		push @newrts, {
			x => ($x - 1),
			y => $y,
			steps => ($steps + 1)
		}
	}
	# Can we go right?
	if ($x < ($width - 1) && _tile($x + 1, $y) ne '#') {
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
		$newrts[0]->{split} = $split;
	}
	else {
		$_->{visit} = { %$visit } for @newrts;
		++$next_split;
		$_->{split} = [ @$split, $next_split ] for @newrts;
	}
	unshift @rts, @newrts;
}

say $goal;
