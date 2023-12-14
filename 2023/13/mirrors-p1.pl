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
		$_ = 1 for @xrp[1 .. ($width - 1)];
		for my $m (@map) {
			for my $xrp (grep { $xrp[$_] } keys @xrp) {
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
				if ($l ne $r) {
					$xrp[$xrp] = 0;
				}
			}
		}
		$xr = List::Util::first { $xrp[$_] } keys @xrp;
		$xr //= 0;
	}
	for my $y ( 1 .. $#map ) {
		my @up = reverse @map[0 .. ($y - 1)];
		my @dn = @map[$y .. $#map];
		if (@up < @dn) {
			if (List::Util::all { $up[$_] eq $dn[$_] } 0 .. $#up) {
				$yr = $y;
			}
		}
		else {
			if (List::Util::all { $up[$_] eq $dn[$_] } 0 .. $#dn) {
				$yr = $y;
			}
		}
	}
	if ($xr == 0 && $yr == 0) {
		say STDERR "Uh oh (no line found)";
		say STDERR $_ for @map;
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
