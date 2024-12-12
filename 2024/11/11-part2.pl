#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $stones = <>;
chomp $stones;

my @stones = split / +/, $stones;

my $cycle = 0;

my @blink;

use constant CYCLE_MAX => 75;

$#blink = CYCLE_MAX;

my @queue;
while (@stones) {
	push @queue, [shift(@stones), 0];
}

while (@queue) {
	my ($stone, $blink) = (pop @queue)->@*;
	exists $blink[$blink]{$stone} and next; # This one has been solved, so we're good.
	if ($blink == CYCLE_MAX) {
		$blink[$blink]{$stone} = 1;
		next;
	}
	elsif ($stone == 0) {
		my $val = $blink[$blink + 1]{1};
		if (defined $val) {
			$blink[$blink]{$stone} = $val;
		}
		else {
			push @queue, [$stone, $blink], [1, $blink + 1];
		}
	}
	elsif ((1 + int(log($stone)/log(10))) % 2 == 0) {
		my $hi = substr($stone, 0, length($stone)/2) + 0;
		my $lo = substr($stone, length($stone)/2) + 0;
		my $hival = $blink[$blink + 1]{$hi};
		my $loval = $blink[$blink + 1]{$lo};
		if (defined($hival) && defined($loval)) {
			$blink[$blink]{$stone} = $hival + $loval;
		}
		else {
			push @queue, [$stone, $blink];
			defined $hival or push @queue, [$hi, $blink + 1];
			defined $loval or push @queue, [$lo, $blink + 1];
		}
	}
	else {
		my $val = $blink[$blink + 1]{$stone * 2024};
		if (defined $val) {
			$blink[$blink]{$stone} = $val;
		}
		else {
			push @queue, [$stone, $blink], [$stone * 2024, $blink + 1];
		}
	}
}

use List::Util ();

say List::Util::sum values $blink[0]->%*;
