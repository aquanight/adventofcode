#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use List::Util 'sum';

use integer;

my $input = <>;
defined $input or die "Missing input";

my @crabs = map {0+$_} split /,/, $input;

@crabs = sort { $a <=> $b } @crabs;

sub posfuel ($pos) { sum map { my $n = abs($pos - $_); my $r = ($n * ($n + 1)) / 2; $r; } @crabs }

my $mean = do { no integer; int(((sum @crabs) / @crabs) + 0.5); };

my $fuel = posfuel $mean;

say STDERR "Align to slot $mean, cost is $fuel";

my $smallest;
my $smcost;
for my $brute (0 .. $crabs[-1]) {
	my $cost = posfuel $brute;
	unless (defined $smallest && $smcost <= $cost) {
		$smallest = $brute;
		$smcost = $cost;
	}
}

say STDERR "Found by brute force: $smallest, cost $smcost";
