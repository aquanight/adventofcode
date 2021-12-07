#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use List::Util ();

use Devel::Peek;

my $input = <>;

my @fish = map{0+$_} split /,/, $input;

my @days = (0, 0, 0, 0, 0, 0, 0, 0, 0);

while (defined(my $fish = shift @fish)) {
	$days[$fish]++;
}

sub step {
	my $spawn = shift @days;
	$days[6] += $spawn;
	$days[8] += $spawn;
}

sub print_fish {
	my $ct = List::Util::sum @days;
	printf "Fish: Count=%d, Fish by day: [%s]\n", $ct, (join ",", @days);
}

print "Initial ";
print_fish;

for my $day (1 .. 256) {
	step;
	print "Day $day ";
	print_fish;
}

