#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $score = 0;

my %choice = ( X => 0, Y => 3, Z => 6 );

my %match;
($match{A}->@{qw/X Y Z/}) = (3, 1, 2);
($match{B}->@{qw/X Y Z/}) = (1, 2, 3);
($match{C}->@{qw/X Y Z/}) = (2, 3, 1);

while (<>) {
	my ($opp, $play);
	(($opp, $play) = /^\s*(\w+)\s+(\w+)/) or die "Invalid";

	my $line = $choice{$play} + $match{$opp}{$play};

	$score += $line;
}

say $score;
