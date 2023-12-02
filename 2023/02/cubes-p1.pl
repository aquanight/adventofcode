#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $red_limit = 12;
my $green_limit = 13;
my $blue_limit = 14;

my $id_sum;

while (<>) {
	my ($game_id, $game) = /^Game (\d+): (.*)$/;
	defined $game_id or die "Uh oh";
	my $possible = 1;
	my @rounds = split /\s*;\s*/, $game;
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
		$red > $red_limit and $possible = 0;
		$green > $green_limit and $possible = 0;
		$blue > $blue_limit and $possible = 0;
	}
	if ($possible) {
		$id_sum += $game_id;
	}
}

say $id_sum;
