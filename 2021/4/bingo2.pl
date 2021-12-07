#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;


use integer;

use List::Util ();

my @calls;

my @boards;

@calls = map { 0+$_ } do { defined($_ = <>) or die "No input"; chomp; split /,/; };

my $board;

while (<>) {
	chomp;
	if ($_ eq "") {
		die "Invalid board" unless !defined($board) || @$board == 25;
		push @boards, ($board = []);
	}
	else {
		my @row = /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$/ or die "Invalid board row";
		push @$board, @row;
		(@$board > 25) and die "Too many rows in board";
	}
}

# Isn't the middle supposed to be "FREE SPACE"?

sub mark_board ($board, $call) {
	for my $ix (0 .. $#$board) {
		if ($board->[$ix] == $call) {
			$board->[$ix] = ~($board->[$ix]);
		}
	}
}

use constant WINS => (
	[ 0, 1, 2, 3, 4 ],
	[ 5, 6, 7, 8, 9 ],
	[ 10, 11, 12, 13, 14 ],
	[ 15, 16, 17, 18, 19 ],
	[ 20, 21, 22, 23, 24 ],
	[ 0, 5, 10, 15, 20 ],
	[ 1, 6, 11, 16, 21 ],
	[ 2, 7, 12, 17, 22 ],
	[ 3, 8, 13, 18, 23 ],
	[ 4, 9, 14, 19, 24 ],
);
sub is_winner ($board) {
	for my $win (WINS) {
		grep { $_ >= 0 } $board->@[@$win] or return 1;
	}
	return "";
}

sub point_value ($board) {
	return List::Util::sum grep { $_ >= 0 } @$board;
}

my $last_winner;
my $last_call;

while (defined(my $call = shift @calls)) {
	@boards or last;
	mark_board $_, $call for @boards;
	my $ix = 0;
	while ($ix < $#boards) {
		if (is_winner $boards[$ix]) {
			$last_winner = splice @boards, $ix, 1;
			$last_call = $call;
		}
		else {
			++$ix;
		}
	}
}

my $score = point_value $last_winner;
say STDERR "Last winning board: [@$last_winner]";
say STDERR "Base score: $score";
$score *= $last_call;
say "Final Score: $score";
