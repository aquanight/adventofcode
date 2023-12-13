#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $sum = 0;

while (<>) {
	my ($springs, $groups) = /^([\.\#\?]+) +([\d,]+)$/;
	defined $springs or die "Input error";
	my @groups = split /,/, $groups;

	my @states = [ $springs, @groups ];

	my $line = 0;

	while (@states) {
		my ($spr, @grp) = (shift @states)->@*;
		if (length($spr) == 0) {
			$line++ if @grp < 1;
			next;
		}
		my $cmd = substr($spr, 0, 1, "");
		if ($cmd eq '.') {
			push @states, [ $spr, @grp ];
		}
		if ($cmd eq '?') {
			push @states, [ ".$spr", @grp ];
			push @states, [ "#$spr", @grp ];
		}
		if ($cmd eq '#') {
			my $group = shift @grp;
			next unless $group;
			--$group;
			if ($spr =~ /^[\#\?]{$group}(?![\#])\??/) { # Eat a following ? (which can only be .) if it is present
				push @states, [ $', @grp ];
			}
		}
	}

	say STDERR "$springs : $line";

	$sum += $line;
}

say $sum;
