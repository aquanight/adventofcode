#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

my @map;
my $width = 0;

my $sum = 0;

sub process () {
	my $xr = 0;
	my $yr = 0;
	{
		my @xrp = (0) x $width;
		for my $m (@map) {
			for my $xrp (grep { $xrp[$_] < 2 } keys @xrp) {
				my $ll = substr($m, 0, $xrp);
				my $l = reverse $ll;
				my $r = substr($m, $xrp);
				next unless length($l) && length($r);
				if (length $l > length $r) {
					$l = substr($l, 0, length($r));
				}
				if (length $r > length $l) {
					$r = substr($r, 0, length($l));
				}
				my @l = map { $_ eq '#' ? 1 : 0 } split //, $l;
				my @r = map { $_ eq '#' ? 1 : 0 } split //, $r;
				my $diff = List::Util::sum0 map { abs($l[$_] - $r[$_]) } keys @l;
				$xrp[$xrp] += $diff;
			}
		}
		$xr = List::Util::first { $xrp[$_] == 1 } keys @xrp;
		$xr //= 0;
	}
	for my $y ( 1 .. $#map ) {
		my @up = reverse @map[0 .. ($y - 1)];
		my @dn = @map[$y .. $#map];
		if (@up < @dn) {
			$#dn = $#up;
		} else {
			$#up = $#dn;
		}
		my @upchr = map { map { $_ eq '#' ? 1 : 0 } split //, $_ } @up;
		my @dnchr = map { map { $_ eq '#' ? 1 : 0 } split //, $_ } @dn;
		my $diff = List::Util::sum0 map { abs($upchr[$_] - $dnchr[$_]) } keys @upchr;
		if ($diff == 1) {
			$yr = $y;
			last;
		}
	}
	if ($xr == 0 && $yr == 0) {
		say STDERR "Uh oh (no line found)";
		say STDERR $_ for @map;
	}
	if ($xr != 0 && $yr != 0) {
		say STDERR "Uh oh (two lines found)";
		say STDERR $_ for @map;
		say STDERR "X: $xr";
		say STDERR "Y: $yr";
	}
	$sum += $xr + (100 * $yr);
	@map = ();
	$width = 0;
}

while (<>) {
	chomp;
	if (length) {
		/^[\.\#]+$/ or die "Input error";
		push @map, $_;
		$width ||= length $_;
	}
	else {
		process;
	}
}

process if @map;

say $sum;
