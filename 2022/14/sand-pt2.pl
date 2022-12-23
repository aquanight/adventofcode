#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @paths;

my @stopped_sand;

while (<>) {
	chomp;
	my @points = split /\s*->\s*/;
	my @path = map { split /\s*,\s*/ } @points;
	while (@path >= 4) {
		my $sx = shift(@path);
		my $sy = shift(@path);
		my ($ex, $ey) = @path[0, 1];
		assert($sx >= 0 && $sy >= 0 && $ex >= 0 && $ey >= 0);
		if ($sy == $ey) {
			if ($sy < 0) { next; }
			# Horizontal path
			if ($ex < $sx) {
				($sx, $ex) = ($ex, $sx);
			}
			for my $x ($sx .. $ex) {
				vec($paths[$sy], $x, 1) = 1;
			}
		}
		elsif ($sx == $ex) {
			if ($sy < 0 && $ey < 0) { next; }
			if ($sy < 0) { $sy = 0; }
			if ($ey < 0) { $ey = 0; }
			# Veritical path
			if ($ey < $sy) { ($sy, $ey) = ($ey, $sy); }
			for my $y ($sy .. $ey) {
				vec($paths[$y], $sx, 1) = 1;
			}
		}
	}
}

SAND: while (1) {
	my $sand_x = 500;
	my $sand_y = 0;

	MOVE: while (1) {
		my $can_down = 1;
		my $can_downleft = 1;
		my $can_downright = 1;
		# Check paths for barricades
		if (defined(my $row = $paths[$sand_y + 1])) {
			vec($row, $sand_x, 1) and $can_down = 0;
			vec($row, $sand_x - 1, 1) and $can_downleft = 0;
			vec($row, $sand_x + 1, 1) and $can_downright = 0;
		}
		# Now check for existing sand
		if (defined(my $row = $stopped_sand[$sand_y + 1])) {
			$row->{$sand_x} and $can_down = 0;
			$row->{$sand_x - 1} and $can_downleft = 0;
			$row->{$sand_x + 1} and $can_downright = 0;
		}
		# Now attempt to move the sand:
		if ($can_down) {
			$sand_y++;
		}
		elsif ($can_downleft) {
			$sand_x--;
			$sand_y++;
		}
		elsif ($can_downright) {
			$sand_x++;
			$sand_y++;
		}
		else {
			# The sand stops here.
			$stopped_sand[$sand_y]{$sand_x} = 1;
			if ($sand_y == 0) {
				last SAND;
			}
			last MOVE;
		}
		if ($sand_y > $#paths) {
			$stopped_sand[$sand_y]{$sand_x} = 1;
			last MOVE;
		}
	}
}

use List::Util ();

my $score = List::Util::sum0(map { scalar keys %$_ } @stopped_sand);

say $score;
