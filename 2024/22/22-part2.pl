#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub step ($val) {
	my $t;
	$t = $val * 64;
	$val = ($val ^ $t) % 16777216;
	$t = int($val / 32);
	$val = ($val ^ $t) % 16777216;
	$t = $val * 2048;
	$val = ($val ^ $t) % 16777216;
}

my $score = 0;

my %opts;

while (<>) {
	chomp;
	my $val = $_ + 0;
	my $price = $val % 10;
	my %buyer;
	my @diffs;
	for my $step (1 .. 2000) {
		$val = step($val);
		my $np = $val % 10;
		push @diffs, $np - $price;
		$price = $np;
		if (@diffs > 4) { shift @diffs; }
		if (@diffs == 4) {
			my $key = join ",", @diffs;
			unless (exists $buyer{$key}) {
				$buyer{$key} = $price;
			}
		}
	}
	for my $opt (keys %buyer) {
		$opts{$opt} += $buyer{$opt};
	}
}

($score) = sort { $b <=> $a } values %opts;

say $score;
