#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $input = scalar <>;

unless ($input =~ m/
	(.)
	((?!\1).)
	((?!\1|\2).)
	((?!\1|\2|\3).)
	((?!\1|\2|\3|\4).)
	((?!\1|\2|\3|\4|\5).)
	((?!\1|\2|\3|\4|\5|\6).)
	((?!\1|\2|\3|\4|\5|\6|\7).)
	((?!\1|\2|\3|\4|\5|\6|\7|\8).)
	((?!\1|\2|\3|\4|\5|\6|\7|\8|\9).)
	((?!\1|\2|\3|\4|\5|\6|\7|\8|\9|\g10).)
	((?!\1|\2|\3|\4|\5|\6|\7|\8|\9|\g10|\g11).)
	((?!\1|\2|\3|\4|\5|\6|\7|\8|\9|\g10|\g11|\g12).)
	((?!\1|\2|\3|\4|\5|\6|\7|\8|\9|\g10|\g11|\g12|\g13).)
	/gx) {
	die "No marker found";
}

my $score = pos($input);

say $score;
