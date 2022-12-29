#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

use Object::Pad; # Day 22 I'm finally busting O:P

my sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @grid;

while (<>) {
	chomp;
	last unless length;
	/^[ .#]+$/ or die "Input error";
	push @grid, $_;
}

my $pts = List::Util::sum0 map { length } map { split /\s+/ } @grid;
my $vl = int(sqrt($pts / 6));

my $max_x = List::Util::max map { length } @grid;

class Face {
	my $faceid;

	field $id :reader;
	BUILD { $id = $faceid++; }

	method name { "Face($id)"; }

	#use overload '""' => method { "Face($id)" };

	# Top-left position of this face in the 2D grid
	field $posx :param :reader;
	field $posy :param :reader;

	BUILD { say STDERR "Face($id) created from grid x=$posx, y=$posy"; }

	method face_coord($grid_x, $grid_y) {
		my $face_x = $grid_x - $posx;
		my $face_y = $grid_y - $posy;
		assert(0 <= $face_x < $vl);
		assert(0 <= $face_y < $vl);
		return ($face_x, $face_y);
	}

	method grid_coord($face_x, $face_y) {
		return (($face_x + $posx), ($face_y + $posy));
	}

	method cx { int($posx / $vl); }
	method cy { int($posy / $vl); }

	# Each of the faces bordering this face
	field $north :reader;
	field $east :reader;
	field $south :reader;
	field $west :reader;

	# The orientation, in terms of number of rotations of the face relative to this one
	# This also informs how to adjust the positioning and direciton of movement when crossing the border
	# For example, 0 means these faces are "oriented" the same way such that no change of direction is required.
	# -> If we exit our face from a certain border, we'll enter the neighbor face from the opposite border, moving the same direction, and with the same row or column offset.
	# 1 means the neighbor face is rotated 90 degrees clockwise relative to this one
	# -> Row offset will be translated into column offset - and vice versa - but may be inverted.
	# -> The north border exits into the target's east, with inverted offset
	# -> The east border exits into the target's south, with normal offset
	# -> The south border exits into the target's west, with inverted offset
	# -> The west border exits into the target's north, with normal offset
	# 2 means the neighbor face is rotated 180 degrees relative to this one
	# -> When exiting a border, we will enter from the SAME border in the neighbor, with inverted offset
	# 3 means the neighbor face is rotated 270 degrees clockwise (or 90 degrees anticlockwise) relative to this face
	# -> North border exits into the target's west, with normal offset
	# -> East border exits into the target's north, with inverted offset
	# -> South border exits into the target's east, with normal offset
	# -> West border exits into the target's south, with inverted offset
	# Postconditions:
	# Connecting two same-direction faces: both faces should have rotation value 0
	# Connecting two inverted faces: both faces should have rotation value 2
	# Connecting two rotated faces: one face should have 1, the other should have 3
	# Effecitvely, in all cases, the sum of the rotation values modulo 4 should be 0, and the required rotation value for the opposite face can be attained by (4 - <this side>) % 4
	field $rotation_north :reader;
	field $rotation_east :reader;
	field $rotation_south :reader;
	field $rotation_west :reader;

	method dump {
		say STDERR "${\$self->name}:";
		defined($north) and say STDERR "\tNorth is ${\$north->name} - rotation $rotation_north";
		defined($east) and say STDERR "\tEast is ${\$east->name} - rotation $rotation_east";
		defined($south) and say STDERR "\tSouth is ${\$south->name} - rotation $rotation_south";
		defined($west) and say STDERR "\tWest is ${\$west->name} - rotation $rotation_west";
	}

	method $connect_edge ($other, $side, $rotation) {
		assert($side =~ m/^(?:north|south|east|west)$/);
		assert(defined($rotation));
		say STDERR "Connecting ${\$self->name} to ${\$other->name} on $side rotation $rotation";
		if ($side eq 'north') { assert(!defined($north) || ($north == $other && $rotation_north == $rotation)); $north = $other; $rotation_north = $rotation; }
		if ($side eq 'south') { assert(!defined($south) || ($south == $other && $rotation_south == $rotation)); $south = $other; $rotation_south = $rotation; }
		if ($side eq 'east')  { assert(!defined($east)  || ($east  == $other && $rotation_east  == $rotation)); $east  = $other; $rotation_east  = $rotation; }
		if ($side eq 'west')  { assert(!defined($west)  || ($west  == $other && $rotation_west  == $rotation)); $west  = $other; $rotation_west  = $rotation; }
	}

	method connect_north ($other, $rotation) {
		assert($other->isa("Face"));
		assert(0 <= $rotation < 4);
		state @opposite = qw/south east north west/;
		my $opp = $opposite[$rotation];
		my $other_rot = (4 - $rotation) % 4;
		$self->$connect_edge($other, north => $rotation);
		$other->$connect_edge($self, $opp => $other_rot);
	}
	method connect_east ($other, $rotation) {
		assert($other->isa("Face"));
		assert(0 <= $rotation < 4);
		state @opposite = qw/west south east north/;
		my $opp = $opposite[$rotation];
		my $other_rot = (4 - $rotation) % 4;
		$self->$connect_edge($other, east => $rotation);
		$other->$connect_edge($self, $opp => $other_rot);
	}
	method connect_south ($other, $rotation) {
		assert($other->isa("Face"));
		assert(0 <= $rotation < 4);
		state @opposite = qw/north west south east/;
		my $opp = $opposite[$rotation];
		my $other_rot = (4 - $rotation) % 4;
		$self->$connect_edge($other, south => $rotation);
		$other->$connect_edge($self, $opp => $other_rot);
	}
	method connect_west ($other, $rotation) {
		assert($other->isa("Face"));
		assert(0 <= $rotation < 4);
		state @opposite = qw/east north west south/;
		my $opp = $opposite[$rotation];
		my $other_rot = (4 - $rotation) % 4;
		$self->$connect_edge($other, west => $rotation);
		$other->$connect_edge($self, $opp => $other_rot);
	}

	method is_complete () { defined($north) && defined($east) && defined($south) && defined($west); }

	method is_connected ($other) {
		(defined($north) && $north == $other) ||
		(defined($east) && $east == $other) ||
		(defined($south) && $south == $other) ||
		(defined($west) && $west == $other)
	}

	method has_corner () {
		(defined($north) && defined($west) && !$north->is_connected($west)) ||
		(defined($north) && defined($east) && !$north->is_connected($east)) ||
		(defined($south) && defined($west) && !$south->is_connected($west)) ||
		(defined($south) && defined($east) && !$south->is_connected($east));
	}

	# Due to all the crosslinking, we'll need a way to manually unlink the faces
	method Dispose () {
		undef $north;
		undef $west;
		undef $south;
		undef $east;
	}

	my sub invert($pos) { $vl - 1 - $pos; }

	# Returns: new_face, face_x, face_y, dx, dy
	method move ($face_x, $face_y, $dx, $dy) {
		my $face = $self;
		assert(($dx != 0) != ($dy != 0));
		assert(abs($dx) + abs($dy) <= 1);
		# North/South borders must invert their offset on 1 and 2 rotation
		# East/West borders must invert their offset on 2 and 3 rotation
		if ($face_y + $dy < 0) {
			# Moved off the north border.
			# 0 -> Enters south, 1 -> Enters east, 2 -> Enters north, 3 -> Enters west
			if ($rotation_north == 0) { return $north, $face_x, ($vl - 1), 0, -1; }
			if ($rotation_north == 1) { return $north, ($vl - 1), invert($face_x), -1, 0; }
			if ($rotation_north == 2) { return $north, invert($face_x), 0, 0, 1; }
			if ($rotation_north == 3) { return $north, 0, $face_x, 1, 0; }
			die;
		}
		elsif ($face_y + $dy >= $vl) {
			# moved off the south border
			# 0 -> Enters north, 1 -> Enters west, 2 -> Enters south, 3 -> Enters east
			if ($rotation_south == 0) { return $south, $face_x, 0, 0, 1; }
			if ($rotation_south == 1) { return $south, 0, invert($face_x), 1, 0; }
			if ($rotation_south == 2) { return $south, invert($face_x), ($vl - 1), 0, -1; }
			if ($rotation_south == 3) { return $south, ($vl - 1), $face_x, -1, 0; }
			die;
		}
		elsif ($face_x + $dx < 0) {
			# moved off the west border
			# 0 -> Enters east, 1 -> North, 2 -> west, 3 -> south
			if ($rotation_west == 0) { return $west, ($vl - 1), $face_y, -1, 0; }
			if ($rotation_west == 1) { return $west, $face_y, 0, 0, 1; }
			if ($rotation_west == 2) { return $west, 0, invert($face_y), 1, 0; }
			if ($rotation_west == 3) { return $west, invert($face_y), ($vl - 1), 0, -1; }
			die;
		}
		elsif ($face_x + $dx >= $vl) {
			# moved off the east border
			# 0 -> enters west, 1 -> enters south, 2 -> enters east, 3 -> enters north
			if ($rotation_east == 0) { return $east, 0, $face_y, 1, 0; }
			if ($rotation_east == 1) { return $east, $face_y, ($vl - 1), 0, -1; }
			if ($rotation_east == 2) { return $east, ($vl - 1), invert($face_y), -1, 0; }
			if ($rotation_east == 3) { return $east, invert($face_y), 0, 0, 1; }
			die;
		}
		else {
			return $self, $face_x + $dx, $face_y + $dy, $dx, $dy;
		}
	}

}

class Cube {
	field @faces;

	method add_face ($face) {
		assert($face->isa("Face"));
		assert(@faces < 6);
		push @faces, $face;
	}

	method faces (@which) {
		assert (wantarray||@which <= 1);
		@which < 0 and return @faces;
		@which > 0 and return @faces[@which];
		return $faces[$which[0]];
	}

	method get_face ($grid_x, $grid_y) {
		my $cx = int($grid_x / $vl);
		my $cy = int($grid_y / $vl);
		assert((my ($face) = grep { $_->cx == $cx && $_->cy == $cy } @faces) <= 1);
		return $face;
	}

	method complete_cube () {
		assert(@faces == 6);
		while (my (@remain) = grep { !$_->is_complete } @faces) {
			my @candidates = grep { $_->has_corner } @faces;
			assert scalar(@candidates);
			for my $candidate (@candidates) {
				print STDERR "Completing for candidate ";
				$candidate->dump;
				my $n = $candidate->north;
				my $e = $candidate->east;
				my $s = $candidate->south;
				my $w = $candidate->west;
				my $rn = $candidate->rotation_north;
				my $re = $candidate->rotation_east;
				my $rs = $candidate->rotation_south;
				my $rw = $candidate->rotation_west;
				if (defined($n) && defined($e)) {
					# If we now have a complete corner we can also complete a connection on that edge.
					# N 0 + E 0 = E (N)->N (E) 1, N 0 + E 1 = E (W)->N (E) 0, N 0 + E 2 = E (S)->N (E) 3, N 0 + E 3 = E (E)->N (E) 2
					# N 1 + E 0 = E->N (N) 2, N 1 + E 1 (W) = E->N 1
					# N 2 + E 0 = E->N (N) 3
					# N 3 + E 0 = E->N (N) 0
					my @east_faces = qw/north west south east/;
					my $eton_face = $east_faces[$re];
					my $eton_rotate = (17 + ($rn - $re)) % 4;
					my $connect = $e->can("connect_$eton_face");
					$e->$connect($n, $eton_rotate);
				}
				if (defined($n) && defined($w)) {
					# N 0 + W 0 = W (N)->N (W) 3, N 0 + W 1 = W (W)->N (W) 2, N 0 + W 2 = W (S)->N (W) 1, N 0 + W 3 (W) = W (E)->N (W) 0
					# N 1 + W 0 = W (N)->N (S) 0, N 1 + W 2 = W (W)->N (S) 3
					# N 2 + W 0 = W->N (N) 1
					# N 3 + W 0 = W->N (N) 2
					my @west_faces = qw/north west south east/;
					my $wton_face = $west_faces[$rw];
					my $wton_rotate = (15 + ($rn - $rw)) % 4;
					my $connect = $w->can("connect_$wton_face");
					$w->$connect($n, $wton_rotate);
				}
				if (defined($s) && defined($e)) {
					# S 0 + E 0 = E (S)->S (E) 3, S 0 + E 1 = E (E)->S (E) 2, S 0 + E 2 = E (N)->S (E) 1, S 0 + E 3 = E (W)->S (E) 0
					# S 1 + E 0 = E (S)->S (N) 0, S 1 + E 1 = E (E)->S (N) 3
					my @east_faces = qw/south east north west/;
					my $etos_face = $east_faces[$re];
					my $etos_rotate = (15 + ($rs - $re)) % 4;
					my $connect = $e->can("connect_$etos_face");
					$e->$connect($s, $etos_rotate);
				}
				if (defined($s) && defined($w)) {
					# S 0 + W 0 = W->S (S) 1
					my @west_faces = qw/south east north west/;
					my $wtos_face = $west_faces[$rw];
					my $wtos_rotate = (17 + ($rs - $rw)) % 4;
					my $connect = $w->can("connect_$wtos_face");
					$w->$connect($s, $wtos_rotate);
				}
				print STDERR "Result of completion for ";
				$candidate->dump;
			}
		}
	}

	# He who owns Disposables shall himself be Disposable
	method Dispose () {
		$_->Dispose() for @faces;
		undef @faces;
	}
}

my $cube = Cube->new();
END { defined($cube) and $cube->Dispose(); }

for (my $y = 0; $y < @grid; $y += $vl) {
	my $row = $grid[$y];
	for (my $x = 0; $x < length($row); $x += $vl) {
		next if substr($row, $x, 1) eq ' ';
		my $face = Face->new(posx => $x, posy => $y);
		$cube->add_face($face);
		# Can we bind to a west face (with no rotation)
		if (($x - $vl) >= 0) {
			if (defined(my $west = $cube->get_face(($x - $vl), $y))) {
				$face->connect_west($west, 0);
			}
		}
		if (($y - $vl) >= 0) {
			if (defined(my $north = $cube->get_face($x, ($y - $vl)))) {
				$face->connect_north($north, 0);
			}
		}
	}
}

$cube->complete_cube();

my $dx = 1;
my $dy = 0;

chomp(my $dirline = scalar <>);

my @dir = split /([LR])/, $dirline;

my $curface = $cube->faces(0);

my $facex = 0;
my $facey = 0;

while (@dir) {
	my $cmd = shift @dir;
	if ($cmd eq 'L') {
		($dx, $dy) = ($dy, -$dx);
	}
	elsif ($cmd eq 'R') {
		($dx, $dy) = (-$dy, $dx);
	}
	else {
		while ($cmd--) {
			my ($newface, $newx, $newy, $newdx, $newdy) = $curface->move($facex, $facey, $dx, $dy);
			my ($gx, $gy) = $newface->grid_coord($newx, $newy);
			last if substr($grid[$gy], $gx, 1) eq '#';
			$curface = $newface;
			$facex = $newx;
			$facey = $newy;
			$dx = $newdx;
			$dy = $newdy;
		}
	}
}

my ($final_posx, $final_posy) = $curface->grid_coord($facex, $facey);

my %facekey = ("1,0" => 0, "0,1" => 1, "-1,0" => 2, "0,-1" => 3);

say STDERR "Final position: x=$final_posx, y=$final_posy, dx=$dx, dy=$dy";

my $score = (1000 * ($final_posy + 1)) + (4 * ($final_posx + 1)) + $facekey{"$dx,$dy"};

say $score;
