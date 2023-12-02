#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $sum = 0;

while (<>) {
	my ($first) = /^\D*(\d)/;
	my ($last) = /(\d)\D*$/;
	my $value = ($first . $last) + 0;
	$sum += $value;
}

say $sum;
