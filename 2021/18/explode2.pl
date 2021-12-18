#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Scalar::Util ();

use Carp ();

my @numbers;

sub reduce_num;

sub init_parents {
	@_ or return;
	ref $_[0] or die "Top should be an array node";
	$_[0][2] = undef;
	while (@_) {
		my $n = shift;
		my ($l, $r) = @$n;
		if (ref $l) {
			$l->[2] = $n;
			push @_, $l;
		}
		if (ref $r) {
			$r->[2] = $n;
			push @_, $r;
		}
	}
}

my %ids;
my $next_id = 0;
sub array_id ($r) {
	$r//return "<>";
	#return "<$a>";
	unless (exists $ids{"$r"}) {
		$ids{"$r"} = $next_id++;
	}
	return sprintf "<%s>", $ids{$r};
}

sub bad_link {
	while (defined(my $n = shift)) {
		warn sprintf("Node is %s\n", array_id($n));
		warn sprintf("Node parent is %s\n", array_id($n->[2]));
		my ($l, $r) = $n->[2]->@*;
		warn sprintf("Node parent left is %s\n", (ref $l ? array_id($l) : "$l"));
		warn sprintf("Node parent right is %s\n", (ref $r ? array_id($r) : "$r"));
	}
	Carp::confess "ASSERT FAIL: BAD PARENT LINKAGE";
}

sub fmtnum ($n) {
	if (ref $n) {
		my ($l, $r) = @$n;
		return sprintf '[ %2$s, %3$s ]', array_id($n), fmtnum($l), fmtnum($r), array_id($n->[2]);
	}
	else {
		return "$n";
	}
}

while (<>) {
	chomp;
	/^[\d+\[\],]+$/ or die "Invalid input";
	my $number = eval $_; # Probably the absolute worst way to do this.
	init_parents $number;
	printf STDERR "Read: %s\n", fmtnum($number);
	reduce_num $number; # Ensure it is reduced.
	push @numbers, $number;
}

sub magnitude ($n) {
	ref $n or return $n;
	my ($l, $r) = @$n;
	my $ml = 3 * __SUB__->($l);
	my $mr = 2 * __SUB__->($r);
	return $ml + $mr;
}

sub dup ($n) {
	ref $n or return $n;
	my $d = [];
	if (ref $n->[0]) {
		$d->[0] = __SUB__->($n->[0]);
		Scalar::Util::weaken($d->[0][2] = $d);
	}
	else { $d->[0] = $n->[0]; }
	if (ref $n->[1]) {
		$d->[1] = __SUB__->($n->[1]);
		Scalar::Util::weaken($d->[1][2] = $d);
	}
	else { $d->[1] = $n->[1]; }
	$d->[2] = undef;
	return $d;
}

my $best_mag = 0;

for my $x ( 0 .. $#numbers ) {
	for my $y ( 0 .. $#numbers ) {
		next if $x == $y;
		my $n1 = dup $numbers[$x];
		my $n2 = dup $numbers[$y];
		my $r = [ $n1, $n2, undef ];
		$n1->[2] = $r;
		$n2->[2] = $r;
		reduce_num $r;
		my $mag = magnitude($r);
		if ($mag > $best_mag) { $best_mag = $mag; }
	}
}

say "The highest magnitude is: $best_mag";

sub explode;
sub splitnum;

sub reduce_num ($n) {
	{
		if (explode $n) {
			redo;
		}
		if (splitnum $n) {
			redo;
		}
	}
}

# Returns the left-most regular element under the current node.
sub leftmost :lvalue ($node) {
	ref $node or die "Invalid node";
	while (ref $node->[0]) {
		$node = $node->[0];
	}
	return $node->[0];
}

# Returns the right-most regular element under the current node.
sub rightmost :lvalue ($node) {
	ref $node or die "Invalid node";
	while (ref $node->[1]) {
		$node = $node->[1];
	}
	return $node->[1];
}

# Finds the regular number which is to the left of the current node.
# If no such eleemnt, returns undef.
sub addtoleft ($node, $val) {
	while (defined $node->[2]) {
		my $p = $node->[2];
		if ($node == $p->[1]) {
			# We were the right node of this parent, so get the rightmost element of the left side
			if (ref $p->[0]) {
				rightmost($p->[0]) += $val;
			}
			else {
				$p->[0] += $val;
			}
			return;
		}
		# Otherwise we were the left side. Move up one level and try the next level up.
		$node == $p->[0] or bad_link $node;
		$node = $p;
	}
}

sub addtoright ($node, $val) {
	while (defined $node->[2]) {
		my $p = $node->[2];
		if ($node == $p->[0]) {
			# We were the left node of this parent, so get the leftmost element of the right side
			if (ref $p->[1]) {
				leftmost($p->[1]) += $val;
			}
			else {
				$p->[1] += $val;
			}
			return;
		}
		# Otherwise we were the right side. Move up one level and try the next level up.
		$node == $p->[1] or bad_link $node;
		$node = $p;
	}
}

sub depth ($n) {
	ref $n or Carp::confess "Bad reference";
	my $d = 0;
	while (defined $n) {
		$n = $n->[2];
		++$d;
	}
	return $d;
}

sub zero ($n) {
	ref $n or Carp::confess "Bad reference";
	my $p = $n->[2];
	if ($n == $p->[0]) {
		$p->[0] = 0;
	}
	else {
		$n == $p->[1] or bad_link $n;
		$p->[1] = 0;
	}
}

sub explode ($n) {
	my @check = @$n[0, 1];
	while (@check) {
		my $n = shift @check;
		ref $n or next;
		if (depth($n) > 4) {
			# EXPLOD
			my ($l, $r) = @$n;
			addtoleft $n, $l;
			addtoright $n, $r;
			zero $n;
			return 1;
		}
		unshift @check, grep { ref $_ } $n->@[0, 1];
	}
	return !1;
}

sub splitnum ($n) {
	while (defined $n) {
		if (ref $n->[0]) {
			$n = $n->[0];
			next;
		}
		if ($n->[0] > 9) {
			my $nl = int $n->[0] / 2;
			my $nr = $n->[0] - $nl;
			$n->[0] = [ $nl, $nr, $n ];
			return 1;
		}
		RIGHT:
		if (ref $n->[1]) {
			$n = $n->[1];
			next;
		}
		if ($n->[1] > 9) {
			my $nl = int $n->[1] / 2;
			my $nr = $n->[1] - $nl;
			$n->[1] = [ $nl, $nr, $n ];
			return 1;
		}
		my $p = $n->[2];
		while (defined $p) {
			if ($n == $p->[0]) {
				$n = $p;
				goto RIGHT;
			}
			else {
				$n == $p->[1] or bad_link $n, $p;
				$n = $p;
				$p = $n->[2];
			}
		}
		return "";
	}
}
