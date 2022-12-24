#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %valves;

while (<>) {
	print STDERR $_;
	chomp;
	my ($id, $rate, $links) = /^Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ([\w,\s]+)$/ or die;
	my @links = split /\s*,\s*/, $links;
	exists $valves{$id} and die "Duplicate valve";
	$valves{$id} = {
		rate => $rate,
		links => [ @links ],
	};
}

# Integrity-check the links
for my $vlv (values %valves) {
	for my $link ($vlv->{links}->@*) {
		exists $valves{$link} or die "Id '$link' not defined";
	}
}

use constant START => 'AA';

my %path_maps;

sub path_map ($from) {
	if (exists($path_maps{$from})) { return $path_maps{$from}->%*; }
	my @check = ($from);
	my %map = ($from => []);
	while (@check) {
		my $id = shift(@check);
		my @route = $map{$id}->@*;
		my @links = $valves{$id}{links}->@*;
		for my $link (@links) {
			exists $map{$link} and next;
			$map{$link} = [ @route, $link ];
			push @check, $link;
		}
	}
	$path_maps{$from} = \%map;
	return %map;
}

# A set of states to consider.
# 'current' is the current location
# 'open' is the hash of valves currently open
# 'score' is the total pressure released so far
# 'remain' is how many turns this route has left

my @paths;

$paths[26] = [ { player => 'AA', player_move => undef, player_done => 0, elephant => 'AA', elephant_move => undef, elephant_done => 0, open => {}, score => 0, remain => 26, route => '' } ];

my @current = ();

my $best = 0;

# The unique part of a given state can be expressed as the conjunction of:
# - Which valves are open
# - Where is the player
# - Where is the elephant
# - The amount of time remaining
# If we see such a state appear a second time and it turns out that such a state has a lower or equal score than the saved one, we can discard the incoming state.
my %dupstates;

sub addpath ($path) {
	my $ix = $path->{remain};
	my $state = sprintf "<%s>(%s:%s)", join(":", sort keys $path->{open}->%*), sort { $a cmp $b } ($path->{player}, $path->{elephant});
	# Optimization #1: If we've seen this state before and it is worse now than it was then, discard it.
	if (exists($dupstates{$state})) {
		my $val = $dupstates{$state};
		if (defined($val->[$path->{remain}]) && $val->[$path->{remain}] > $path->{score}) {
			#say STDERR "Dropping route [$path->{route}] due to previously seen score";
			return;
		}
		$val->[$path->{remain}] = $path->{score};
	}
	else {
		$dupstates{$state} = [];
		$dupstates{$state}[$path->{remain}] = $path->{score};
	}
	# Optimization #2: If this state can't ever beat our current top actual state, discard it.
	# This is based on the assumption idea that all remaining unopened valves are opened right this minute.
	{
		my $all_flow = List::Util::sum0 map { $valves{$_}{rate} } keys %valves;
		my $max_flow = $all_flow * ($path->{remain});
		if ($max_flow < 0) { $max_flow = 0; }
		my $max_score = $path->{score} + $max_flow;
		if ($max_score < $best) {
			#say STDERR "Dropping route [$path->{route}] because it cannot beat $best it has $path->{score} and can add $max_flow" if $path->{route} =~ /^:\(DD\)/;
			return;
		}
	}
	$paths[$ix]//=[];
	push $paths[$ix]->@*, $path;
}

sub pathstats {
	my $top = 7;
	for my $ix (reverse 0 .. $#paths) {
		ref $paths[$ix] or next;
		scalar $paths[$ix]->@* or next;
		printf STDERR "{%2d : %4d} ", $ix, scalar($paths[$ix]->@*);
		--$top or last;
	}
}

sub nextpath () {
	if (@current < 1) {
		for my $ix (0 .. $#paths) {
			unless (ref($paths[$ix])) {
				next;
			}
			unless (scalar $paths[$ix]->@*) {
				next;
			}
			(\@current, $paths[$ix]) = ($paths[$ix], \@current);
			pathstats;
			printf STDERR "[$ix] Process batch of %d routes (%d remain)...                    \r", scalar(@current), List::Util::sum0 map { defined($_) ? scalar(@$_) : 0 } @paths;
			$paths[$ix] = [];
			return shift @current;
		}
	}
	return shift @current;
}


while (defined(my $path = nextpath)) {
	my \%path = $path;
	my \($player, $plymv, $elephant, $elemv, $open, $score, $remain, $route) = \@path{qw/player player_move elephant elephant_move open score remain route/};
	my $turnscore = List::Util::sum0(map { $valves{$_}{rate}//die "WTF <$_>" } keys %$open);
	# Determine if a turn needs to be set
	if (!defined($plymv) && !$path{player_done}) {
		# Determine the player's next route.
		#say STDERR "Player's next move for route $route with score $score and $remain turns left";
		#say STDERR "  Open: " . join(",", keys %$open);
		my %pathmap = path_map($player);
		my $any = 0;
		for my $path (keys %pathmap) {
			# Discard any zero-value target
			next unless $valves{$path}{rate} > 0;
			# Discard if already open
			next if $open->{$path};
			# Discard if we can't get there in time.
			my @move = $pathmap{$path}->@*;
			next unless $remain > scalar(@move);
			# Discard if the elephant is already going there.
			next if defined($elemv) && @$elemv && ($elemv->[-1] eq $path);
			$any = 1;
			my $state = { %path, player_move => [ @move ], route => "$route:($path)" };
			addpath $state;
		}
		unless ($any) {
			# No paths remain for the player? Push an empty array. Excess opens are pointless.
			addpath { %path, player_done => 1 };
		}
	}
	elsif (!defined($elemv) && !$path{elephant_done}) {
		# Determine the elephant's next route. Same logic as doing so for the player.
		#say STDERR "Elephant's next move for route $route with score $score and $remain turns left";
		#say STDERR "  Open: " . join(",", keys %$open);
		my %pathmap = path_map($elephant);
		my $any = 0;
		for my $path (keys %pathmap) {
			# Discard any zero-value target
			next unless $valves{$path}{rate} > 0;
			# Discard if already open
			next if $open->{$path};
			# Discard if we can't get there in time.
			my \@move = $pathmap{$path};
			next unless $remain > scalar(@move);
			# Discard if the player is already going there.
			next if defined($plymv) && @$plymv && ($plymv->[-1] eq $path);
			$any = 1;
			my $state = { %path, elephant_move  => [ @move ], route => "$route:[$path]" };
			addpath $state;
		}
		unless ($any) {
			# No paths remain for the player? Push an empty array. Excess opens are pointless.
			addpath { %path, elephant_done => 1 };
		}
	}
	else {
		# Both critters have a turn to execute, so let's do so:
		if ($path{player_done} && $path{elephant_done}) {
			#say STDERR "Route $route opened all valves with $remain left";
			$score += ($remain * $turnscore);
			$remain = 0;
		}
		else {
			my $go = 1;
			while ($go && $remain > 0) {
				--$remain;
				$score += $turnscore;
				if (defined($plymv)) {
					$plymv = [ @$plymv ];
					my $playerstep = shift @$plymv;
					if (defined($playerstep)) {
						#say STDERR "Route $route, player moving to $playerstep with $remain left";
						$player = $playerstep;
					}
					else {
						# The empty array means the player arrived at their valve, so open it
						#say STDERR "Route $route, player opening $player with $remain left";
						$open = { %$open, $player => 1 };
						$plymv = undef; # When it goes around again, a new target will be set
						$go = 0;
					}
				}
				if (defined($elemv)) {
					$elemv = [ @$elemv ];
					my $elestep = shift @$elemv;
					if (defined($elestep)) {
						#say STDERR "Route $route, elephant moving to $elestep with $remain left";
						$elephant = $elestep;
					}
					else {
						#say STDERR "Route $route, elephant opening $elephant with $remain left";
						$open = { %$open, $elephant => 1 };
						$elemv = undef;
						$go = 0;
					}
				}
			}
		}
		if ($remain > 0) {
			addpath \%path;
		}
		else {
			if ($score > $best) {
				#say STDERR "Route $route ended with score $score";
				#say STDERR "  (Best so far)";
				$best = $score;
			}
		}
	}
}

say $best;
