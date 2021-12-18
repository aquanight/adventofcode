#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use POSIX ();

use List::Util ();

my ($txmin, $txmax, $tymin, $tymax) = (<> =~ /^\s*target\s+area\s*:\s*x\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*,\s*y\s*=\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$/);

say "Target: X [ $txmin .. $txmax ] Y [ $tymin .. $tymax ]";

my $vymin = $tymin;
my $vymax = -$tymin - 1;

sub quad ($x, $y, $z) {
	my $r1 = (-$y + sqrt(($y*$y) - (4*$x*$z))) / (2*$x);
	my $r2 = (-$y - sqrt(($y*$y) - (4*$x*$z))) / (2*$x);
	List::Util::first{ $_ >= 0 } $r1, $r2;
}

my %t;

sub solve_y ($vy) {
	my $_ovy = $vy;
	my $off = 0;
	if ($vy >= 0) {
		$off = 2*$vy + 1;
		$vy = -$vy - 1;
	}
	my $max_t = POSIX::floor(quad(-1, (2*$vy + 1), (-2*$tymin)));
	my $min_t = POSIX::ceil(quad(-1, (2*$vy + 1), (-2*$tymax)));
	say STDERR "For vy $_ovy : Time range $min_t .. $max_t";
	if ($min_t > $max_t) { return (); }
	for my $t ($min_t .. $max_t) {
		$t{$off+$t}{vy}{$_ovy} = 1;
	}
}

solve_y $_ for $vymin .. $vymax;

my @vy = sort { $a <=> $b } (map { keys $_->{vy}->%* } values %t);

say "vy solutions: [ @vy ]";

my @restvx;

my $minrestvx = quad(1, 1, (-2*$txmin));
my $maxrestvx = quad(1, 1, (-2*$txmax));

@restvx = POSIX::ceil($minrestvx) .. POSIX::floor($maxrestvx); # The vx range that produces a "resting" probe.

say STDERR "Rest range: $minrestvx .. $maxrestvx";

for my $t (keys %t) {
	if ($t > $minrestvx) {
		for (my $vx = POSIX::ceil($minrestvx); $vx < $t && $vx < $maxrestvx; ++$vx) {
			$t{$t}{vx}{$vx} = 1;
		}
	}
	my $min_vx = POSIX::ceil( (((2*$txmin) / $t) + $t - 1) / 2 );
	my $max_vx = POSIX::floor((((2*$txmax) / $t) + $t - 1) / 2 );
	$min_vx = ($min_vx < $t ? $t : $min_vx);
	$t{$t}{vx}{$_} = 1 for $min_vx .. $max_vx;
}

my @vx = sort { $a <=> $b } (map { keys $_->{vx}->%* } values %t);

say "vx solutions: [ @vx ]";

my %sol;

for my $t (keys %t) {
	my $vx = $t{$t}{vx}//next;
	my $vy = $t{$t}{vy}//next;
	next unless(defined($vx) && %$vx);
	next unless(defined($vy) && %$vy);
	for my $_vx (keys %$vx) {
		for my $_vy (keys %$vy) {
			$sol{"$_vx,$_vy"} = 1;
		}
	}
}

my $solct = keys %sol;

say "Solution count: $solct";
