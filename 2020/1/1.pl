#!/usr/bin/perl
use v5.30;
use warnings;

use constant TARGET => 2020;

my %input = ();

my $found;

while (<>) {
	chomp;
	my $value = 0+$_;
	my $other = TARGET - $value;

	$input{$value} = $other;
	if (exists $input{$other}) {
		$found = $value;
		last;
	}
}

$found//die "Found no suitable value";

printf "Result: %d\n", ($found * (TARGET - $found));
