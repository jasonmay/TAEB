#!/usr/bin/env perl
package TAEB::Knowledge::Item::Food;
use MooseX::Singleton;
use TAEB::Knowledge::Monster; # for corpses

has list => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $foods = {
            'meatball' => {
                cost => 5, weight => 1, nutrition => 5, time => 1
            },
            'meat ring' => {
                cost => 5, weight => 1, nutrition => 5, time => 1
            },
            'meat stick' => {
                cost => 5, weight => 1, nutrition => 5, time => 1
            },
            'egg' => {
                cost => 9, weight => 1, nutrition => 80, time => 1, unsafe => 1,
            },
            'tripe ration' => {
                cost => 15, weight => 10, nutrition => 200, time => 2, unsafe => 1,
            },
            'huge chunk of meat' => {
                cost => 105, weight => 400, nutrition => 2000, time => 20
            },
            'kelp frond' => {
                cost => 6, weight => 1, nutrition => 30, time => 1
            },
            'eucalyptus leaf' => {
                cost => 6, weight => 1, nutrition => 30, time => 1
            },
            'clove of garlic' => {
                cost => 7, weight => 1, nutrition => 40, time => 1
            },
            'sprig of wolfsbane' => {
                cost => 7, weight => 1, nutrition => 40, time => 1
            },
            'apple' => {
                cost => 7, weight => 2, nutrition => 50, time => 1
            },
            'carrot' => {
                cost => 7, weight => 2, nutrition => 50, time => 1
            },
            'pear' => {
                cost => 7, weight => 2, nutrition => 50, time => 1
            },
            'banana' => {
                cost => 9, weight => 2, nutrition => 80, time => 1
            },
            'orange' => {
                cost => 9, weight => 2, nutrition => 80, time => 1
            },
            'melon' => {
                cost => 10, weight => 5, nutrition => 100, time => 1
            },
            'slime mold' => {
                cost => 17, weight => 5, nutrition => 250, time => 1
            },
            'fortune cookie' => {
                cost => 7, weight => 1, nutrition => 40, time => 1
            },
            'candy bar' => {
                cost => 10, weight => 2, nutrition => 100, time => 1
            },
            'cream pie' => {
                cost => 10, weight => 10, nutrition => 100, time => 1
            },
            'lump of royal jelly' => {
                cost => 15, weight => 2, nutrition => 200, time => 1
            },
            'pancake' => {
                cost => 15, weight => 2, nutrition => 200, time => 2
            },
            'C-ration' => {
                cost => 20, weight => 10, nutrition => 300, time => 1
            },
            'K-ration' => {
                cost => 25, weight => 10, nutrition => 400, time => 1
            },
            'cram ration' => {
                cost => 35, weight => 15, nutrition => 600, time => 3
            },
            'food ration' => {
                cost => 45, weight => 20, nutrition => 800, time => 5
            },
            'lembas wafer' => {
                cost => 45, weight => 5, nutrition => 800, time => 2
            },
        };

        # Japanese name mapping
        $foods->{'gunyoki'} = $foods->{'food ration'};

        # Collect monster corpses
        my $monsterlist = TAEB::Knowledge::Monster->list;
        while (my ($name, $stats) = each %$monsterlist) {
            $foods->{"$name corpse"} = $stats->{corpse};
            $foods->{"$name corpse"}->{corpse} = 1;
        }

        # tag each food with its name
        while (my ($name, $stats) = each %$foods) {
            $stats->{name} = $name;
        }

        return $foods;
    },
);

sub food {
    my $self = shift;
    my $item = TAEB::Knowledge::Item->canonicalize_item(shift);

    return $self->list->{$item};
}

sub should_eat {
    my $self = shift;
    my $food = shift;

    $self->food($food) if !ref($food);
    return 0 if $food->{unsafe};
    return 0 if $food->{corpse} && $food->{name} !~ /lichen|lizard/; # :|
    return 1;
}

1;

