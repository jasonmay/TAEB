#!/usr/bin/env perl
package TAEB::Meta::Role::Reblessing;
use Moose::Role;

requires 'base_class';

sub rebless {
    my $self    = shift;
    my $new_pkg = shift;

    my $base    = $self->base_class;
    my $old_pkg = blessed $self;

    # if the new_pkg doesn't exist, then just rebless into the base class
    return $self->downgrade unless $new_pkg->can('meta');

    # no work to be done, yay
    return if $old_pkg eq $new_pkg;

    # are we a superclass of the new package? if not, we need to revert
    # to a regular Tile so we can be reblessed into a subclass of Tile
    # in other words, Moose doesn't let you rebless into a sibling class
    unless ($new_pkg->isa($old_pkg)) {
        $self->downgrade("Reblessing a $old_pkg into $base (temporarily) because Moose doesn't let us rebless into sibling classes.");
    }

    TAEB->debug("Reblessing a $old_pkg into $new_pkg.");

    # and do the rebless, which does all the typechecking and whatnot
    $new_pkg->meta->rebless_instance($self);
}

sub downgrade {
    my $self = shift;
    my $base = $self->base_class;
    my $old  = blessed($self);

    return $self if $old eq $base;

    TAEB->debug(shift || "Reblessing $old into $base.");

    # rebless_instance only lets you get more specific, not less specific
    bless $self => $base;
}

no Moose::Role;

1;
