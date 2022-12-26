#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %monkeys;

my %ops = (
	'+' => sub { $_[0] + $_[1] },
	'-' => sub { $_[0] - $_[1] },
	'*' => sub { $_[0] * $_[1] },
	'/' => sub { $_[0] / $_[1] },
);

while (<>) {
	chomp;
	if (/^([^:]+): (\d+)$/) {
		my ($monkey, $number) = ($1, $2);
		$monkeys{$monkey} = $number;
	}
	elsif (/^([^:]+): ([^:]+) ([-+*\/]) ([^:]+)/) {
		my ($monkey, $left, $op, $right) = ($1, $2, $3, $4);
		$monkeys{$monkey} = {
			op => $ops{$op},
			left => $left,
			right => $right,
		};
	}
	else { die "Input error"; }
}

my @exec_stack = 'root';

while (@exec_stack) {
	my $monkey = pop @exec_stack;
	my $val = $monkeys{$monkey};
	if (ref($val)) {
		push @exec_stack, $monkey; # Put it back
		my $lm = $monkeys{$val->{left}};
		my $rm = $monkeys{$val->{right}};
		if (ref($lm)) {
			push @exec_stack, $val->{left};
		}
		elsif (ref($rm)) {
			push @exec_stack, $val->{right};
		}
		else {
			defined($lm) or die "Monkey $val->{left} bad";
			defined($rm) or die "Monkey $val->{right} bad";
			my $r = $val->{op}->($lm, $rm);
			$monkeys{$monkey} = $r;
		}
	}
}

my $score = $monkeys{root};

assert !ref($score);

say $score;
