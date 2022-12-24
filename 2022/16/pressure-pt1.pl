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

sub distance_map ($from) {
	my @check = ($from);
	my %map = ($from => 0);
	while (@check) {
		my $id = shift(@check);
		my $dist = $map{$id} + 1;
		my @links = $valves{$id}{links}->@*;
		for my $link (@links) {
			exists $map{$link} and next;
			$map{$link} = $dist;
			push @check, $link;
		}
	}
	return %map;
}

# A set of states to consider.
# 'current' is the current location
# 'open' is the hash of valves currently open
# 'score' is the total pressure released so far
# 'remain' is how many turns this route has left
my @paths = ( { current => 'AA', open => {}, score => 0, remain => 30, route => 'AA' } );

my $best = 0;

while (@paths) {
	my \%path = shift @paths;
	my ($current, $open, $score, $remain, $route) = (@path{qw/current open score remain route/});
	print STDERR "Considering route [$route] with score $score and $remain time left";
	my %distmap = distance_map($current);
	my $turnscore = List::Util::sum0(map { $valves{$_}{rate} } keys %$open);
	my $endscore = $score + ($remain * $turnscore);
	say STDERR ", ending score $endscore";
	if ($endscore > $best) {
		say STDERR "  (Best route so far)";
		$best = $endscore;
	}
	for my $target (keys %distmap) {
		my $dist = $distmap{$target};
		# Don't consider unreachable options
		next unless $remain > $dist;
		# Skip already-opened valves
		next if $open->{$target};
		# Skip valves that don't have any output
		next if $valves{$target}{rate} < 1;
		#say STDERR "  Considering target $target with distance $dist";
		my $move_score = List::Util::sum0($turnscore * ($dist + 1));
		my $dest = { current => $target, open => { %$open, $target => 1 }, score => ($score + $move_score), remain => ($remain - ($dist + 1), route => "$route:$target") };
		push @paths, $dest;
	}
}

say $best;
