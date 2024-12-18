#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $xw = shift @ARGV;
my $yw = shift @ARGV;
my $limit = shift @ARGV;

my %no;

while (<>) {
	last unless $limit--;
	chomp;
	/^(\d+),(\d+)$/ or die;
	my ($x, $y) = ($1, $2);
	$no{"$x,$y"} = 1;
}

for my $y ( 0 .. $yw ) {
	for my $x ( 0 .. $xw ) {
		if ($no{"$x,$y"}) { print STDERR '#'; }
		else { print STDERR '.'; }
	}
	print STDERR "\n";
}

my @paths = [ 0, 0, 0 ]; # (x, y, steps)

my %seen;

my $goal;

while (@paths) {
	my ($x, $y, $steps) = (shift @paths)->@*;
	next if $no{"$x,$y"};
	next if defined($goal) && $steps >= $goal;
	next if defined($seen{"$x,$y"}) && $steps >= $seen{"$x,$y"};
	$seen{"$x,$y"} = $steps;
	if ($x == $xw && $y == $yw) {
		$goal = $steps;
		next;
	}
	if ($x > 0) {
		push @paths, [ $x - 1, $y, $steps + 1 ];
	}
	if ($x < $xw) {
		push @paths, [ $x + 1, $y, $steps + 1 ];
	}
	if ($y > 0) {
		push @paths, [ $x, $y - 1, $steps + 1 ];
	}
	if ($y < $yw) {
		push @paths, [ $x, $y + 1, $steps + 1 ];
	}
}

say $goal;
