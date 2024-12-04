#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $sum = 0;

my $enabled = 1;

while (<>) {
	our $REGMARK;
	while (/do\(\)(*MARK:DO)|don't\(\)(*MARK:DONT)|mul\((\d+),(\d+)\)(*MARK:MUL)/g) {
		say STDERR "MARK: $REGMARK";
		if ($REGMARK eq "DO") { $enabled = 1; next; }
		if ($REGMARK eq "DONT") { $enabled = 0; next; }
		die unless $REGMARK eq "MUL";
		next unless $enabled;
		my ($x, $y) = ($1, $2);
		$sum += $x * $y;
	}
}

say $sum;
