#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @lines = <>;

chomp for @lines;

my $xmas = 0;

sub word ($x, $y, $dx, $dy, $ct) {
	my $str = "";
	while ($ct > 0) {
		--$ct;
		next if $y < 0;
		next if $y > $#lines;
		my $l = $lines[$y];
		next if $x < 0;
		next if $x >= length $l;
		$str .= substr($l, $x, 1);
		$x += $dx;
		$y += $dy;
	}
	return $str;
}

for my $ln (0 .. $#lines) {
	local $_ = $lines[$ln];
	while (/X/g) {
		my $x = pos() - 1;
		say STDERR "X at $x,$ln";
		for my $dx (-1, 0, 1) {
			for my $dy (-1, 0, 1) {
				if (word($x, $ln, $dx, $dy, 4) eq "XMAS") {
					say STDERR "XMAS at $x,$ln moving $dx,$dy";
					++$xmas;
				}
			}
		}
	}
}

say $xmas;
