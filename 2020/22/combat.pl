#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

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

sub round {
	say "Player 1 deck: @p1deck";
	say "Player 2 deck: @p2deck";

	my $p1 = shift @p1deck;
	my $p2 = shift @p2deck;

	say "Player 1 card: $p1";
	say "Player 2 card: $p2";

	if ($p1 > $p2) {
		say "Player 1 wins";
		push @p1deck, $p1, $p2;
	}
	elsif ($p2 > $p1) {
		say "Player 2 wins";
		push @p2deck, $p2, $p1;
	}
	else {
		die "Tie result undefined";
	}
	say "";

	return scalar(@p1deck) * scalar(@p2deck);
}

while (round) {
}

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
