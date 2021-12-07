#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my @bits;

while (<>) {
	chomp;
	/^[01]+$/ or die "Invalid input";
	my @lb = split //, $_;
	if (scalar @bits) {
		(@lb * 2) == scalar @bits or die "Inconsistent input";
		while (my ($i, $v) = each @lb) {
			$bits[$i * 2 + !!$v]++;
		}
	}
	else {
		@bits = map { $_ ? (0, 1) : (1, 0) } @lb;
	}
}

my $gamma = 0;
my $epsilon = 0;
while (@bits) {
	my ($_0, $_1) = splice @bits, 0, 2;
	if ($_1 > $_0) { $gamma |= 1; }
	else { $epsilon |= 1; }
	$gamma <<= 1;
	$epsilon <<= 1;
}

$gamma >>= 1;
$epsilon >>= 1;

my $pow = $gamma * $epsilon;

say "Gamma is $gamma, Epsilon $epsilon, Power rate $pow";
