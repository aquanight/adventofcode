#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @paths;

my @stopped_sand;

my $void_y; # The furthest Y goes in any path: sand falling past this has fallen into the void

while (<>) {
	chomp;
	my @points = split /\s*->\s*/;
	my $path = [ map { split /\s*,\s*/ } @points ];
	for (my $ix = 1; $ix < @$path; $ix += 2) {
		$void_y = defined($void_y) && $void_y > $path->[$ix] ? $void_y : $path->[$ix];
	}
	push @paths, $path;
}


SAND: while (1) {
	my $sand_x = 500;
	my $sand_y = 0;

	MOVE: while (1) {
		my $can_down = 1;
		my $can_downleft = 1;
		my $can_downright = 1;
		# Check paths for barricades
		for my $path (@paths) {
			for (my $ix = 2; $ix < @$path; $ix += 2) {
				my ($sx, $sy, $ex, $ey) = $path->@[$ix - 2, $ix - 1, $ix, $ix + 1];
				# Is this segment even relevant (no if it is entirely above or entirely below the target height)
				next if ($sy > ($sand_y + 1) && $ey > ($sand_y + 1)); # Entirely below
				next if ($sy < ($sand_y + 1) && $ey < ($sand_y + 1)); # Entirely above
				# If this is a vertical segment, it is relevant if and only if it comes within 1 block of the sand
				# (The above two conditions have assured that a vertical segment passes through the target height)
				next if ($ex == $sx && abs($sx - $sand_x) > 1); # Vertical segment far away from relevance
				# If this is a horizontal segment, it is relevant if either end point is near the sand, or if the two endpoints are on opposite sides of the sand
				# (Due to the first two conditions, we've effectively ensured this segment is AT the target height exactly.)
				if ($ey == $sy) {
					next unless (
						abs($sx - $sand_x) <= 1 ||
						abs($ex - $sand_x) <= 1 ||
						($sx < $sand_x) != ($ex < $sand_x)
					);
				}
				# If it's still relevant, it's in the way of at least one of the three points. Now which one(s)?
				if ($ex == $sx) {
					# Vertical segment can only block one of the three points.
					if ($sx == $sand_x) {
						$can_down = 0;
					}
					elsif ($sx == $sand_x - 1) {
						$can_downleft = 0;
					}
					elsif ($sx == $sand_x + 1) {
						$can_downright = 0;
					}
				}
				elsif ($ey == $sy) {
					# Horizontal segment can block any of the 3 (we've already checked it for good altitude)
					my ($lox, $hix) = $sx <= $ex ? ($sx, $ex) : ($ex, $sx);
					if ($lox <= $sand_x - 1 <= $hix) {
						$can_downleft = 0;
					}
					if ($lox <= $sand_x <= $hix) {
						$can_down = 0;
					}
					if ($lox <= $sand_x + 1 <= $hix) {
						$can_downright = 0;
					}
				}
				else {
					die "Confusion";
				}
			}
		}
		# Now check for existing sand
		for (my $ix = 0; $ix < @stopped_sand; $ix += 2) {
			my ($stop_x, $stop_y) = @stopped_sand[$ix, $ix + 1];
			next if ($stop_y != $sand_y + 1);
			if ($stop_x == $sand_x - 1) {
				$can_downleft = 0;
			}
			if ($stop_x == $sand_x) {
				$can_down = 0;
			}
			if ($stop_x == $sand_x + 1) {
				$can_downright = 0;
			}
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
			push @stopped_sand, $sand_x, $sand_y;
			last MOVE;
		}
		if ($sand_y > $void_y) {
			# Sand fell out of the world
			last SAND;
		}
	}
}

my $score = @stopped_sand/2;

say $score;
