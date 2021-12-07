#!/usr/bin/perl
use v5.30;
use warnings;

my $validcount = 0;

while (<>) {
	(my ($min, $max, $letter, $password) = /^(\d+)-(\d+) ([a-zA-Z]): (.*)$/) or die "Line $_ not valid";
	my $count = scalar(() = $password =~ m/$letter/g);
	($count >= $min && $count <= $max) and ++$validcount;
}

say "Number of valid passwords: $validcount";
