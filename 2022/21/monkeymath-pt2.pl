#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %monkeys;

while (<>) {
	chomp;
	if (/^([^:]+): (\d+)$/) {
		my ($monkey, $number) = ($1, $2);
		$monkeys{$monkey} = $number;
	}
	elsif (/^([^:]+): ([^:]+) ([-+*\/]) ([^:]+)/) {
		my ($monkey, $left, $op, $right) = ($1, $2, $3, $4);
		$monkeys{$monkey} = {
			op => $op,
			left => $left,
			right => $right,
		};
	}
	else { die "Input error"; }
}

$monkeys{root}{op} = '==';

$monkeys{humn} = undef;

my $top = {};
# Build an expression tree:

sub dump_tree;
sub dump_tree($node) {
	defined($node) or return "HUMN";
	ref($node) or return "$node";
	return sprintf "(%s) %s (%s)", dump_tree($node->{left}), $node->{op}, dump_tree($node->{right});
}

sub build_tree;
sub build_tree ($monkey, $path = "") {
	assert ref($monkey);
	my $left = $monkeys{$monkey->{left}};
	my $right = $monkeys{$monkey->{right}};
	my $hash = {};
	$hash->{op} = $monkey->{op};
	$hash->{path} = $path;
	$hash->{left} = ref($left) ? build_tree($left, "${path}L") : $left;
	$hash->{right} = ref($right) ? build_tree($right, "${path}R") : $right;
	return $hash;
}

$top = build_tree($monkeys{root});
say STDERR "Built tree: ".dump_tree $top;

sub reduce_tree;
sub reduce_tree ($node) {
	ref($node) or return $node;
	if (defined($node->{left})) {
		$node->{left} = reduce_tree $node->{left};
	}
	else { return $node; }
	if (defined($node->{right})) {
		$node->{right} = reduce_tree $node->{right};
	}
	else { return $node; }
	if (ref($node->{left}) || ref($node->{right})) {
		return $node;
	}
	if ($node->{op} eq '+') { return $node->{left} + $node->{right}; }
	if ($node->{op} eq '-') { return $node->{left} - $node->{right}; }
	if ($node->{op} eq '*') { return $node->{left} * $node->{right}; }
	if ($node->{op} eq '/') { return $node->{left} / $node->{right}; }
	die "Uh oh '$node->{op}'";
}

$top = reduce_tree($top);
say STDERR "Reduced tree: ".dump_tree $top;
assert ref($top);
# One side should be fully resolvable?
assert ((!ref($top->{left})) != (!ref($top->{right})));

my $value;
my $variable;

if (ref($top->{right})) {
	($variable, $value) = $top->@{qw/right left/};
}
else {
	($variable, $value) = $top->@{qw/left right/};
}

while (defined $variable) {
	assert ref($variable);
	my ($l, $r) = $variable->@{qw/left right/};
	assert !(ref($l) && ref($r));
	assert ref($l) || ref($r) || (defined($l) != defined($r));
	my $varleft;
	if (ref($l) || !defined($l)) { $varleft = 1; }
	elsif (ref($r) || !defined($r)) { $varleft = 0; }
	else { die "WTF"; }
	if ($variable->{op} eq '+') {
		if ($varleft) {
			($variable, $value) = ($l, $value - $r);
		}
		else {
			($variable, $value) = ($r, $value - $l);
		}
	}
	elsif ($variable->{op} eq '-') {
		if ($varleft) {
			($variable, $value) = ($l, $value + $r);
		}
		else {
			($variable, $value) = ($r, $l - $value);
		}
	}
	elsif ($variable->{op} eq '*') {
		if ($varleft) {
			($variable, $value) = ($l, $value / $r);
		}
		else {
			($variable, $value) = ($r, $value / $l);
		}
	}
	elsif ($variable->{op} eq '/') {
		if ($varleft) {
			($variable, $value) = ($l, $value * $r);
		}
		else {
			($variable, $value) = ($r, $l / $value);
		}
	}
	else { die "WTF"; }
}

say $value;
