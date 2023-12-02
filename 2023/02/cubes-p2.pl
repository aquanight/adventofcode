#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $pow_sum = 0;

while (<>) {
	my ($game_id, $game) = /^Game (\d+): (.*)$/;
	defined $game_id or die "Uh oh";
	my $possible = 1;
	my @rounds = split /\s*;\s*/, $game;
	my $power = 0;
	my $min_red = 0;
	my $min_green = 0;
	my $min_blue = 0;
	for my $round (@rounds) {
		my $red = 0;
		my $green = 0;
		my $blue = 0;
		my @pulls = split /\s*,\s*/, $round;
		for my $pull (@pulls) {
			my ($qty, $color) = $pull =~ /(\d+) (red|green|blue)/;
			defined($color) or die "Oops";
			$red += $qty if $color eq 'red';
			$green += $qty if $color eq 'green';
			$blue += $qty if $color eq 'blue';
		}
		$red > $min_red and $min_red = $red;
		$green > $min_green and $min_green = $green;
		$blue > $min_blue and $min_blue = $blue;
	}
	$power = $min_red * $min_green * $min_blue;
	$pow_sum += $power;
}

say $pow_sum;
