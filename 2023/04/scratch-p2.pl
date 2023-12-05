#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util;

my @cards = (0);

while (<>) {
	my ($idx, $win, $play) = /^Card +(\d+):\s*([\d\s]+)\|([\d\s]+)$/;
	$cards[$idx]++;
	defined $idx or die "Uh";
	defined $win or die "Oh";
	defined $play or die "Er";
	my %win = map { $_ => 1 } split /\s+/, $win;
	my @play = split /\s+/, $play;
	my $matches = List::Util::sum map { $_ // 0 } @win{@play};
	for my $copy (($idx + 1) .. ($idx + $matches)) {
		$cards[$copy] += $cards[$idx];
	}
}

say List::Util::sum @cards;
