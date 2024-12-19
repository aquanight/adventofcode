#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @towels;

my @patterns;

my $inp = 0;

while (<>) {
	chomp;
	if ($inp) {
		push @patterns, $_;
	}
	elsif (/^ *$/) {
		$inp = 1;
	}
	else {
		my @t = split / *, */, $_;
		push @towels, @t;
	}
}

my $rx_txt = "^(" . join("|", @towels) . ")*\$";
say STDERR "Towel set: $rx_txt";

my $rx = qr/$rx_txt/;

my $ct = scalar grep { /$rx/ } @patterns;

say $ct;
