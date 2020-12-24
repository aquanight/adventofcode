#!/usr/bin/perl
use v5.30;
use warnings;

$/ = ""; # paragraph mode

my %fields = (
	byr => sub { /^\d{4}$/ && $_ >= 1920 && $_ <= 2002 },
	iyr => sub { /^\d{4}$/ && $_ >= 2010 && $_ <= 2020 },
	eyr => sub { /^\d{4}$/ && $_ >= 2020 && $_ <= 2030 },
	hgt => sub {
		if (/^(\d+)cm/) {
			return $1 >= 150 && $1 <= 193;
		} elsif (/^(\d+)in/) {
			return $1 >= 59 && $1 <= 76;
		} else {
			return "";
		}
       	},
	hcl => sub { /^#[0-9a-f]{6}$/ },
	ecl => sub { /^(amb|blu|brn|gry|grn|hzl|oth)$/ },
	pid => sub { /^\d{9}$/ },
	cid => undef,
);

my $validcount = 0;

RECORD: while (<>) {
	my @fields = split /\s+/, $_;
	my %record = map { split /:/, $_, 2 } @fields;
	FIELD: for my $field (keys %fields) {
		my $vproc = $fields{$field}//next FIELD;
		exists $record{$field} or next RECORD;
		local $_ = $record{$field};
		$vproc->() or next RECORD;
	}
	++$validcount;
}

say "Valid records: $validcount";
