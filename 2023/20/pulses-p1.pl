#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %modules;

while (<>) {
	chomp;
	my ($type, $name, $dests) = /^([\&\%]?)(\w+) -\> (.*)$/;
	defined $name or die "Input error";
	my @dests = split / *, */, $dests;
	my $mod = $modules{$name} = {
		type => $type,
		name => $name,
		dest => [ @dests ], # I'd like to use a hash, but destination order is important.
	};
	if ($type eq '&') {
		$mod->{state} = { };
	}
	elsif ($type eq '%') {
		$mod->{state} = 0;
	}
}

use List::Util ();

# Initialize conjunction modules
for my $mod (values %modules) {
	next unless $mod->{type} eq '&';
	my @sources = map { $_->{name} } grep { List::Util::any { $_ eq $mod->{name} } $_->{dest}->@* } values %modules;
	$_ = 0 for $mod->{state}->@{@sources};
}

my @pulses;

my $loct = 0;
my $hict = 0;

for my $runct (1 .. 1_000) {
	die "How?" if @pulses;
	push @pulses, button => broadcaster => 0;
	while (@pulses) {
		my $source = shift @pulses;
		my $target = shift @pulses;
		my $pulse = shift @pulses;
		defined $source or die "WTF";
		defined $target or die "Problem";
		defined $pulse or die "Bad";
		my $mod = $modules{$target};
		if ($pulse) { ++$hict; }
		else { ++$loct; }
		defined $mod or next;
		if ($mod->{type} eq '') {
			if ($target eq "broadcaster") {
				push @pulses, map { $target => $_ => $pulse } $mod->{dest}->@*;
			}
		}
		if ($mod->{type} eq '%') {
			unless ($pulse) {
				$mod->{state} = $mod->{state} ? 0 : 1;
				push @pulses, map { $target => $_ => $mod->{state} } $mod->{dest}->@*;
			}
		}
		if ($mod->{type} eq '&') {
			$mod->{state}{$source} = $pulse;
			$pulse = (List::Util::all { $_ } values $mod->{state}->%*) ? 0 : 1;
			push @pulses, map { $target => $_ => $pulse } $mod->{dest}->@*;
		}
	}
}

say ($loct * $hict);
