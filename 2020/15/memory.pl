#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

my $turn = 0;

# The first argument is the turn number we want. Remaining arguments are the starting numbers.

my $goal = shift @ARGV;

my %mem;

my $last;

while ($turn < $goal) {
	++$turn;
	my $number = shift @ARGV;
	unless (defined $number) {
		if (exists $mem{$last}) {
			my $when = $mem{$last};
			$number = ($turn - 1) - $when;
		}
		else {
			$number = 0;
		}
	}
	$mem{$last} = ($turn - 1) if defined $last;
	$last = $number;
	#print "$number ";
	#printf "(%s)\n", join(", ", map { "$_: $mem{$_}" } sort {$a <=> $b} keys %mem);
}

say "Target number is: $last";
