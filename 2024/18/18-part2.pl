#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $xw = shift @ARGV;
my $yw = shift @ARGV;

my %no;

my %current;

sub find_path {
	my @paths = [ 0, 0, 0 ]; # (x, y, steps, @path)
	my %seen;
	undef %current;
	say STDERR "Building new path";
	while (@paths) {
		my ($x, $y, $steps, @path) = (shift @paths)->@*;
		push @path, "$x,$y";
		next if $no{"$x,$y"};
		next if defined($seen{"$x,$y"}) && $steps >= $seen{"$x,$y"};
		$seen{"$x,$y"} = $steps;
		if ($x == $xw && $y == $yw) {
			say STDERR "Route to goal found at $steps steps";
			for my $v (@path) { $current{$v} = 1; }
			return;
		}
		if ($x > 0) {
			push @paths, [ $x - 1, $y, $steps + 1, @path ];
		}
		if ($x < $xw) {
			push @paths, [ $x + 1, $y, $steps + 1, @path ];
		}
		if ($y > 0) {
			push @paths, [ $x, $y - 1, $steps + 1, @path ];
		}
		if ($y < $yw) {
			push @paths, [ $x, $y + 1, $steps + 1, @path ];
		}
	}
	say STDERR "No route found";
}

find_path;

while (<>) {
	chomp;
	/^(\d+),(\d+)$/ or die;
	my ($x, $y) = ($1, $2);
	say STDERR "Blocking $x,$y";
	$no{"$x,$y"} = 1;
	if ($current{"$x,$y"}) {
		# This path no longer works, find a new one.
		say STDERR "Previous path blocked";
		find_path;
		unless (%current) {
			# No path remains.
			say "$x,$y";
			exit;
		}
	}
}

