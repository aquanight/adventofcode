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

my %triples;

for my $n1 (keys %links) {
	for my $n2 (keys $links{$n1}->%*) {
		for my $n3 (keys $links{$n1}->%*) {
			next if $n3 le $n2;
			next unless $links{$n2}{$n3} && $links{$n3}{$n2};
			my $key = join ",", sort { $a cmp $b } $n1, $n2, $n3;
			$triples{$key} = 1;
		}
	}
}

for my $trip (sort keys %triples) {
	say STDERR "$trip";
}

say scalar grep /(^|,)t/, keys %triples;
