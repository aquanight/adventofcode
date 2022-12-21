#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %ls;

my @current;

my $ls = undef;

while (<>) {
	chomp;
	if (/^\$/) { undef $ls; }
	if (/^\$ cd \/$/) {
		@current = ();
	}
	elsif (/^\$ cd ..$/) {
		pop @current;
	}
	elsif ((my $where) = /^\$ cd (.*)$/) {
		my $target = "/" . join("/", @current, $where) . "/";
		exists $ls{$target} or die "Input trouble looking for $target in [" . join(", " => keys %ls) . "]";
		push @current, $where;
	}
	elsif (/^\$ ls$/) {
		if (@current) {
			$ls = "/" . join("/", @current) . "/";
		}
		else {
			$ls = "/";
		}
	}
	elsif (defined $ls) {
		if ((my $subdir) = /^dir (.*)$/) {
			$ls{"${ls}$subdir/"} = 0;
		}
		elsif (my ($size, $name) = /^(\d+) (.*)$/) {
			$ls{"${ls}$name"} = $size;
		}
	}
}

my %dir_sizes;

my @dirs = grep { m{/$} } keys %ls;

my $score = 0;

foreach my $dir (@dirs) {
	my @contents = grep { m{^\Q$dir\E} } keys %ls;
	my @sizes = @ls{@contents};
	my $total = List::Util::sum0 @sizes;
	if ($total < 100000) {
		$score += $total;
	}
}

say $score;
