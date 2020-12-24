#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

use constant PI => atan2(0, -1);

my $dx = 10;
my $dy = -1;

my $x = 0;
my $y = 0;

sub act_N { $dy -= shift; }
sub act_S { $dy += shift; }
sub act_E { $dx += shift; }
sub act_W { $dx -= shift; }

sub act_L {
	my $amt = shift;
	while ($amt <= -90) {
		my $ndx = -$dy;
		my $ndy = $dx;
		$dx = $ndx;
		$dy = $ndy;
		$amt += 90;
	}
	while ($amt >= 90) {
		my $ndx = $dy;
		my $ndy = -$dx;
		$dx = $ndx;
		$dy = $ndy;
		$amt -= 90;
	}
	if ($amt == 0) { return }
	my $ang = atan2($dy, $dx) * 180 / PI;
	my $mag = sqrt(($dx * $dx) + ($dy * $dy));
	say "Current angle $ang";
	$ang -= $amt;
	$dx = cos ($ang * PI / 180) * $mag;
	$dy = sin ($ang * PI / 180) * $mag;
}

sub act_R {
	$_[0] *= -1;
	goto &act_L;
}

sub act_F { my $amt = shift; $x += ($dx * $amt); $y += ($dy * $amt); }

while (<>) {
	chomp;
	my ($cmd, $amt) = /^([NSEWLRF])(\d+)$/;
	main->can("act_$cmd")->($amt);
	say "CMD $_ X $x Y $y DX $dx DY $dy";
}

printf "Distance: %d\n", (abs($x) + abs($y));
