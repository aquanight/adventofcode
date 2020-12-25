#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';
no warnings 'experimental';

use POSIX ();

use constant CARD_SUBJECT => 7;
use constant DOOR_SUBJECT => 7;

use constant MODULUS => 20201227;

sub powmod {
	my $b = shift;
	my $e = shift;

	use integer;

	my $r = 1;
	while ($e > 0) {
		if ($e % 2 == 1) {
			$r = ($r * $b) % MODULUS;
		}
		$e >>= 1;
		$b = ($b * $b) % MODULUS;
	}

	return $r;
}

sub dlog {
	my $subj = shift;
	my $pk = shift;

	use integer;

	my $m = POSIX::ceil( sqrt(MODULUS) )+0;

	my %tbl;

	my $e = 1;

	for my $i (0 .. ($m - 1)) {
		$tbl{$e} = $i;
		$e = ($e * $subj) % MODULUS;
	}

	my $factor = powmod $subj, (MODULUS - $m - 1);

	$e = $pk;

	for my $i (0 .. ($m - 1)) {
		exists $tbl{$e} and return ($i * $m) + $tbl{$e};
		$e = ($e * $factor) % MODULUS;
	}
	return undef;
}

chomp (my $card_pk = scalar(<>));
chomp (my $door_pk = scalar(<>));

say "Card PK is $card_pk";
say "Door PK is $door_pk";

my $card_loop = dlog(CARD_SUBJECT, $card_pk);
my $door_loop = dlog(DOOR_SUBJECT, $door_pk);

say "Card loop is $card_loop";
say "Door loop is $door_loop";

unless (powmod(CARD_SUBJECT, $card_loop) == $card_pk) {
	die "Failed to verify card loop";
}
unless (powmod(DOOR_SUBJECT, $door_loop) == $door_pk) {
	die "Failed to verify door loop";
}

my $card_enc = powmod $door_pk, $card_loop;
my $door_enc = powmod $card_pk, $door_loop;

say "Card computes encryption key as $card_enc";
say "Door computes encryption key as $door_enc";

print "(These should be the same:";

if ($card_enc == $door_enc) {
	say " and they are :) )";
}
else {
	say " but they aren't :( )";
	die;
}

