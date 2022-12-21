#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @sacks;

my %prio;
@prio{'a' .. 'z', 'A' .. 'Z'} = 1 .. 52;

my $score = 0;

while (<>) {
	my ($half) = length($_)/2;
	my ($first, $second) = (substr($_, 0, $half), substr($_, $half));
	my %sack;
	foreach my $item (split //, $first) { $sack{$item} = 1; }
	foreach my $item (split //, $second) {
		exists $sack{$item} or next;
		delete $sack{$item};
		$score += $prio{$item};
	}
}

say $score;
