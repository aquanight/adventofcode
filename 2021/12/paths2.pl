#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my %nodes;

while (<>) {
	chomp;
	my ($x, $y) = /^\s*([a-z]+|[A-Z]+)\s*-\s*([a-z]+|[A-Z]+)\s*$/ or die "Input error: $_";
	/^[A-Z]+-[A-Z]+/ and warn "Uh oh, two large caves are linked!";
	$nodes{$x}->{$y} = 1;
	$nodes{$y}->{$x} = 1;
}

exists $nodes{start} or die "No starting point!";
exists $nodes{end} or die "No ending point!";

# $repeat tracks if a small cave has already been used twice.
sub find_routes ($repeat, @current) {
	@current or @current = "start";
	say STDERR "Current path: " . join " -> ", @current;
	my @routes;
	my $pos = $current[-1];
	for my $link (keys $nodes{$pos}->%*) {
		if ($link eq 'start') { next; } # Skip the 'start' node: it can never be used twice.
		if ($link eq 'end') { # This is the terminus node.
			my $path = [ @current, $link ];
			say STDERR "Resolved path: " . join " -> ", @$path;
			push @routes, $path;
			next;
		}
		# uppercase nodes can be reused, lowercase nodes allowed if they aren't used yet.
		elsif ($link =~ /^[A-Z]+$/ || 0 == grep { $_ eq $link } @current) {
			push @routes, find_routes($repeat, @current, $link);
		}
		elsif (!$repeat) {
			# Lowercase node that we've already used once: we can use it if we haven't used a node twice yet.
			push @routes, find_routes(1, @current, $link);
		}
	}
	return @routes;
}

my @r = find_routes 0, 'start';

my $rct = scalar @r;

say "Number of paths: $rct";
