#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs for_list/;

use Carp ();

my %ant;

my $xw = 0;
my $yw = 0;

while (<>) {
	chomp;
	$xw = length if $xw < length;
	++$yw;
	while (/[A-Za-z0-9]/g) {
		my $x = $+[0];
		$ant{"$x,$yw"} = $&;
	}
}

my @ant = keys %ant;

my %anti;

for my $a1 (@ant) {
	for my $a2 (@ant) {
		next if $a1 eq $a2;

		my $at1 = $ant{$a1};
		my $at2 = $ant{$a2};

		next unless $at1 eq $at2;

		my ($x1, $y1) = split /,/, $a1;
		my ($x2, $y2) = split /,/, $a2;

		my $dx = $x1 - $x2;
		my $dy = $y1 - $y2;

		my $antix = $x1;
		my $antiy = $y1;
		while ($antix > 0 && $antix <= $xw && $antiy > 0 && $antiy <= $yw) {
			$anti{"$antix,$antiy"} = 1;
			$antix += $dx;
			$antiy += $dy;
		}

		$antix = $x2;
		$antiy = $y2;
		while ($antix > 0 && $antix <= $xw && $antiy > 0 && $antiy <= $yw) {
			$anti{"$antix,$antiy"} = 1;
			$antix -= $dx;
			$antiy -= $dy;
		}

	}
}

say scalar keys %anti;
