#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @l;
my %r;

while (<>) {
	my ($l, $r) = /^(\d+) +(\d+)/ or die "Input error";
	push @l, $l;
	$r{$r} += 1;
}

my $result = 0;

for my $l (@l) {
	my $ct = $r{$l} // 0;
	$result += $l * $ct;
}

say $result;
