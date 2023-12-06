#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use POSIX ();

my @times;
my @records;

while (<>) {
	if (my ($t) = /^Time: +([\d ]+)$/) {
		$t =~ s/ //g;
		@times = $t;
	}
	elsif (my ($r) = /^Distance: +([\d ]+)$/) {
		$r =~ s/ //g;
		@records = $r;
	}
	else {
		die "Bad input '$_'";
	}
}

unless (@times == @records) {
	die "Something's wrong";
}

my $result = 1;

for my $race (0 .. $#times) {
	my $t = $times[$race];
	my $r = $records[$race];
	# distance = speed * (time - speed)
	# Solve:
	# -speed^2 + time*speed - record = 0
	print STDERR "[ $t $r ] ";
	my $det = ($t * $t) - (4 * $r);
	die "How??" if $det < 0; # Imaginary roots
	my $s1 = ((-$t) + sqrt(($t * $t) - (4 * $r))) / -2;
	my $s2 = ((-$t) - sqrt(($t * $t) - (4 * $r))) / -2;
	print STDERR ": [ $s1 $s2 ] ";
	die unless $s1 <= $s2;
	$s1 = POSIX::floor($s1) + 1;
	$s2 = POSIX::ceil($s2) - 1;
	my $ways = $s2 - $s1 + 1;
	say STDERR " < $ways >";
	$result *= $ways;
}

say $result;
