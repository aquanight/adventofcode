#!/usr/bin/perl
use v5.30;
use warnings;

use List::Util ();

use constant RIGHT => 3;

#my @cases = map { { rate => $_, pos => 0, tree => 0 } } 1, 3, 5, 7, 0.5;

my @cases = (
	{ right => 1, down => 1 },
	{ right => 3, down => 1 },
	{ right => 5, down => 1 },
	{ right => 7, down => 1 },
	{ right => 1, down => 2 },
);

for my $case (@cases) {
	$case->@{qw/pos tree line/} = (0, 0, 999);
}

while (defined(my $line = <>)) {
	chomp $line;
	for my $case (@cases) {
		++$case->{line};
		if ($case->{line} >= $case->{down}) {
			$case->{line} = 0;
			my $ix = $case->{pos} % length($line);
			$case->{pos} += $case->{right};
			my $chr = substr($line, $ix, 1);
			if ($chr eq '#') {
				$case->{tree}++;
			}
		}
	}
}

for my $case (@cases) {
	my ($right, $down, $tree) = $case->@{qw/right down tree/};
	say "Case R$right D$down : Trees $tree";
}

printf "Trees: %d\n", List::Util::product(map { $_->{tree} } @cases);
