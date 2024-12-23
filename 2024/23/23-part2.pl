#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %links;

while (<>) {
	chomp;
	/^(\w+)-(\w+)$/ or die;
	my ($c1, $c2) = ($1, $2);
	$links{$c1}{$c2} = 1;
	$links{$c2}{$c1} = 1;
}

my @q = [ {}, { map { $_ => 1 } keys %links }, {} ]; # [ %r, %p, %x ]

my %clique;

while (@q) {
	my ($r, $p, $x) = (shift @q)->@*;
	if (scalar(%$x) == 0 && scalar(%$p) == 0) {
		if (%clique < %$r) {
			%clique = %$r;
		}
	}
	for my $v (keys %$p) {
		my @nv = keys $links{$v}->%*;
		my $nr = { %$r, $v => 1 };
		my $np = { };
		my $nx = { };
		for my $n (@nv) {
			$p->{$n} and $np->{$n} = 1;
			$x->{$n} and $nx->{$n} = 1;
		}
		push @q, [ $nr, $np, $nx ];
		delete $p->{$v};
		$x->{$v} = 1;
	}
}

say join ",", sort keys %clique;
