#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @input;

my $zero;

while (<>) {
	chomp;
	push @input, { value => (0 + $_), prev => (@input - 1), next => (@input + 1) };
	if ((0 + $_) == 0) { $zero = $input[-1]; }
}

assert ref($zero);

$input[0]{prev} = $#input;
$input[-1]{next} = 0;

sub dumpset {
	for my $ix (0 .. $#input) {
		printf STDERR "[%d] value = %d, from = %d, to = %d\n", $ix, $input[$ix]->@{qw/value prev next/};
	}
	say STDERR "---";
}
#dumpset;

sub unlink_node ($ix) {
	my $prev = $input[$ix]{prev}//die;
	my $next = $input[$ix]{next}//die;
	$input[$prev]{next} = $next;
	$input[$next]{prev} = $prev;
	$input[$ix]{prev} = undef;
	$input[$ix]{next} = undef;
}

sub insert_after ($ix, $where) {
	defined $input[$ix]{prev} and die;
	defined $input[$ix]{next} and die;
	my $next = $input[$where]{next}//die;
	$input[$ix]{prev} = $where;
	$input[$ix]{next} = $next;
	$input[$where]{next} = $ix;
	$input[$next]{prev} = $ix;
}

sub insert_before ($ix, $where) {
	defined $input[$ix]{prev} and die;
	defined $input[$ix]{next} and die;
	my $prev = $input[$where]{prev};
	$input[$ix]{next} = $where;
	$input[$ix]{prev} = $prev;
	$input[$where]{prev} = $ix;
	$input[$prev]{next} = $ix;
}

sub move ($ix, $ct) {
	if ($ct == 0) { return; }
	say STDERR "moving $ix by $ct";
	if ($ct > 0) {
		$ct %= $#input;
		my $where = $input[$ix]{next};
		unlink_node $ix;
		while ($ct-- > 1) {
			$where = $input[$where]->{next};
		}
		insert_after $ix, $where;
	}
	else {
		$ct = (-$ct) % $#input;
		my $where = $input[$ix]{prev};
		unlink_node $ix;
		while ($ct-- > 1) {
			$where = $input[$where]->{prev};
		}
		insert_before $ix, $where;
	}
	#dumpset;
}

for my $ix (0 .. $#input) {
	my $item = $input[$ix]{value};
	move($ix, $item);
}

sub get($from, $ct) {
	$ct %= @input;
	for (1 .. $ct) {
		$from = $input[$from->{next}];
	}
	return $from->{value};
}

my $first = get($zero, 1000);
my $second = get($zero, 2000);
my $third = get($zero, 3000);

say "First $first, Second $second, Third $third";

my $score = $first + $second + $third;

say $score;

