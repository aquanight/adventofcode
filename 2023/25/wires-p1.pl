#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %map;
my %nodes;

while (<>) {
	chomp;
	my ($from, $to) = /^(\w+): +(.*)$/;
	defined $from or die "Input error";
	my @to = split / +/, $to;
	for my $t (@to) {
		$map{$from}->{$t} = 1;
		$map{$t}->{$from} = 1;
		$nodes{$t} = 1;
	}
	$nodes{$from} = 1;
}

# Utility functions

# Combine two nodes in the graph into one
# Returns the key of the newly merged node
sub merge_nodes ($n1, $n2) {
	say STDERR "Merging $n1 and $n2";
	my $merge = "$n1,$n2";

	$_ = 1 for $map{$merge}->@{keys($map{$n1}->%*), keys($map{$n2}->%*)};
	delete $map{$merge}->@{$n1, $n2};
	for my $o (keys $map{$merge}->%*) {
		delete $map{$o}->@{$n1, $n2};
		$map{$o}->{$merge} = 1;
	}
	delete $map{$n1};
	delete $map{$n2};
	my ($v1, $v2) = @nodes{$n1, $n2};
	$nodes{$merge} = $v1 + $v2;
	delete @nodes{$n1, $n2};
	return $merge;
}

# Choose any arbitrary node to be the starting position:
my ($pos) = keys %nodes;

# Until we have EXACTLY three edges, combine this node with any of its neighbors
until (keys $map{$pos}->%* == 3) {
	# Choose the neighbor that has the lowest connection count
	my ($other) = sort { keys($map{$a}->%*) <=> keys($map{$b}->%*) } keys $map{$pos}->%*;
	# Combine these two nodes
	$pos = merge_nodes($pos, $other);
}

# At this point, we have three edges between our node and the rest of the graph.
my $v1 = $nodes{$pos};
use List::Util ();
my $v2 = List::Util::sum0(values %nodes) - $v1;

say $v1 * $v2;

