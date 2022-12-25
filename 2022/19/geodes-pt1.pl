#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $total = 0;

# Determine the absolute maximum possible score a given route could attain, assuming we built only geode bots for the rest of the remaining time, ignoring material costs
sub route_max_score ($path) {
	my $score = $path->{geodes};
	my $bots = $path->{geobots};
	my $time = $path->{time};
	while ($time > 0) {
		--$time;
		$score += $bots;
		++$bots;
	}
	return $score;
}

while (<>) {
	chomp;
	/^Blueprint (\d+): Each ore robot costs (\d+) ore. Each clay robot costs (\d+) ore. Each obsidian robot costs (\d+) ore and (\d+) clay. Each geode robot costs (\d+) ore and (\d+) obsidian.$/ or die "Input error.";
	my ($id, $orebot, $claybot, $obsbot, $obsbot_clay, $geobot, $geobot_obs) = ($1, $2, $3, $4, $5, $6, $7);
	my ($max_ore) = sort { $b <=> $a } ($orebot, $claybot, $obsbot, $geobot); # Maximum amount of ore bots we need
	say STDERR "Processing blueprint $id";
	my $best = 0;
	# The 'skip' keys determine if we could've built a bot but built no bot at all. They are only set for the "no bot" step.
	my @paths = ( { time => 24, ore => 0, orebots => 1, clay => 0, claybots => 0, obs => 0, obsbots => 0, geodes => 0, geobots => 0, skipped_ore => 0, skipped_clay => 0, skipped_obsidian => 0, skipped_geode => 0 } );
	while (@paths) {
		my $path = pop @paths;
		my $route = sprintf "%d:%d:%d:%d:%d:%d:%d:%d", $path->@{qw/time ore orebots clay claybots obs obsbots geobots/};
		#say STDERR "Check route $route";
		# Optimziation 1: discard any path that cannot produce a better score than we could have.
		if ($best >= route_max_score($path)) {
			#say STDERR "  Dropped because it can't beat best score of $best";
			next;
		}
		if ($best < $path->{geodes}) {
			$best = $path->{geodes};
			#say STDERR "  Best score is now $best";
		}
		if ($path->{time} < 1) {
			next;
		}
		my $next = {
			time => $path->{time} - 1,
			$path->%{qw/orebots claybots obsbots geobots/},
			ore => $path->{ore} + $path->{orebots},
			clay => $path->{clay} + $path->{claybots},
			obs => $path->{obs} + $path->{obsbots},
			geodes => $path->{geodes} + $path->{geobots},
			skipped_ore => 0,
			skipped_clay => 0,
			skipped_obsidian => 0,
			skipped_geode => 0,
		};
		{
			# Optimzation 2: if we could've built an ore bot last turn and didn't build any bot at all, don't consider it this turn
			local $next->{skipped_ore} = $path->{ore} >= $orebot;
			local $next->{skipped_clay} = $path->{ore} >= $claybot;
			local $next->{skipped_obsidian} = $path->{ore} >= $obsbot && $path->{clay} >= $obsbot_clay;
			local $next->{skipped_geode} = $path->{ore} >= $geobot && $path->{obs} >= $geobot_obs;
			push @paths, { %$next };
		}
		# Optimization: no bot will help in the last minute
		next if $next->{time} < 1;
		if ($path->{orebots} < $max_ore && $path->{ore} >= $orebot && !$path->{skipped_ore} && $path->{time} > 1) {
			local $next->{ore} = $next->{ore} - $orebot;
			local $next->{orebots} = $next->{orebots} + 1;
			push @paths, { %$next, lastbot => 1 };
		}
		if ($path->{claybots} < $obsbot_clay && $path->{ore} >= $claybot && !$path->{skipped_clay} && $path->{time} > 2) {
			local $next->{ore} = $next->{ore} - $claybot;
			local $next->{claybots} = $next->{claybots} + 1;
			push @paths, { %$next, lastbot => 1 };
		}
		if ($path->{obsbots} < $geobot_obs && $path->{ore} >= $obsbot && $path->{clay} >= $obsbot_clay && !$path->{skipped_obsidian} && $path->{time} > 1) {
			local $next->{ore} = $next->{ore} - $obsbot;
			local $next->{clay} = $next->{clay} - $obsbot_clay;
			local $next->{obsbots} = $next->{obsbots} + 1;
			push @paths, { %$next, lastbot => 1 };
		}
		if ($path->{ore} >= $geobot && $path->{obs} >= $geobot_obs && !$path->{skipped_geode}) {
			local $next->{ore} = $next->{ore} - $geobot;
			local $next->{obs} = $next->{obs} - $geobot_obs;
			local $next->{geobots} = $next->{geobots} + 1;
			push @paths, { %$next, lastbot => 1 };
		}
	}
	$total += ($best * $id);
}

say $total;
