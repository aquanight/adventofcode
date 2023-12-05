#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @nums;

my @syms;

while (<>) {
	while (m/\d+/g) {
		my $y = $.;
		my $x = $-[0];
		push @nums, [$&, $x, $y];
	}
	pos($_) = 0;
	while (m/[[:punct:]]/g) {
		next if $& eq '.';
		my $y = $.;
		my $x = $-[0];
		push @syms, [$&, $x, $y];
	}
}

my $sum = 0;

for my $sym (@syms) {
	my ($s, $sx, $sy) = @$sym;
	say STDERR "Symbol $s at $sx, $sy";
	for my $num (@nums) {
		my ($n, $nx, $ny) = @$num;
		next if abs($sy - $ny) > 1;
		next if $nx - $sx > 1;
		next if $sx - $nx > length($n);
		say STDERR "Adjacent number $n";
		$sum += $n;
	}
}

say $sum;
