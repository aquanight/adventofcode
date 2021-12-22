#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my ($p1pos) = (<> =~ m/^Player 1 starting position: (\d+)$/);
my ($p2pos) = (<> =~ m/^Player 2 starting position: (\d+)$/);

defined($p1pos) && defined($p2pos) or die "Invalid input";

my $rollcount = 0;
sub d () {
	++$rollcount;
	state $next = 0;
	my $val = ++$next;
	$next %= 100;
	return $val;
}

sub turn ($pos) {
	$pos--;
	my $roll = d() + d() + d();
	$pos += $roll;
	$pos %= 10;
	$pos++;
	return $pos;
}

my $p1score = 0;
my $p2score = 0;

while (1) {
	# Player 1 turn
	$p1pos = turn $p1pos;
	$p1score += $p1pos;
	if ($p1score >= 1000) {
		say STDERR "Player 1 wins ($p1score - $p2score) after $rollcount rolls.";
		my $result = ($p2score * $rollcount);
		say "Result: $result";
		last;
	}
	# Player 2 turn
	$p2pos = turn $p2pos;
	$p2score += $p2pos;
	if ($p2score >= 1000) {
		say STDERR "Player 2 wins ($p1score - $p2score) after $rollcount rolls.";
		my $result = ($p1score * $rollcount);
		say "Result: $result";
		last;
	}
}
