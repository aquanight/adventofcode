#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $X = 1;

my $scan = 0;

my $crt = "";

sub cycle {
	if (abs($X - $scan) <= 1) {
		$crt .= "#";
	}
	else {
		$crt .= ".";
	}
	++$scan;
	if ($scan >= 40) {
		$crt .= "\n";
		$scan = 0;
	}
}

while (<>) {
	chomp;
	if (/^noop$/) {
		cycle;
	}
	elsif (/^addx (-?\d+)$/) {
		cycle;
		cycle;
		$X += $1;
	}
}

say $crt;
