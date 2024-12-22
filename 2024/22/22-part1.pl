#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub step ($val) {
	my $t;
	$t = $val * 64;
	$val = ($val ^ $t) % 16777216;
	$t = int($val / 32);
	$val = ($val ^ $t) % 16777216;
	$t = $val * 2048;
	$val = ($val ^ $t) % 16777216;
}

my $score = 0;

while (<>) {
	chomp;
	my $val = $_ + 0;
	my $r = $val;
	$r = step($r) for 1 .. 2000;
	say STDERR "$val : $r";
	$score += $r;
}

say $score;
