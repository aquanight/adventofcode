#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %values = (
	A => 14,
	K => 13,
	Q => 12,
	J => 11,
	T => 10,
	(map{ $_ => $_ } qw/2 3 4 5 6 7 8 9/),
);

sub hand_type ($hand) {
	my %card;
	$card{$_}++ for split //, $hand;
	my @amts = sort { $b <=> $a } values %card;
	if ($amts[0] == 5) { return 7; }
	if ($amts[0] == 4) { return 6; }
	if ($amts[0] == 3 && $amts[1] == 2) { return 5; }
	if ($amts[0] == 3) { return 4; }
	if ($amts[0] == 2 && $amts[1] == 2) { return 3; }
	if ($amts[0] == 2) { return 2; }
	return 1;
}

sub sort_hand {
	my @a = map { $values{$_} } split //, $a;
	my @b = map { $values{$_} } split //, $b;
	hand_type($a) <=> hand_type($b) or
	$a[0] <=> $b[0] or
	$a[1] <=> $b[1] or
	$a[2] <=> $b[2] or
	$a[3] <=> $b[3] or
	$a[4] <=> $b[4];
}

my %hands;

while (<>) {
	my ($hand, $bid) = /^(.{5}) (\d+)$/;
	defined $hand or die "Uh oh";
	$hands{$hand} = $bid;
}

my @ranked = sort sort_hand keys %hands;

my $win = 0;
for (my $ix = 0; $ix < @ranked; ++$ix) {
	$win += $hands{$ranked[$ix]} * ($ix + 1);
}

say $win;
