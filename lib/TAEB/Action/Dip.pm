#!/usr/bin/env perl
package TAEB::Action::Dip;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Item';

use constant command => "#dip\n";

has '+item' => (
    isa      => 'TAEB::World::Item',
    required => 1,
);

has into => (
    traits  => [qw/Provided/],
    isa     => 'TAEB::World::Item | Str',
    default => 'fountain',
);

sub respond_dip_what { shift->item->slot }

sub respond_dip_into_water {
    my $self  = shift;
    my $item  = shift;
    my $water = shift;

    # fountains are very much a special case - if water we want moat, pool, etc
    return 'y' if $self->into eq 'water' && $water ne 'fountain';

    return 'y' if $self->into eq $water;

    return 'n';
}

sub respond_dip_into_what {
    my $self = shift;
    return $self->into->slot if blessed($self->into);

    TAEB->error("Unable to dip into '" . $self->into . "'. Sending escape, but I doubt this will work.");
    return "\e";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

