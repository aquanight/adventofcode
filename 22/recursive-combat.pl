#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';
no warnings 'experimental';
use feature qw/refaliasing declared_refs/;

my @p1deck;
my @p2deck;

my $current;

while (<>) {
	chomp;
	next if ($_ eq "");
	if (/^Player 1:/) {
		$current = \@p1deck;
	}
	elsif (/^Player 2:/) {
		$current = \@p2deck;
	}
	elsif (/^\d+$/) {
		push @$current, 0+$_;
	}
}

sub combat;

use constant VERBOSE => 1;

my $depth = 0;
my $pfx = "";

sub round {
	my (\@p1, \@p2) = @_;
	say "${pfx}Player 1 deck: @p1" if $depth <= VERBOSE;
	say "${pfx}Player 2 deck: @p2" if $depth <= VERBOSE;

	my $p1 = shift @p1;
	my $p2 = shift @p2;

	say "${pfx}Player 1 card: $p1" if $depth <= VERBOSE;
	say "${pfx}Player 2 card: $p2" if $depth <= VERBOSE;

	if ($p1 <= scalar(@p1) && $p2 <= scalar(@p2)) {
		say "${pfx}Entering recursive combat!" if $depth <= VERBOSE;
		++$depth;
		$pfx = (" " x $depth);
		my @subp1 = @p1[0 .. ($p1 - 1)];
		my @subp2 = @p2[0 .. ($p2 - 1)];

		my $win = combat \@subp1, \@subp2;
		--$depth;
		$pfx = (" " x $depth);

		say "${pfx}Player $win won the recursive round" if $depth <= VERBOSE;
		if ($win == 1) {
			push @p1, $p1, $p2;
		}
		else {
			push @p2, $p2, $p1;
		}
	}
	else {
		if ($p1 > $p2) {
			say "${pfx}Player 1 wins" if $depth <= VERBOSE;
			push @p1, $p1, $p2;
		}
		elsif ($p2 > $p1) {
			say "${pfx}Player 2 wins" if $depth <= VERBOSE;
			push @p2, $p2, $p1;
		}
		else {
			die "${pfx}Tie result undefined" if $depth <= VERBOSE;
		}
	}
	say "" if $depth <= VERBOSE;

	return scalar(@p1) * scalar(@p2);
}

use List::Util ();

sub sequence_equal {
	my (\@x, \@y) = @_;
	return "" unless scalar(@x) == scalar(@y);
	return List::Util::all { $x[$_] == $y[$_] } keys @x;
}

sub seen {
	my (\@current, \@p1, \@p2) = @_;

	for my $state (@current) {
		next unless sequence_equal \@p1, $state->[0];
		next unless sequence_equal \@p2, $state->[1];
		# We have seen this state before
		return 1;
	}

	# Not yet seen state, so add it to our list:
	push @current, [ [ @p1 ], [ @p2 ] ];
	return "";
}

# Returns 1 for P1 win, 2 for P2 win
sub combat {
	my (\@p1, \@p2) = @_;

	my @seen;

	while (1) {
		if (seen \@seen, \@p1, \@p2) {
			say "${pfx}Repeated state - P1 wins" if $depth <= VERBOSE;
			return 1; # Player 1 immediately wins
		}
		round \@p1, \@p2 or last;
	}


	return 1 if scalar(@p1) > 0 && scalar(@p2) < 1;
	return 2 if scalar(@p2) > 0 && scalar(@p1) < 1;
	die;
}

my $p = combat \@p1deck, \@p2deck;

say "Player $p won the Recursive Combat";

say "Final results:";
say "Player 1 deck: @p1deck";
say "Player 2 deck: @p2deck";

my (@winning) = (@p1deck, @p2deck); # one of these will be empty

my $score = 0;
my $factor = 1;

say "Winning deck: @winning";

while (defined(my $card = pop @winning)) {
	$score += ($card * $factor);
	++$factor;
}

say "Winning score: $score";
