#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my @dots;

sub count_dots {
	my $ct = grep { $_//!1 } map { @{$_//[]} } @dots;
	say STDERR "Dot count is $ct";
}

while (<>) {
	chomp;
	my ($x, $y);
	if (($x, $y) = /^\s*(\d+)\s*,\s*(\d+)\s*$/) {
		$dots[$y][$x] = 1;
	}
	elsif (($x) = /^\s*fold\s+along\s+x\s*=\s*(\d+)\s*$/) {
		for $y (0 .. $#dots) {
			for my $rx ( ($x + 1) .. $dots[$y]->$#* ) {
				my $lx = $x - ($rx - $x);
				$dots[$y][$lx] |= $dots[$y][$rx]//(!1);
			}
			splice $dots[$y]->@*, $x;
		}
		last; # Only do first fold.
	}
	elsif (($y) = /^\s*fold\s+along\s+y\s*=\s*(\d+)\s*$/) {
		for my $dy ( ($y + 1) .. $#dots ) {
			my $uy = $y - ($dy - $y);
			$dots[$uy][$_] |= $dots[$dy][$_]//(!1) for (0 .. $dots[$dy]->$#*);
		}
		splice @dots, $y;
		last;
	}
}

my $dotct = grep { $_//!1 } map { @{$_//[]} } @dots;

say "Dot count is $dotct";
