#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

use List::Util ();

chomp(my $time = <>);
chomp(my $sched = <>);

my @buses = grep /\d+/, split /,/, $sched;

my @waits = map { ($_ - ($time % $_)) % $_ } @buses;

my $short = 999_999;
my $res;

for my $ix (0..$#buses) {
	if ($waits[$ix] < $short) {
		$short = $waits[$ix];
		$res = $short * $buses[$ix];
	}
}

say "Result: $res";

@buses = split /,/, $sched;

my $bigbus = $buses[0];
my $bigix = 0;

for my $ix (1 .. $#buses) {
	if ($buses[$ix] eq 'x') { next; }
	if ($bigbus eq 'x' || $buses[$ix] > $bigbus) {
		$bigbus = $buses[$ix];
		$bigix = $ix;
	}
}

my $t = $bigbus - $bigix;
print "$sched\n";
print "Checking starting at $t\n";

my $step = $bigbus;

TIME: while (1) {
	#	die if $t > 1_000_000_000;
	print "$t\t";
	my @mods = map { $buses[$_] eq 'x' ? undef : ($t + $_) % $buses[$_] } 0 .. $#buses;
	say join " ", map { $_//"x" } @mods;
	if (List::Util::all { ($_//0) == 0 } @mods) { last; }
	my @zeros = map { $buses[$_] } grep { defined $mods[$_] && $mods[$_] == 0 } 0 .. $#buses;
	$step = List::Util::product @zeros;
}
continue {
	$t += $step;
}
say "Resonance at $t";
