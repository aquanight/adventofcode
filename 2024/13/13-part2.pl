#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @machines; # ( A-x, A-Y, B-X, B-Y, P-X, P-Y )

my $current;

while (<>) {
	chomp;
	if (/^Button A: X\+(\d+), Y\+(\d+)$/) {
		push @machines, ($current = [$1, $2]);
	}
	elsif (/^Button B: X\+(\d+), Y\+(\d+)$/) {
		$current->[2] = $1;
		$current->[3] = $2;
	}
	elsif (/^Prize: X=(\d+), Y=(\d+)$/) {
		$current->[4] = $1 + 10000000000000;
		$current->[5] = $2 + 10000000000000;
	}
	elsif (/^\s*$/) {
		$current = undef;
	}
	else { die "Input error" }
}

my $tokens = 0;

sub gcd ($x, $y) {
	while ($y != 0) {
		($x, $y) = ($y, $x % $y);
	}
	return $x;
}

while (defined($current = shift @machines)) {
	my ($ax, $ay, $bx, $by, $px, $py) = @$current;
	# px = ax * A + bx * B
	# py = ay * A + by * B
	
	my $det = $ax * $by - $bx * $ay;
	if ($det == 0) { next; }

	my $A = ($px * $by - $bx * $py) / $det;
	my $B = ($ax * $py - $px * $ay) / $det;

	if ($A != int($A) || $B != int($B)) { next; }

	say STDERR "Solution: A $A, B $B";
	my $cost = (3 * $A) + $B;
	say STDERR "Needs: $cost tokens";
	$tokens += $cost;
}

say $tokens;
