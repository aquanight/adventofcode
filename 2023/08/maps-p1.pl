#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $path;

my %nodes;

while (<>) {
	if (/^([RL]+)$/) {
		$path = $1;
	}
	elsif (/^([A-Z]{3}) += +\(([(A-Z]{3}), +([A-Z]{3})\)$/) {
		my $src = $1;
		my $ldst = $2;
		my $rdst = $3;
		exists $nodes{$src} and die "Duplicate $src";
		$nodes{$src}{L} = $ldst;
		$nodes{$src}{R} = $rdst;
	}
	elsif (/^ *$/) { }
	else {
		die "Input error";
	}
}

my $current = "AAA";
my $steps = 0;

while ($current ne "ZZZ") {
	my $which = substr($path, ($steps % length($path)), 1);
	my $dest = $nodes{$current}{$which};
	say STDERR "Step $steps : $which (to $dest)";
	$current = $nodes{$current}{$which};
	++$steps;
}

say $steps;
