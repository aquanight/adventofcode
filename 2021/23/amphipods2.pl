#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

# Layout:
# A hallway stack has a capcity of 1
# A room stack has a capacity of 2 but does not block movement even if full (its hall space is always empty)
# From left to right the stacks are:
# hall, hall, room A, hall, room B, hall, room C, hall, room D, hall, hall

my @pos = ( '', '', [], '', [], '', [], '', [], '', '');

my %goal;
my @goal;
BEGIN {
%goal = (
	A => 2,
	B => 4,
	C => 6,
	D => 8,
);
@goal = ('', '', 'A', '', 'B', '', 'C', '', 'D', '', '');
}

# Read the initial position.
my ($AT, $BT, $CT, $DT);
my ($AB, $BB, $CB, $DB);

my %cost = (
	A => 1,
	B => 10,
	C => 100,
	D => 1000,
);

<> =~ m/^#############$/ or die "Input error";
<> =~ m/^#...........#$/ or die "Input error";
($AT, $BT, $CT, $DT) = <> =~ m/^###([ABCD])#([ABCD])#([ABCD])#([ABCD])###$/ or die "Input error";
($AB, $BB, $CB, $DB) = <> =~ m/^  #([ABCD])#([ABCD])#([ABCD])#([ABCD])#\s*$/ or die "Input error";
<> =~ m/^  #########\s*$/ or die "Input error";

push $pos[2]->@*, $AB, qw/D D/, $AT;
push $pos[4]->@*, $BB, qw/B C/, $BT;
push $pos[6]->@*, $CB, qw/A B/, $CT;
push $pos[8]->@*, $DB, qw/C A/, $DT;

use Data::Dumper ();

sub packstate ($state_array) {
	return join ":", map {
		ref ? join("", @$_) : $_
	} @$state_array;
}

use constant SOLVED => do {
	my @solvedpos = ('', '', [], '', [], '', [], '', [], '', '');
	$solvedpos[$_]->@* = ($goal[$_]) x 4 for (2, 4, 6, 8);
	packstate(\@solvedpos);
};

sub unpackstate ($state_string) {
	my @state = split /:/, $state_string, -1;
	for my $ix (2, 4, 6, 8) {
		$state[$ix] = [ split //, $state[$ix] ];
	}
	return \@state;
}

sub move($state, $from, $to) {
	my \@state = unpackstate $state;
	#Carp::cluck(Data::Dumper->Dump([\@state]));
	assert 0 <= $from <= 11;
	assert 0 <= $to <= 11;
	return () if $from == $to; # Skip null movements.
	my $f = $state[$from];
	my $t = $state[$to];
	my $moving;
	my ($upcost, $downcost);
	ref($f)||ref($t) or return (); # Not legal unless we're coming from a room or going to a room (we can go room to room directly).
	if (ref($f)) {
		# Do not "move" from a room if there are only "right" pods in that room. There's no point in doing this.
		# This should also pick out empty rooms.
		grep { $_ ne $goal[$from] } @$f or return ();
		$moving = pop @$f;
		$upcost = 4 - @$f;
	}
	else {
		$moving = $f;
		$state[$from] = "";
		$upcost = 0;
	}
	length $moving or return ();
	if (ref($t)) {
		# Cannot move to this room if it is the "wrong" room.
		$moving eq $goal[$to] or return ();
		# Cannot move into a room if it is full, or if it contains a "wrong" pod.
		# (In theory, if we're moving to a "right" room and it's full, it would have to contain a "wrong" pod.)
		grep { $_ ne $goal[$to] } @$t and return ();
		assert @$t < 4;
		$downcost = 4 - @$t;
	}
	else {
		$downcost = 0;
	}
	# Now we must check the path between the two points. We can assume the space "outside" a room is always free.
	my @path_check = $from < $to ? ($from + 1) .. $to : $to .. ($from - 1);
	List::Util::all { ref || !length } @state[@path_check] or return (); # No clean path
	if (ref($t)) {
		push @$t, $moving;
	}
	else {
		$state[$to] = $moving;
	}
	return packstate(\@state), (($upcost + $downcost + abs($from - $to)) * $cost{$moving});
}

# A given state contains an hash of states if it's not yet been solved or a string representing the final state if it has been solved at the score.
my %state = (0 => { (packstate \@pos) => 1 });

sub add_state ($score, $state) {
	exists $state{$score} or $state{$score} = {};
	ref $state{$score} or return; # It's already been solved, stop.
	if ($state eq SOLVED) {
		$state{$score} = $state;
	}
	else {
		$state{$score}{$state} = 1;
	}
}

sub valid_from ($state) {
	my \@state = unpackstate $state;
	my @valid;
	for my $ix ( 0 .. 10 ) {
		if (ref $state[$ix]) {
			grep { $_ ne $goal[$ix] } $state[$ix]->@* or next;
			push @valid, $ix;
		}
		elsif (length $state[$ix]) {
			push @valid, $ix;
		}
	}
	return @valid;
}

my $lastreport = 0;
my $result;

until (defined $result) {
	my @scores = sort { $a <=> $b } keys %state;
	my $lowest = shift @scores;
	my $states = delete $state{$lowest};
	if ($lastreport + 1000 < $lowest) {
		say STDERR "Processing score $lowest";
		$lastreport = $lowest;
	}
	unless (length ref($states)) {
		say STDERR "Solution $states with score $lowest";
		$result = $lowest;
		last;
	}
	for my $state (keys %$states) {
		#say "Processing state $state";
		my $roomed = 0;
		for my $f ( valid_from $state ) {
			# Check to see if any pod can be solved. If so, add only states that "solve" a pod from this position: don't waste time with move-outs.
			for my $t ( 2, 4, 6, 8 ) {
				if (my ($newstate, $cost) = move($state, $f, $t)) {
					add_state(($lowest + $cost) => $newstate);
					$roomed = 1;
				}
			}
		}
		next if $roomed;
		for my $f ( valid_from $state ) {
			# No room moves, look for hallway moves.
			for my $t ( 0, 1, 3, 5, 7, 9, 10 ) {
				if (my ($newstate, $cost) = move($state, $f, $t)) {
					add_state(($lowest + $cost) => $newstate);
					$roomed = 1;
				}
			}
		}
	}
}

say "Lowest cost to sort: $result";
