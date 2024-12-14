#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @robots;

my $xw = 101;
my $yw = 103;
my $steps = $xw * $yw;

while (<>) {
	chomp;
	my ($px, $py, $vx, $vy) = /p=(\d+),(\d+) v=(-?\d+),(-?\d+)/;
	push @robots, [ $px, $py, $vx, $vy ];
}

my $qul = 0;
my $qur = 0;
my $qll = 0;
my $qlr = 0;

for my $step (0 .. ($steps - 1)) {
	my %nr;
	for my $r (@robots) {
		my ($px, $py, $vx, $vy) = @$r;

		my $nx = ($px + ($step * $vx)) % $xw;
		my $ny = ($py + ($step * $vy)) % $yw;
		$nr{"$nx,$ny"} = 1;
	}

	if (keys(%nr) == scalar(@robots)) {
		for my $y (0 .. ($yw - 1)) {
			my $ln = ' ' x $xw;
			for my $x (0 .. ($xw - 1)) {
				$nr{"$x,$y"} and substr($ln, $x, 1, "X");
			}
			say STDERR $ln;
		}
		say STDERR "Step: $step";
		my $resp = <STDIN>;
		if ($resp eq 'q') { last; }
	}
}
