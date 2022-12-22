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
			div => undef,
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
			$$current->{div} = $div;
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
		printf STDERR "Monkey %d inspected %d items\n", $n, $monkeys[$n]->{count};
	}
}

my $lcm = 1;

for my $n ( 0 .. $#monkeys ) {
	$lcm *= $monkeys[$n]->{div};
}

sub monkey_turn ($n) {
	my $monkey = $monkeys[$n];
	while ($monkey->{items}->@*) {
		my $item = shift $monkey->{items}->@*;
		$monkey->{count}++;
		$item = $monkey->{inspect}->($item);
		$item %= $lcm;
		#$item = int($item / 3);
		#say STDERR "    Monkey gets bored with item. Worry level divided by 3 to $item";
		my $where;
		if ($item % $monkey->{div} == 0) {
			$where = $monkey->{true};
		}
		else {
			$where = $monkey->{false};
		}
		push $monkeys[$where]->{items}->@*, $item;
	}
}

my $round_count = 0;

sub monkey_round {
	++$round_count;
	for my $n (0 .. $#monkeys) {
		monkey_turn $n;
	}
	if ("$round_count" =~ m/^[1-9]0+$/) {
		say STDERR "After round $round_count, monkey item report:";
		dump_monkeys;
	}
}

dump_monkeys;

while ($round_count < 10_000) { monkey_round; }

my ($first, $second) = sort { $b <=> $a } map { $_->{count} } @monkeys;

my $score = $first * $second;

say $score;
