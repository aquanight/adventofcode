#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $sum = 0;

while (<>) {
	chomp;
	for my $step (split /,/, $_) {
		my $hash = 0;
		for my $chr (split //, $step) {
			my $ord = ord $chr;
			$hash = (($hash + $ord) * 17) % 256;
		}
		say STDERR "Hash of $step is $hash";
		$sum += $hash;
	}
}

say $sum;
