#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %walls;

my ($sx, $ex);
my ($sy, $ey);

my $xw = 0;
my $yw = 0;

while (<>) {
	chomp;
	$xw = length if $xw < length;
	while (/#/g) {
		my $x = $-[0];
		$walls{"$x,$yw"} = 1;
	}
	pos() = 0;
	if (/S/) { $sx = $-[0]; $sy = $yw; }
	pos() = 0;
	if (/E/) { $ex = $-[0]; $ey = $yw; }
	++$yw;
}

my @q = [ $sx, $sy, 0 ]; # ( X, Y, steps )

my %seen;

use constant DIRS => [ 1, 0 ], [ -1, 0 ], [ 0, 1 ], [ 0, -1 ];

while (@q)
{
	my ($x, $y, $steps) = (shift @q)->@*;
	next if (defined($seen{"$x,$y"}) && $seen{"$x,$y"} <= $steps);
	$seen{"$x,$y"} = $steps;

	for my $dir (DIRS) {
		my ($dx, $dy) = @$dir;
		my $nx = $x + $dx;
		my $ny = $y + $dy;

		next if $nx < 0 || $nx >= $xw || $ny < 0 || $ny >= $yw;
		next if $walls{"$nx,$ny"};
		push @q, [ $nx, $ny, $steps + 1 ];
	}
}

say STDERR "Base path to end takes " . $seen{"$ex,$ey"};

my %cheat;

# find valid cheat locations
for my $s (keys %seen) {
	my ($x, $y) = split /,/, $s;
	my $base = $seen{"$x,$y"};
	for my $s2 (keys %seen) {
		my ($nx, $ny) = split /,/, $s2;
		my $val = $seen{"$nx,$ny"};
		my $dx = $nx - $x;
		my $dy = $ny - $y;
		my $dist = abs($dx) + abs($dy);
		next if $dist > 20;
		my $save = $base - ($val + $dist);
		next if $save < 1;
		$cheat{$save}++;
	}
}

say STDERR "Total cheat counts:";
for my $cht (sort { $a <=> $b } keys %cheat) {
	say STDERR "$cht ps : $cheat{$cht}";
}

use List::Util ();

say List::Util::sum map { $cheat{$_} } grep { $_ >= 100 } keys %cheat;
