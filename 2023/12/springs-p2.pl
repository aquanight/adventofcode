#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

my $sum = 0;

my %seen;

sub process ($spr, @grp) {
	my $key = join "," => $spr, @grp;
	defined $seen{$key} and return $seen{$key};
	#say STDERR "Test $key"
	my $required = List::Util::sum0(@grp) + (@grp - 1);
#	$spr =~ s/^\.+//;
#	if (length($spr) == 0) {
#		return @grp ? 0 : 1;
#	}
	my $amt = 0;
	while (1) {
		if (length $spr < $required) {
			$amt = 0;
			last;
		}
		elsif (length $spr == 0) {
			$amt = @grp ? 0 : 1;
			last;
		}
		elsif ($spr =~ m/^\./) {
			$spr =~ s/^\.+//;
		}
		elsif ($spr =~ m/^\#/) {
			my $group = shift @grp;
			unless ($group) {
				last;
			}
			$required -= ($group + 1);
			# A string of # or ? exactly $group long and does not have a # after it (because that would be $group + 1)
			# But if it has a ? after it, that's okay (and the ? can only be . so it gets eaten)
			if ($spr =~ /^[\#\?]{$group}(?![\#])\??/) {
				$spr = $';
			}
			else {
				# Does not match because the contiguous group is not the correct size
				last;
			}
		}
		elsif ($spr =~ m/^\?/) {
			#say STDERR "Branch $'";
			my $nx = $';
			$amt += __SUB__->(".$nx", @grp);
			$amt += __SUB__->("#$nx", @grp);
			last;
		}
	}
	$seen{$key} = $amt;



#	my $cmd = substr($spr, 0, 1, "");
#	if ($cmd eq '.') {
#		$amt = __SUB__->($spr, @grp);
#	}
#	elsif ($cmd eq '?') {
#		$amt = __SUB__->(".$spr", @grp);
#		$amt += __SUB__->("#$spr", @grp);
#	}
#	elsif ($cmd eq '#') {
#		my $group = shift @grp;
#		unless ($group) {
#			# Not a solution
#			return 0;
#		}
#		--$group;
#		if ($spr =~ /^[\#\?]{$group}(?![\#])\??/) { # Eat a following ? (which can only be .) if it is present
#			$amt = __SUB__->($', @grp);
#		}
#		else {
#			$amt = 0;
#		}
#	}
#	defined $amt or Carp::confess "What?";
#	$seen{$key} = $amt;
	return $amt;
}

while (<>) {
	my ($springs, $groups) = /^([\.\#\?]+) +([\d,]+)$/;


	defined $springs or die "Input error";
	my @groups = split /,/, $groups;

	# Unfold:
	$springs = join "?", ($springs) x 5;
	@groups = (@groups) x 5;

	my $line = 0;

	%seen = ();
	$line = process($springs, @groups);

	say STDERR "$springs $groups : $line";

	$sum += $line;
}

say $sum;
