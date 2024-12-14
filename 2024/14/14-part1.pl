#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @robots;

my $steps = shift @ARGV;
my $xw = shift @ARGV;
my $yw = shift @ARGV;

while (<>) {
	chomp;
	my ($px, $py, $vx, $vy) = /p=(\d+),(\d+) v=(-?\d+),(-?\d+)/;
	push @robots, [ $px, $py, $vx, $vy ];
}

my $xmid = ($xw - 1) / 2;
my $ymid = ($yw - 1) / 2;

my $qul = 0;
my $qur = 0;
my $qll = 0;
my $qlr = 0;

for my $r (@robots) {
	my ($px, $py, $vx, $vy) = @$r;

	my $nx = ($px + ($steps * $vx)) % $xw;
	my $ny = ($py + ($steps * $vy)) % $yw;

	next if $nx == $xmid;
	next if $ny == $ymid;

	if ($nx < $xmid) {
		if ($ny < $ymid) {
			++$qul;
		}
		else {
			++$qll;
		}
	}
	else {
		if ($ny < $ymid) {
			++$qur;
		}
		else {
			++$qlr;
		}
	}
}

say STDERR "Quandarnt counts: $qul, $qur, $qll, $qlr";

say ($qul * $qur * $qll * $qlr);
