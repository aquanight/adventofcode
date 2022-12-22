#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @monkeys;

my $current = undef;

use integer;

while (<>) {
	chomp;
	if (my ($which) = /^Monkey (\d+):$/) {
		$current = \$monkeys[$which];
		defined $$current and die "Duplicate Monkey";
		$$current = {
			items => [],
			inspect => undef,
			test => undef,
			true => undef,
			false => undef,
			count => 0,
		};
	}
	elsif (my ($items) = /^  Starting items: (.*)$/) {
		$$current->{items}->@* = map { 0 + $_ } split /\s*,\s*/, $items;
	}
	elsif (my ($oper) = /^  Operation: (.*)$/) {
		$oper =~ s/old/\$old/g;
		$oper =~ s/new/\$new/g;
		my $code = sprintf q{
			sub ($old) {
				my $new;
				%s;
				return $new;
			}
		} => $oper;
		my $proc = eval "$code" or die "Failed to build operation: $@";
		$$current->{inspect} = $proc;
	}
	elsif (my ($test) = /^  Test: (.*)$/) {
		if (my ($div) = $test =~ m/^divisible by (\d+)$/) {
			$$current->{test} = sub ($n) { $n % $div == 0 };
		}
		else {
			die "Unknown test case: $test";
		}
	}
	elsif (my ($which_true) = /^    If true: throw to monkey (\d+)$/) {
		$$current->{true} = $which_true;
	}
	elsif (my ($which_false) = /^    If false: throw to monkey (\d+)$/) {
		$$current->{false} = $which_false;
	}
}

sub dump_monkeys {
	for my $n (0 .. $#monkeys) {
		defined $monkeys[$n] or next;
		say STDERR "Monkey $n: " . join(", ", $monkeys[$n]->{items}->@*);
	}
}

sub monkey_turn ($n) {
	my $monkey = $monkeys[$n];
	say STDERR "Monkey $n:";
	while ($monkey->{items}->@*) {
		my $item = shift $monkey->{items}->@*;
		$monkey->{count}++;
		say STDERR "  Monkey inspects item with a worry level of $item";
		$item = $monkey->{inspect}->($item);
		say STDERR "    Worry level is now $item";
		$item = int($item / 3);
		say STDERR "    Monkey gets bored with item. Worry level divided by 3 to $item";
		my $where;
		if ($monkey->{test}->($item)) {
			say STDERR "    Item passes Monkey $n test";
			$where = $monkey->{true};
		}
		else {
			say STDERR "    Item does not pass Monkey $n test";
			$where = $monkey->{false};
		}
		say "    Item is thrown to monkey $where";
		push $monkeys[$where]->{items}->@*, $item;
	}
}

my $round_count = 0;

sub monkey_round {
	++$round_count;
	for my $n (0 .. $#monkeys) {
		monkey_turn $n;
	}
	say STDERR "After round $round_count, monkey item report:";
	dump_monkeys;
}

dump_monkeys;

while ($round_count < 20) { monkey_round; }

my ($first, $second) = sort { $b <=> $a } map { $_->{count} } @monkeys;

my $score = $first * $second;

say $score;
