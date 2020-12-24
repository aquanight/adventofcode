#!/usr/bin/perl
use v5.30;
use warnings;

$/ = ""; # paragraph

my $sum = 0;

while (<>)
{
	my %answers = ();
	my $groupcount = () = m/^.+$/mg;
	for my $ans (/[a-z]/g) {
		$answers{$ans}++;
	}
	$sum += scalar grep { $answers{$_} == $groupcount; } keys %answers;
}

say "Total: $sum";
