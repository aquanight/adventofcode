#!/usr/bin/perl
use v5.30;
use warnings;

my $validcount = 0;

while (<>) {
	(my ($pos1, $pos2, $letter, $password) = /^(\d+)-(\d+) ([a-zA-Z]): (.*)$/) or die "Line $_ not valid";
	my $chr1 = substr $password, ($pos1 - 1), 1;
	my $chr2 = substr $password, ($pos2 - 1), 1;
	(($chr1 eq $letter) != ($chr2 eq $letter)) and ++$validcount;
}

say "Number of valid passwords: $validcount";
