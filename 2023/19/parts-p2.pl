#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %rules;

while (<>) {
	chomp;
	length or last;
	my ($name, $rule) = /^(\w+?)\{(.+)\}$/;
	defined $name or die "Input error";
	my @rule = split /,/, $rule;
	my @built;
	while (defined(my $r = shift @rule)) {
		if (my ($var, $cmp, $val, $target) = $r =~ m/^([xmas])([\<\>])(\d+):(\w+)$/) {
			push @built, $var, $cmp, $val, $target;
		}
		else {
			push @built, "", $r;
		}
	}
	$rules{$name} = [ @built ];
}

my $accept = 0;

my @current = (in => { x => [ 1, 4000 ], m => [ 1, 4000 ], a => [ 1, 4000 ], s => [ 1, 4000 ]});

while (@current) {
	my $label = shift @current;
	my $state = shift @current;
	printf STDERR "Processing state: at=%s, x=%d..%d, m=%d..%d, a=%d..%d, s=%d..%d\n",
		$label, map { $_->@[0, 1] } $state->@{qw/x m a s/};
	if ($label eq 'R') { next; }
	if ($label eq 'A') {
		my ($X, $M, $A, $S) = $state->@{qw/x m a s/};
		my ($xl, $xu) = @$X;
		my ($ml, $mu) = @$M;
		my ($al, $au) = @$A;
		my ($sl, $su) = @$S;
		my $xrng = ($xu - $xl + 1);
		my $mrng = ($mu - $ml + 1);
		my $arng = ($au - $al + 1);
		my $srng = ($su - $sl + 1);
		$accept += ($xrng * $mrng * $arng * $srng);
		next;
	}
	my @rule = $rules{$label}->@*;
	say STDERR "Rule: " . join ":", @rule;
	while (defined($state)) {
		die "Uh oh" unless @rule;
		my $var = shift @rule;
		if (length($var)) {
			say STDERR "Partition on var $var";
			my $curlo = $state->{$var}[0];
			my $curhi = $state->{$var}[1];
			my $cmp = shift @rule;
			my $val = shift @rule;
			my $target = shift @rule;
			if ($cmp eq '<') {
				if ($val <= $curlo) {
					# No options can take this branch, move on.
				}
				if ($val > $curhi) {
					# All routes take this branch.
					push @current, $target => $state;
					$state = undef;
				}
				else {
					# Split
					my $newstate = { %$state };
					$newstate->{$var} = [ $curlo, ($val - 1) ];
					$state->{$var} = [ $val, $curhi ];
					push @current, $target => $newstate;
				}

			}
			else {
				if ($val >= $curhi) {
					# No options can take this branch, move on.
				}
				elsif ($val < $curlo) {
					# All route take this branch.
					push @current, $target => $state;
					$state = undef;
				}
				else {
					# Split
					my $newstate = { %$state };
					$newstate->{$var} = [ ($val + 1), $curhi ];
					$state->{$var} = [ $curlo, $val ];
					push @current, $target => $newstate;
				}
			}
		}
		else {
			my $target = shift @rule;
			push @current, $target => $state;
			$state = undef;
		}
	}
}

say $accept;
