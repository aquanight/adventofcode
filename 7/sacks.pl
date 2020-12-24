#!/usr/bin/perl
use v5.30;
use warnings;

my %bag;

while (<>) {
	chomp;
	if (my ($which) = /^(\w+ \w+) bags contain no other bags.$/) {
		$bag{$which} = {};
		next;
	}
	my ($current, $content) = /^(\w+ \w+) bags contain (\d+ \w+ \w+ bags?(?:, \d+ \w+ \w+ bags?)*)\.$/;
	$current//die "Line invalid: $_";
	my $hash = ($bag{$current} = {});
	while ($content =~ m/(\d+) (\w+ \w+) bags?/g) {
		my ($count, $type) = @{^CAPTURE};
		$hash->{$type} = $count;
	}
}

sub merge_bags {
	my $x = shift;
	my $y = shift;
	for my $bag (keys %$y) {
		$x->{$bag} += $y->{$bag};
	}
}

sub create_bag {
	my $type = shift;
	my $qty = shift//1;
	#say STDERR "Creating $qty $type bags";
	my %result;
	#$result{$type} = $qty;
	my %process = %{$bag{$type}};
	for my $bag (keys %process) {
		my $amt = $process{$bag};
		$result{$bag} += ($amt * $qty);
		merge_bags(\%result, create_bag($bag, $qty * $amt));
	}
	return \%result;
}

use Data::Dumper ();

print Data::Dumper->Dump([\%bag]);

use constant TARGET => 'shiny gold';

my $total = scalar grep { create_bag($_)->{+TARGET}//0 > 0 } keys %bag;

say "Result: $total";

my $tbag = create_bag(TARGET);

print Data::Dumper->Dump([$tbag]);

use List::Util ();

printf "Bags inside target: %d\n", List::Util::sum(values %$tbag);
