#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

use feature 'declared_refs', 'refaliasing';

my $cur = 0;

my @input = sort {$a <=> $b} map { chomp; 0+$_; } <>;

my @up = (0, 0, 1);

say "@input";

for my $jolt (@input) {
	chomp $jolt;
	my $step = $jolt - $cur;

	$step < 0 and die "Uh oh, step down!";
	$step > 3 and die "Uh oh, hit last adapter";

	$step == 1 && ++$up[0];
	$step == 2 && ++$up[1];
	$step == 3 && ++$up[2];

	$cur = $jolt;
}

say "1J diff: $up[0]";
say "2J diff: $up[1]";
say "3J diff: $up[2]";

my $prod = $up[0] * $up[2];

say "Result: $prod";

my $phone = $input[$#input] + 3;

my %input = map { $_ => undef } @input;

sub paths_to_joltage {
	my $target = shift;
	my $paths = 0;
	$paths++ if $target <= 3; # Can go directly to port
	for my $option (1..3) {
		next unless exists $input{$target - $option};
		my \$value = \$input{$target - $option};
		$value //= paths_to_joltage($target - $option);
		$paths += $value;
	}
	return $paths;
}

printf "Paths to %dJ: %d\n", $phone, paths_to_joltage($phone);
