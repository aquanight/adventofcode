#!/usr/bin/perl
use v5.30;
use warnings;

use constant TARGET => 2020;

my %input = ();

my @found;

while (<>) {
	chomp;
	my $value = 0+$_;

	my $pairs = {};

	for my $current (keys %input) {
		my $opair = $input{$current};
		if (exists ($opair->{$value})) {
			@found = ($value, $current, $opair->{$value});
			last;
		}
		my $other = TARGET - ($value + $current);
		$opair->{$value} = TARGET - ($value + $current);
		$opair->{$other} = $value;
		$pairs->{$current} = $other;
		$pairs->{$other} = $current;
	}

	$input{$value} = $pairs;
}

scalar @found or die "Found no suitable value";

printf "Result: %d\n", ($found[0] * $found[1] * $found[2]);
