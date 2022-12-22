#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $X = 1;

my $cycle_count = 0;

use constant INTEREST => 20, 60, 100, 140, 180, 220;

my $score = 0;

sub cycle {
	++$cycle_count;
	if (List::Util::any { $_ == $cycle_count } INTEREST) {
		$score += $cycle_count * $X;
	}
}

while (<>) {
	chomp;
	if (/^noop$/) {
		cycle;
	}
	elsif (/^addx (-?\d+)$/) {
		cycle;
		cycle;
		$X += $1;
	}
}

say $score;
