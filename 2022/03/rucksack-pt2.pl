#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @sacks;

my %prio;
@prio{'a' .. 'z', 'A' .. 'Z'} = 1 .. 52;

my $score = 0;

while (<>) {
	chomp;
	my %sack = map { $_ => 1 } split //, $_;
	push @sacks, \%sack;
}

while (@sacks) {
	state %common;
	assert @sacks >= 3;
	for (1..3) {
		my \%sack = shift @sacks;
		for (keys %sack) {
			$common{$_} += $sack{$_};
		}
	}
	my ($key, $xtra) = grep { $common{$_} == 3 } keys %common;
	assert defined($key) && !defined($xtra);
	$score += $prio{$key};
	%common = ();
}

say $score;
