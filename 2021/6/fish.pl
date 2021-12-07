#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $input = <>;

my @fish = map{0+$_} split /,/, $input;

sub step {
	my $day = $#fish;

	for my $ix (0 .. $day) {
		my \$fish = \$fish[$ix];
		if ($fish == 0) {
			$fish = 6;
			push @fish, 8;
		}
		else {
			--$fish;
		}
	}
}

sub print_fish {
	my $ct = @fish;
	printf "Fish: Count=%d, [%s]\n", $ct, (join ",", @fish);
}

print "Initial ";
print_fish;

for my $day (1 .. 80) {
	step;
	print "Day $day ";
	print_fish;
}

say "Final fish count: " . (scalar @fish);
