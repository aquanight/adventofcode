#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $easyct = 0;

while (<>) {
	my ($segments, $output) = /^([abcdefg ]+)\|([abcdefg ]+)$/ or die "Input error";
	my @seg = split / +/, $segments;
	my @out = split / +/, $output;

	$easyct += scalar grep { my $l = length $_; $l == 2 || $l == 3 || $l == 4 || $l == 7 } @out;
}

say "Count of 1/4/7/8: $easyct";
