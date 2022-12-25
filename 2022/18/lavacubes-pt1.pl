#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %cubes;

while (<>) {
	chomp;
	my ($x, $y, $z) = split /\s*,\s*/;

	$cubes{"$x,$y,$z"} = 1;
}


my $score = 0;

my @test = (
	1, 0, 0,
	-1, 0, 0,
	0, 1, 0,
	0, -1, 0,
	0, 0, 1,
	0, 0, -1,
);

for my $cube (keys %cubes) {
	my ($x, $y, $z) = split /,/, $cube;
	next unless $cubes{$cube};
	print STDERR "Cube x=$x, y=$y, z=$z :";
	my $sides = 0;
	for (my $tix = 0; $tix < @test; $tix += 3) {
		my ($dx, $dy, $dz) = @test[$tix .. (2 + $tix)];
		my $check = sprintf("%d,%d,%d", ($x + $dx), ($y + $dy), ($z + $dz));
		$cubes{$check} or ++$sides;
	}
	say STDERR " $sides sides not adjacent";
	#assert $sides < 6;
	$score += $sides;

}

say $score;
