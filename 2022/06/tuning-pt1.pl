#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $input = scalar <>;

unless ($input =~ m/(.)((?!\1).)((?!\1|\2).)((?!\1|\2|\3).)/g) {
	die "No marker found";
}

my $score = pos($input);

say $score;
