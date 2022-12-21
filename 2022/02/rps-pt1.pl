#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $score = 0;

my %choice = ( X => 1, Y => 2, Z => 3 );

my %match;
($match{A}->@{qw/X Y Z/}) = (3, 6, 0);
($match{B}->@{qw/X Y Z/}) = (0, 3, 6);
($match{C}->@{qw/X Y Z/}) = (6, 0, 3);

while (<>) {
	my ($opp, $play);
	(($opp, $play) = /^\s*(\w+)\s+(\w+)/) or die "Invalid";

	my $line = $choice{$play} + $match{$opp}{$play};

	$score += $line;
}

say $score;
