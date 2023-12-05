#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $sum = 0;

while (<>) {
	my ($idx, $win, $play) = /^Card +(\d+):\s*([\d\s]+)\|([\d\s]+)$/;
	defined $idx or die "Uh";
	defined $win or die "Oh";
	defined $play or die "Er";
	my %win = map { $_ => 1 } split /\s+/, $win;
	my $card = 0;
	my @play = split /\s+/, $play;
	for my $n (@play) {
		exists $win{$n} or next;
		if ($card < 1) {
			$card = 1;
		}
		else {
			$card *= 2;
		}
	}
	$sum += $card;
}

say $sum;
