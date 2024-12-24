#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %lines;

my %pending;

while (<>) {
	if (my ($line, $val) = /^(\w+): ([01])$/) {
		$lines{$line} = $val;
	}
	elsif (my ($i1, $op, $i2, $out) = /^(\w+) (AND|OR|XOR) (\w+) -> (\w+)$/) {
		$pending{$out} = [ $op, $i1, $i2 ];
	}
	elsif (/^$/) { }
	else { die; }
}

while (%pending) {
	say STDERR join ",", keys %pending;
	for my $p (keys %pending) {
		my ($op, $i1, $i2) = $pending{$p}->@*;
		defined($lines{$i1}) or next;
		defined($lines{$i2}) or next;
		my $l1 = $lines{$i1};
		my $l2 = $lines{$i2};
		delete $pending{$p};
		if ($op eq "AND") { $lines{$p} = $l1 && !!$l2; }
		elsif ($op eq "OR") { $lines{$p} = !!$l1 || !!$l2; }
		elsif ($op eq "XOR") { $lines{$p} = (!$l1) != !($l2); }
	}
}

my $bits = join "", map { $lines{$_} ? 1 : 0 } sort { $b cmp $a } grep /^z/, keys %lines;

use bigint;
say oct("0b$bits");
