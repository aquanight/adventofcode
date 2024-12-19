#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @towels;

my @patterns;

my $inp = 0;

while (<>) {
	chomp;
	if ($inp) {
		push @patterns, $_;
	}
	elsif (/^ *$/) {
		$inp = 1;
	}
	else {
		my @t = split / *, */, $_;
		push @towels, @t;
	}
}

my %every;

sub every($txt) {
	if (defined $every{$txt}) { return $every{$txt}; }
	return 0 unless length $txt;
	my $ct = 0;
	for my $t (@towels) {
		next unless $txt =~ m/^\Q$t\E/;
		if (length $') {
			$ct += __SUB__->($');
		}
		else {
			$ct++;
		}
	}
	$every{$txt} = $ct;
	return $ct;
}

my $ct = 0;

for my $pat (@patterns) {
	$ct += every $pat;
	say STDERR "$pat: $ct";
}

say $ct;
