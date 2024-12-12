#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $stones = <>;
chomp $stones;

my @stones = split / +/, $stones;

my $cycle = 0;

use constant CYCLE_MAX => 25;

while ($cycle < CYCLE_MAX) {
	if ($cycle <= 6) {
		say STDERR "[$cycle] @stones";
	}
	my @newstone;

	while (defined(my $stone = shift(@stones))) {
		if ($stone == 0) {
			push @newstone, 1;
		}
		elsif ((1 + int(log($stone)/log(10))) % 2 == 0) {
			my $hi = substr($stone, 0, length($stone)/2);
			my $lo = substr($stone, length($stone)/2);
			push @newstone, $hi + 0, $lo + 0;
		}
		else {
			push @newstone, $stone * 2024;
		}
	}
	\@stones = \@newstone;
	++$cycle;
}

say scalar(@stones);
