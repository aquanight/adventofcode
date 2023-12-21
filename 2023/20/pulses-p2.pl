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
	$modules{$name}{type} = $type;
	$modules{$name}{name} = $name;
	$modules{$name}{dest} = [ @dests ];
	for my $dest (@dests) {
		push $modules{$dest}{in}->@*, $name;
	}
	my $mod = $modules{$name};
	if ($type eq '&') {
		$mod->{state} = { };
	}
	elsif ($type eq '%') {
		$mod->{state} = 0;
	}
}

use List::Util ();

use Data::Dumper;
say STDERR Dumper(\%modules);

# Initialize conjunction modules
for my $mod (values %modules) {
	next unless defined $mod->{type};
	next unless $mod->{type} eq '&';
	my @sources = map { $_->{name} } grep { List::Util::any { $_ eq $mod->{name} } $_->{dest}->@* } values %modules;
	$_ = 0 for $mod->{state}->@{@sources};
}

my @pulses;

my $pushes = 0;

my %need;
my $rxct;

{
	my @rxin = $modules{rx}{in}->@*;
	die unless @rxin == 1;
	my @need = $modules{$rxin[0]}{in}->@*;
	$_ = undef for @need{@need};
}

say STDERR Dumper(\%need);

PUSH: until (defined $rxct) {
	die "How?" if @pulses;
	push @pulses, button => broadcaster => 0;
	++$pushes;
	while (@pulses) {
		my $source = shift @pulses;
		my $target = shift @pulses;
		my $pulse = shift @pulses;
		defined $source or die "WTF";
		defined $target or die "Problem";
		defined $pulse or die "Bad";
		if ($target eq 'rx') {
			printf STDERR "[%d] To rx : %s\r", $pushes, ($pulse ? "hi" : "LO");
			if (!$pulse) {
				$rxct = $pushes;
			}
		}
		if (exists $need{$source} && $pulse) {
			printf STDERR "\e[K[%d] Hi from %s\n", $pushes, $source;
			$need{$source} //= $pushes;
			last PUSH if List::Util::all { defined } values %need;
		}
		my $mod = $modules{$target};
		defined $mod->{type} or next;
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

# Aw hell it's this crap again
sub gcd ($x, $y) {
	return $y if $x == 0;
	return $x if $y == 0;
	my $g = 1;
	while (!(($x | $y) & 1)) {
		$x >>= 1;
		$y >>= 1;
		$g <<= 1;
	}
	$x >>= 1 until $x & 1;
	$y >>= 1 until $y & 1;
	until ($x == $y) {
		if ($x < $y) {
			($x, $y) = ($y, $x);
		}
		$x -= $y;
		$x >>= 1 until $x & 1;
	}
	return $x * $g;
}

sub lcm ($x, $y) {
	return ($x * $y) / gcd($x, $y);
}

unless (defined $rxct) {
	$rxct = List::Util::reduce { lcm($a, $b) } values %need;
}

say $rxct;
