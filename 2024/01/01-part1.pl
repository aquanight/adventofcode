#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @l;
my @r;

while (<>) {
	my ($l, $r) = /^(\d+) +(\d+)/ or die "Input error";
	push @l, $l;
	push @r, $r;
}

@l = sort { $a <=> $b } @l;
@r = sort { $a <=> $b } @r;

my $result = 0;

while (@l && @r) {
	my $l = shift @l;
	my $r = shift @r;
	$result += abs($l - $r);
}

say $result;
