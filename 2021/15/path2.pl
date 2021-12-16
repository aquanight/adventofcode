#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my @graph;

my $xwide;
my $ywide;

while (<>) {
	chomp;
	/^\d+$/ or die "Invalid input";
	my @r = split //;
	push @graph, \@r;
	if (defined $xwide) {
		$xwide == @r or die "Length issue";
	}
	else {
		$xwide = @r;
	}
}
$ywide = @graph;

use constant INF => (0+"INF");

# Tile the graph across...
for my $r (@graph) {
	my @base = @$r;
	push @$r, map { ($_ % 9) + 1 } @base;
	push @$r, map { (($_ + 1) % 9) + 1 } @base;
	push @$r, map { (($_ + 2) % 9) + 1 } @base;
	push @$r, map { (($_ + 3) % 9) + 1 } @base;
}

while (@graph < ($ywide * 5)) {
	my $src = @graph - $ywide;
	my $r = $graph[$src];
	push @graph, [ map { ($_ % 9) + 1 } @$r ];
}

my @dist;
my @visited;
for my $y ( 0 .. $#graph ) {
	my $r = $graph[$y];
	for my $x ( 0 .. $#$r ) {
		$dist[$y][$x] = INF;
		$visited[$y][$x] = 0;
	}
}

my %reachable;

$dist[0][0] = 0;
$reachable{"0,0"} = [0, 0];

sub next_node {
	my @sorted = sort { $dist[$a->[1]][$a->[0]] <=> $dist[$b->[1]][$b->[0]] } values %reachable;
	return () unless @sorted;
	my $nearest = shift @sorted;
	my ($x, $y) = @$nearest;
	delete $reachable{"$x,$y"};
	return $x, $y;
}

sub process_neighbor {
	my ($nx, $ny, $base) = @_;
	return 0 if $ny < 0;
	return 0 if $nx < 0;
	return 0 if $ny > $#graph;
	return 0 if $nx > $graph[$ny]->$#*;
	return 0 if $visited[$ny][$nx];
	$reachable{"$nx,$ny"} = [ $nx, $ny ];
	my $score = $base + $graph[$ny][$nx];
	if ($score < $dist[$ny][$nx]) {
		$dist[$ny][$nx] = $score;
	}
	return 1;
}

while (!$visited[-1][-1]) {
	my ($x, $y) = next_node;
	my $score = $dist[$y][$x];
	process_neighbor $x, $y - 1, $score;
	process_neighbor $x, $y + 1, $score;
	process_neighbor $x - 1, $y, $score;
	process_neighbor $x + 1, $y, $score;
	$visited[$y][$x] = 1;
}

say "Distnace to goal: " . $dist[-1][-1];
