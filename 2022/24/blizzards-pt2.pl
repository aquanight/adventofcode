#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

use Object::Pad;

my sub assert { shift or Carp::confess "ASSERT FAIL"; }

class Point {
	field $x :param :reader;
	field $y :param :reader;

	method $Deconstruct () {
		assert wantarray;
		return ($x, $y);
	}

	method add ($other, $swapped=!1) {
		assert($other->isa("Point"));
		my ($ox, $oy) = $other->$Deconstruct();
		Point->new(x => $x + $ox, y => $y + $oy);
	}

	method scale ($other, $swapped=!1) {
		assert(!ref($other));
		Point->new(x => $x * $other, y => $y * $other);
	}

	method wrap ($other, $swapped=!1) {
		assert !$swapped;
		assert $other->isa("Point");
		my ($dx, $dy) = $other->$Deconstruct();
		my $qx = $x / $dx;
		my $qy = $y / $dy;
		my $rx = $x % $dx;
		my $ry = $y % $dy;
		# Change truncated division/modulus (remainder has the sign of the dividend) to floored (remainder has the sign of the divisor)
		if ($rx * $dx < 0) { --$qx; $rx += $dx; }
		if ($ry * $dy < 0) { --$qy; $ry += $dy; }
		return Point->new(x => $rx, y => $ry);
	}

	method new_with (%args) {
		%args = (x => $x, y => $y, %args);
		Point->new(%args);
	}

	method Equals($other, $swapped=!1) {
		assert $other->isa("Point");
		return ($x == $other->x) && ($y == $other->y);
	}

	field $key;
	method GetHashCode () { $key //= "Point($x,$y)"; }

	use overload '+' => \&add, '*' => \&scale, '%' => \&wrap, '==' => \&Equals, '!=' => method ($other, $swapped) { !$self->Equals($other, $swapped) }, fallback => 1;

	method abs () { abs($x) + abs($y); }
}

use constant UP => Point->new(x => 0, y => -1);
use constant DOWN => Point->new(x => 0, y => 1);
use constant LEFT => Point->new(x => -1, y => 0);
use constant RIGHT => Point->new(x => 1, y => 0);
use constant WAIT => Point->new(x => 0, y => 0);

my %blizzchr = (
	'>' => RIGHT,
	'^' => UP,
	'<' => LEFT,
	'v' => DOWN,
);

my $field_width;
my $field_height;

my $start_x;

my $target_x;

my $size;

class Blizzard {
	field $base :param :reader;
	field $dir :param :reader;
	BUILD {
		assert(defined $base);
		assert($base->isa("Point"));
		assert(defined $dir);
		assert($dir->isa("Point"));
		assert(($dir->x != 0) != ($dir->y != 0));
		assert($dir->abs() == 1);
	}

	method get_pos($turn) {
		my $bp = ($base + ($dir * $turn)) % $size;
		assert ($dir->x != 0 || ($bp->x == $base->x));
		assert ($dir->y != 0 || ($bp->y == $base->y));
		return $bp;
	}
}

# The blizzards move the same way every turn.
my @blizzards;

while (<>) {
	chomp;
	if (/^#+(\.)#+$/) {
		# Top or bottom border
		my $pos = $-[1];
		if (!defined($start_x)) {
			$start_x = $pos - 1;
			$field_width = length($_) - 2;
		}
		elsif (!defined($target_x)) {
			$target_x = $pos - 1;
			$field_height = ($. - 2);
		}
		else {
			die "WTF";
		}
	}
	elsif (/^#[\^><v.]+#$/) {
		assert defined($start_x);
		assert !defined($target_x);
		my $y = ($. - 2);
		while (/[\^><v]/g) {
			my $x = $-[0] - 1;
			my $dir = $blizzchr{$&};
			assert defined($dir);
			push @blizzards, Blizzard->new(base => Point->new(x => $x, y => $y), dir => $dir);
		}
	}
	else { die "Input error [$_]"; }
}

$size = Point->new(x => $field_width, y => $field_height);
printf STDERR "Board size is %s\n", $size->GetHashCode();

my $start = Point->new(x => $start_x, y => -1);
my $goal = Point->new(x => $target_x, y => $field_height);

# The LCM of the field width/height: the entire blizzard map is circular on this value.
my $blizlcm;

{
	my ($x, $y) = ($field_width, $field_height);
	while ($y != 0) {
		($x, $y) = ($y, $x % $y);
	}
	$blizlcm = $field_width * $field_height / $x;
}

my @blizzmap;
my sub get_blizzmap($turn) {
	$turn %= $blizlcm;
	unless (defined $blizzmap[$turn]) {
		my %map = ();
		for my $bliz (@blizzards) {
			my $pos = $bliz->get_pos($turn);
			my $key = $pos->GetHashCode();
			$map{$key} = 1;
		}
		$blizzmap[$turn] = \%map;
	}
	return $blizzmap[$turn];
}

# States we have seen, which consist of: player's position, blizzard map position, and how many turns it's taken.
# The last part is the "variable" of the state: if we see the same state but with more turns, we can discard it.
# We do have to track map position, but keep in mind it's a function of the turn count as it is.
my %states;

my $best_finish;

my $leg_length = abs($start->x - $goal->x) + abs($start->y - $goal->y);

class State {
	field $pos :param :reader;
	field $turn :param :reader;
	field $leg :param :reader;

	method is_start () { $pos == $start }
	method is_goal () { $pos == $goal }

	method is_done () { $pos == $goal && $leg == 2 }

	method move($dir) {
		assert $dir->isa("Point");
		assert $dir->abs() <= 1;
		assert(!(($dir->x != 0) && ($dir->y != 0)));
		my $new = $pos + $dir;
		if ($new != $goal && $new != $start) {
			my $wrapped = $new % $size;
			#printf STDERR "\t\t\tOrig=%s, Moved=%s, Wrapped=%s\n", $pos->GetHashCode(), $new->GetHashCode(), $wrapped->GetHashCode();
			if (($new % $size) != $new) { return undef; }
		}
		my $_leg;
		if ($leg == 0) { $_leg = ($new == $goal) ? 1 : 0; }
		elsif ($leg == 1) { $_leg = ($new == $start) ? 2 : 1; }
		else { $_leg = 2; }
		return State->new(pos => $new, turn => $turn + 1, leg => $_leg);
	}

	method start_dist () {
		my $dx = abs($pos->x - $start->x);
		my $dy = abs($pos->y - $start->y);
		return ($dx + $dy);
	}

	method goal_dist () {
		my $dx = abs($pos->x - $goal->x);
		my $dy = abs($pos->y - $goal->y);
		return ($dx + $dy);
	}

	method total_dist () {
		if ($leg == 0) { return $self->goal_dist + (2 * $leg_length); }
		if ($leg == 1) { return $self->start_dist + $leg_length; }
		if ($leg == 2) { return $self->goal_dist; }
	}

	method is_snowed () {
		#for my $bliz (@blizzards) {
		#	my $bp = $bliz->get_pos($turn);
		#	#printf "\t\tBlizzard started at %s moving %s for %d turns now at %s\n", $bliz->base->GetHashCode(), $bliz->dir->GetHashCode(), $turn, $bp->GetHashCode();
		#	if ($bp == $pos) { return 1; }
		#}
		#return !1;
		my $key = $pos->GetHashCode();
		return !!get_blizzmap($turn)->{$key};
	}

	method check_viable () {
		return "" if defined($best_finish) && $turn >= $best_finish;
		my $key = sprintf "%s:%d:%d", $pos->GetHashCode(), $turn % $blizlcm, $leg;
		return 1 unless defined $states{$key};
		return $states{$key} > $turn;
	}

	method remember () {
		my $key = sprintf "%s:%d:%d", $pos->GetHashCode(), $turn % $blizlcm, $leg;
		unless ($states{$key}//$turn < $turn) {
			$states{$key} = $turn;
		}
	}
}

my @missed_guess;
my @next_batch;
my @states = (State->new(pos => Point->new(x => $start_x, y => -1), turn => 0, leg => 0));

# This our current guess of our goal time. Use this to try to sort out nodes that can reach that time vs those that don't.
my $guess = $states[0]->total_dist;

say STDERR "Initial guess for time is $guess";

while (@states + @next_batch + @missed_guess) {
	if (@states < 1) {
		if (@next_batch < 1) {
			my $old_guess = $guess;
			# We're just going to process all missed guesses but they'll eventually separate back out into those still viable and those that are not
			$guess = List::Util::min map { $_->turn + $_->total_dist } @missed_guess;
			my @mg = @missed_guess;
			undef @missed_guess;
			for my $mg (@mg) {
				if ($mg->turn + $mg->total_dist <= $guess) {
					push @states, $mg;
				}
				else {
					push @missed_guess, $mg;
				}
			}
			assert scalar(@states);
			$guess = $states[0]->turn + $states[0]->total_dist;
			printf STDERR "Missed guess of %d, new guess is %d, with %d states (and %d more missed)\n", $old_guess, $guess, scalar(@states), scalar(@missed_guess);
		}
		else {
			@states = @next_batch;
			@next_batch = ();
			printf STDERR "Processing next batch of %d states (current guess is %d)\n", scalar(@states), $guess;
		}
	}
	my $state = shift @states;
	#printf STDERR "[%d] Processing state pos=%s turn=%d dist=%d (best=%s)\n", scalar(@states), $state->pos->GetHashCode(), $state->turn, $state->total_dist, ($best_finish//"<none>");
	$state->remember();
	if ($state->is_done) {
		if (!defined($best_finish) || $state->turn < $best_finish) {
			$best_finish = $state->turn;
			# Purge states that we know can't finish in the new best time
			my @keep = grep { $_->turn + $_->total_dist < $best_finish; } @states;
			printf STDERR "\tNew best time %d, dropped %d states\n", $best_finish, scalar(@states) - scalar(@keep);
			@states = @keep;
		}
		next;
	}
	if (defined($best_finish) && ($state->turn + $state->total_dist) >= $best_finish) {
		#say STDERR "\tDropping due to DNF";
		next;
	}
	for my $move (UP, LEFT, DOWN, RIGHT, WAIT) {
		#printf STDERR "\tConsidering move dx=%d, dy=%d : ", $move->x, $move->y;
		my $ns = $state->move($move);
		unless (defined $ns) {
			#say STDERR "hit wall";
			next;
		}
		if ($ns->is_snowed) {
			#say STDERR "snowed in";
			next;
		}
		if ($ns->check_viable()) {
			#say STDERR "accepted";
			$ns->remember();
			if ($ns->turn + $ns->total_dist > $guess) { push @missed_guess, $ns; }
			else { push @next_batch, $ns; }
		}
		else {
			#say STDERR "redundant";
		}
	}
}

say $best_finish;
