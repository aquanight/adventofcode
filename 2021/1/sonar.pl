#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $prev = undef;

my $ct = 0;

while (<>) {
	chomp;
	if (defined $prev) {
		if ($_ > $prev) {
			say "$_ (increased)";
			++$ct;
		}
		elsif ($_ < $prev) {
			say "$_ (decreased)";
		}
		else {
			say "$_ (no change)";
		}
	}
	$prev = $_;
}

say "Number of increases: $ct";
