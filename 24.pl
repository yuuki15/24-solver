#!/usr/bin/env perl
#
# Lists all "distinct" solutions to the 24 puzzle.
#
# Usage:
# perl 24.pl [number to make=24] [min number to use=1] [max number to use=13]
#
use v5.10;
use strict;
use warnings;
use autodie;

my $number_to_make    = shift // 24;
my $min_number_to_use = shift // 1;
my $max_number_to_use = shift // 13;
my @numbers_to_use    = ($min_number_to_use .. $max_number_to_use);

# Loads the `normalize` and `negate` subroutines.
require "./normalize.pl";

# Loads the possible 733 expressions.  Cf.: https://oeis.org/A247982
open my $fh, "<", "expressions.txt";
my @expressions = map { s/\s+//g; $_ } <$fh>; # Removes whitespace.
close $fh;

# Iterates over the possible 4-combinations with repetition of numbers.  If 13
# numbers are used, there would be C(13+4-1, 4) = 1820 ways.  Cf.:
# https://mathworld.wolfram.com/Multichoose.html
for my $numbers (combinations_with_repetition(\@numbers_to_use, 4)) {
    my ($a, $b, $c, $d) = @$numbers;

    my @solutions;
    my %seen;

    # Iterates over the expressions.
    for my $expr (@expressions) {
        my $value = eval $expr;

        # Skips on a division by zero.
        if ($@) {
            next;
        }

        # Checks if the value is equal to the number to make, ignoring the sign.
        if (abs($value) eq $number_to_make) {
            # The expression with variables substituted with numbers (but not
            # evaluated).
            my $subst_expr = eval qq("$expr");

            if ($value < 0) {
                $subst_expr = negate($subst_expr);
                $subst_expr =~ s{ \s+ | ^\( | \)$ }{}gx;
            }

            my $normal_form = normalize($subst_expr);

            if (not exists $seen{$normal_form}) {
                push @solutions, $normal_form;
                $seen{$normal_form} = 1;
            }
        }
    }

    if (@solutions) {
        local $, = "\t";
        local $\ = "\n";
        print(
            join($max_number_to_use < 10 ? "" : " ", @$numbers),
            scalar(@solutions),
            @solutions,
        );
    }
}

# Generates the k-combinations with repetition of an array, like Python's
# `itertools.combinations_with_replacement` or Ruby's
# `Array#repeated_combination`.
sub combinations_with_repetition {
    my ($array, $k) = @_;

    if ($k == 0) {
        return ([]);
    }

    if (@$array == 0) {
        return ();
    }

    my ($first, @rest) = @$array;
    return (
        (map { [$first, @$_] } combinations_with_repetition($array, $k - 1)),
        combinations_with_repetition(\@rest, $k),
    );
}
