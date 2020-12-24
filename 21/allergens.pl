#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';
no warnings 'experimental';

use feature qw/refaliasing declared_refs/;

my @records;

my %ingredients;
my %allergens;

sub dumpdata {
	for my $k (sort keys %ingredients) {
		if (ref $ingredients{$k}) {
			printf "%s -> [%s]\n", $k, join " ", sort keys $ingredients{$k}->%*;
		}
		else {
			printf "%s -> %s\n", $k, $ingredients{$k}//"<none>";
		}
	}
	for my $k (sort keys %allergens) {
		if (ref $allergens{$k}) {
			printf "%s -> [%s]\n", $k, join " ", sort keys $allergens{$k}->%*;
		}
		else {
			printf "%s -> %s\n", $k, $allergens{$k}//"<none>";
		}
	}
	say "---";
}

while (<>) {
	chomp;
	my ($ingredients, $allergens) = /^([\w ]+) (?:\(contains ([\w, ]+)\))?/;
	my %ing = map { $_ => 1 } split / +/, $ingredients;
	my %all;
	if (defined $allergens) {
		%all = map { $_ => 1 } split / *, */, $allergens;
	}
	push @records, [ \%ing, \%all, $_ ];
	@ingredients{keys %ing} = (1) x scalar keys %ing;
	@allergens{keys %all} = (1) x scalar keys %all;
}

# Initialize the ingredient list with what possible allergens they could be.
$_ = { map { $_ => 1 } keys %allergens } for values %ingredients;

# Likewise for allergens
$_ = { map { $_ => 1 } keys %ingredients } for values %allergens;

#dumpdata;

for my $record (@records) {
	my (\%ing, \%all, $raw) = @$record;
	#say "Processing $raw";
	#printf "Ingredients: %s\n", join " ", sort keys %ing;
	#printf "Allergens: %s\n", join " ", sort keys %all;

	# Allergens listed on this line MUST be in one of the ingredients listed
	for my $allergen (keys %all) {
		for my $k (keys %ingredients) {
			next if (exists $ing{$k});
			# Ingredient not in this list so it can't have this allergen
			delete $ingredients{$k}->{$allergen};
			delete $allergens{$allergen}->{$k};
		}
	}
	#say "After [$raw]:";
	#dumpdata;
}

my $limit = 1000;

#dumpdata;

# Now resolve ingredient:allergen pairs we have:
LOOP: while (1) {
	# Do we have any empty hashes? Those can't have any allergens, so remove their hash.
	#dumpdata;
	my @check = grep { ref $ingredients{$_} } keys %ingredients;
	#say "@check";
	for my $empty (grep { scalar(keys $ingredients{$_}->%*) == 0 } @check) {
		say "No possible allergen for ingredient '$empty'";
		$ingredients{$empty} = undef;
		next LOOP;
	}

	for my $single (grep { scalar(keys $ingredients{$_}->%*) == 1 } @check) {
		my ($allergen) = keys $ingredients{$single}->%*;

		say "Ingredient '$single' has allergen '$allergen'";
		$ingredients{$single} = $allergen;
		$allergens{$allergen} = $single;
		for my $k (keys %ingredients) {
			next unless ref $ingredients{$k};
			delete $ingredients{$k}->{$allergen};
		}
		for my $k (keys %allergens) {
			next unless ref $allergens{$k};
			delete $allergens{$k}->{$single};
		}
		next LOOP;
	}

	last;
	#die unless --$limit;
}

#dumpdata;

my $sum = 0;
for my $record (@records) {
	my (\%ing, \%all, $raw) = @$record;

	$sum += scalar grep { ! defined $ingredients{$_} } keys %ing;
}

say "Number of ingredients: $sum";

my $bad = join ",", sort { $ingredients{$a} cmp $ingredients{$b} } grep { defined $ingredients{$_} } keys %ingredients;

say "Bad ingredients: $bad";
