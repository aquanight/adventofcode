#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $score = 0;

my %place = (
	'0' => 0,
	'1' => 1,
	'2' => 2,
	'-' => -1,
	'=' => -2,
);

sub to_digit ($digit) {
	assert -2 <= $digit <= 2;
	state @digit = qw/= - 0 1 2/;
	return $digit[$digit + 2];
}

sub from_snafu ($str) {
	assert scalar($str =~ m/^(?:[120=\-]+)$/);
	my $n = 0;
	for my $digit (split //, $str) {
		$n = ($n * 5) + $place{$digit};
	}
	return $n;
}

sub to_snafu ($n) {
	assert $n > 0;
	my $str = "";
	while ($n > 0) {
		my $digit = $n % 5;
		$n = int($n / 5);
		if ($digit > 2) { $digit -= 5; ++$n; }
		$str = to_digit($digit) . $str;
	}
	return "0" unless length $str;
	return $str;
}

while (<>) {
	chomp;
	my $n = from_snafu($_);
	say STDERR "[$_] Converted: $n";
	$score += $n;
}

say STDERR "Before SNAFU: $score";

say to_snafu($score);
