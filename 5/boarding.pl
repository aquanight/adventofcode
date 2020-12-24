#!/usr/bin/perl
use v5.30;
use warnings;

my @seats;

while (<>)
{
	chomp;
	my ($rowstr, $colstr) = m/^([FB]{7})([LR]{3})$/;
	my $row = oct("0b" . ($rowstr =~ tr/FB/01/r));
	my $col = oct("0b" . ($colstr =~ tr/LR/01/r));

	my $sid = ($row * 8) + $col;

	if ($sid > $#seats) { $#seats = $sid; }

	$seats[$sid] = 1;
}

say "Highest ID: $#seats";

my @cand = grep { !$seats[$_] && $seats[$_ - 1] && $seats[$_ + 1] } keys @seats;

say "Candidate seats: @cand";
