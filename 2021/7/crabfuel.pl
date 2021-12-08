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

sub posfuel ($pos) { sum map { abs($pos - $_) } @crabs }

my $median = $crabs[@crabs / 2];

my $fuel = posfuel $median;

say STDERR "Align to slot $median, cost is $fuel";
