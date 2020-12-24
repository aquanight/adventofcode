#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

use Carp ();
use Data::Dumper ();

my @rules;

my $retext = "(?(DEFINE)";

sub make_part {
	my $part = shift;
	if (my ($chr) = $part =~ m/"(.)"/) {
		return $chr;
	}
	else {
		my @cmp = split / +/, $part;
		return join "", map { "(?&rule$_)" } @cmp;
	}
}

sub make_re {
	my $rule = shift;
	my @parts = split/\s*\|\s*/, $rule;
	return join "|", map {make_part $_} @parts;
}

while (<>) {
	chomp;
	if ($_ eq "") { last; }
	my ($num, $rule) = /^(\d+): (.*)$/;
	$rules[$num] = $rule;

	$retext .= sprintf "(?<rule%d>%s)", $num, make_re $rule;
}

$retext .= ")";

my $rules = eval sprintf "qr(%s)", $retext;

say "RE: $rules";

sub compile_rule {
	my $index = shift//Carp::confess "Undefined index";
	my $rule = $rules[$index];
	if (ref $rule eq 'Regexp') { return $rule; }
	if ((ref $rule) eq 'ARRAY') { print Data::Dumper->Dumper(\@rules); Carp::confess "Recursion detected"; }
	$rules[$index] = []; # Guard against recursion
	say "Compiling $rule";
	my @parts = split /\s*\|\s*/, $rule;
	for my $part (@parts) {
		#say "Processing part '$part'";
		if (my ($chr) = $part =~ /"(.)"/) {
			$part = qr/$chr/;
		}
		elsif ($part =~ m/\d+( \d+)*/) {
			my @sub = split / +/, $part;
			my @cmp = map { compile_rule($_) } @sub;
			$part = eval("qr(" . join("", map { "$_" } @cmp) . ")");
		}
	}
	$rule = eval("qr(" . join("|", map { "(?:$_)" } @parts) . ")");
	$rules[$index] = $rule;
	return $rule;
}


sub match_rule {
	my $text = shift;
	my $index = shift;
	my $rule = compile_rule $index;

	return $text =~ m/^$rule$/;
}

my $match = 0;

while (<>) {
	chomp;
	#++$match if match_rule $_, 0;
	++$match if /^(?&rule0)$ $rules/x;
}

say "Matches: $match";
