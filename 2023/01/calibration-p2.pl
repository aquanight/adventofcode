#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $sum = 0;

my %numwords = (
	one => 1,
	two => 2,
	three => 3,
	four => 4,
	five => 5,
	six => 6,
	seven => 7,
	eight => 8,
	nine => 9,
	zero => 0,
);

my $pattern_str = join('|' => '[0123456789]', keys %numwords);
my $pattern_rx = qr/$pattern_str/;

while (<>) {
	my ($first) = /^.*?($pattern_rx)/;
	my ($last) = /^.*($pattern_rx).*$/;
	defined $first or die "Uh ($_)";
	defined $last or die "Oh ($_)";
	for ($first, $last) {
		exists $numwords{$_} and $_ = $numwords{$_};
	}
	my $value = ($first . $last) + 0;
	$sum += $value;
}

say $sum;
