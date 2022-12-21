#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %ls = ( "/" => 0 );

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
my @files = grep { !m{/$} } keys %ls;

my $score = undef;

use constant { TOTAL => 70000000, NEEDED => 30000000 };

foreach my $dir (@dirs) {
	my @contents = grep { m{^\Q$dir\E} } @files;
	my @sizes = @ls{@contents};
	my $total = List::Util::sum0 @sizes;
	$ls{$dir} = $total;
}

my $used = $ls{"/"};

my $current_free = TOTAL - $used;

my $need_to_free = NEEDED - $current_free;

my @candidates = grep { $ls{$_} >= $need_to_free } @dirs;

my ($best) = sort { $ls{$a} <=> $ls{$b} } @candidates;

$score = $ls{$best};

say $score;
