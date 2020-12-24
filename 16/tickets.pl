#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

use List::Util ();

my %ranges;

while (<>) {
	chomp;
	if ($_ eq "") {
		last;
	}
	my ($field, $lo1, $hi1, $lo2, $hi2) = /^([^:]+): (\d+)-(\d+) or (\d+)-(\d+)/;
	$ranges{$field} = [ $lo1, $hi1, $lo2, $hi2 ];
}

sub field_is_valid {
	my $value = shift;
	my $field = shift;

	my @r = $ranges{$field}->@*;

	while (my ($lo, $hi) = splice @r, 0, 2) {
		if ($value >= $lo && $value <= $hi) {
			return 1;
		}
	}
	return "";
}

scalar<> =~ /your ticket:/ or die;

chomp (my $your_ticket = <>);
my @your_ticket = split /,/, $your_ticket;

scalar<> =~ m/^\s+$/ or die;
scalar<> =~ /nearby tickets:/ or die;

my $sum = 0;

my @tickets;
RECORD: while (<>) {
	chomp;
	my @fields = split/,/, $_;
	my $ok = 1;
	FIELD: for my $f (@fields) {
		if (List::Util::none { field_is_valid $f, $_ } keys %ranges) {
			$sum += $f;
			$ok = 0;
		}
	}
	if ($ok) { push @tickets, [@fields]; }
}

say "Scanning error rate: $sum";

# Now go over the valid tickets and see if we can narrow down which fields can be which:
my @possible = map { { map { $_ => 1 } keys %ranges } } 0 .. $#your_ticket;

for my $t (@tickets) {
	say "Processing: @$t";
	for my $ix ( 0 .. $#$t ) {
		my $f = $t->[$ix];
		for my $which (keys %ranges) {
			unless (field_is_valid $f, $which) {
				say "Eliminating $which for $ix";
				delete $possible[$ix]->{$which};
			}
		}
	}
}

say "Field possibilities:";
for my $ix (0 .. $#possible) {
	printf "%d : %s\n", $ix, join ", ", keys $possible[$ix]->%*;
}

my @assigned;

while (my @ix = grep { (scalar keys $possible[$_]->%*) == 1 } keys @possible) {
	for my $ix (@ix) {
		my ($selection) = $possible[$ix]->%*;
		$assigned[$ix] = $selection;
		for my $poss (@possible) {
			delete $poss->{$selection};
		}
	}
}

if (List::Util::any { !defined $_ } @assigned) {
	say "Not all fields resolved.";
	say "Assigned fields: ";
	say join ", ", map { $_ // "<???>" } @assigned;
	say "Possibilities:";
	for my $ix (0 .. $#possible) {
		next if defined $assigned[$ix];
		printf "%d : %s\n", $ix, join ", ", keys $possible[$ix]->%*;
	}
	exit 1;
}
else {
	say "Assignments:";
	say join ", ", map { $_ } @assigned;
}

my %your_ticket = map { $assigned[$_] => $your_ticket[$_] } 0 .. $#assigned;

say "Ticket:";
for my $k (keys %your_ticket) {
	say "$k : $your_ticket{$k}";
}

printf "Result: %d\n", List::Util::product map { $your_ticket{$_} } grep /^departure/, keys %your_ticket;
