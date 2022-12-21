#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @elves = ();

my $current;

while (<>) {
	if (/^\s*$/) {
		undef $current;
		next;
	}
	unless (defined $current) {
		push @elves, 0;
		$current = \$elves[-1];
	}
	assert /^\d+$/;
	$$current += 0 + $_;
}

my ($max1, $max2, $max3) = sort { $b <=> $a } @elves;

say ($max1 + $max2 + $max3);
