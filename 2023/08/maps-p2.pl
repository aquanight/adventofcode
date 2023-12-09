#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $path;

my %nodes;

my @start;

while (<>) {
	if (/^([RL]+)$/) {
		$path = $1;
	}
	elsif (/^(.{3}) += +\((.{3}), +(.{3})\)$/) {
		my $src = $1;
		my $ldst = $2;
		my $rdst = $3;
		exists $nodes{$src} and die "Duplicate $src";
		$nodes{$src}{L} = $ldst;
		$nodes{$src}{R} = $rdst;
		if ($src =~ /A$/) { push @start, $src; }
	}
	elsif (/^ *$/) { }
	else {
		die "Input error";
	}
}

my %seen;

my @first;
my @loop;

use List::Util ();

my $step = 0;
my @current = @start;
until (List::Util::all { defined } @loop[0 .. $#start]) {
	my $cmdix = $step % length($path);
	my $cmd = substr($path, $cmdix, 1);
	for (my $cix = 0; $cix < @current; ++$cix) {
		defined $loop[$cix] and next; ## No need to continue processing this chain
		my $cur = $current[$cix];
		# Don't look at non-destinations
		next unless $cur =~ /Z$/;
		# Has this step and command position already been seen?
		if (defined $seen{$cur}{$cmdix}) {
			# The loop begins at the position this state was last seen, and the length of the loop is the number of steps taken.
			$loop[$cix] = $step - ($first[$cix] = $seen{$cur}{$cmdix});
			# No need to move, this chain will no longer be processed.
		}
		else {
			# Mark this position and state as being seen at this point.
			$seen{$cur}{$cmdix} = $step;
		}
	}
	# Now do the movement
	for my $cur (@current) {
		$cur = $nodes{$cur}{$cmd};
	}
	++$step;
}

for (my $ix = 0; $ix < @first; ++$ix) {
	printf STDERR "For %s, loop starts at %d and is %d steps long\n", $start[$ix], $first[$ix], $loop[$ix];
}

# Aw hell it's this crap again
sub gcd ($x, $y) {
	return $y if $x == 0;
	return $x if $y == 0;
	my $g = 1;
	while (!(($x | $y) & 1)) {
		$x >>= 1;
		$y >>= 1;
		$g <<= 1;
	}
	$x >>= 1 until $x & 1;
	$y >>= 1 until $y & 1;
	until ($x == $y) {
		if ($x < $y) { 
			($x, $y) = ($y, $x);
		}
		$x -= $y;
		$x >>= 1 until $x & 1;
	}
	return $x * $g;
}

sub lcm ($x, $y) {
	return ($x * $y) / gcd($x, $y);
}

my $lcm = List::Util::reduce { lcm($a, $b) } @loop;

say $lcm;
