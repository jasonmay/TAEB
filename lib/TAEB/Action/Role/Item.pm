#!/usr/bin/env perl
package TAEB::Action::Role::Item;
use Moose::Role;

has item => (
    is  => 'rw',
    isa => 'TAEB::World::Item',
);

sub exception_missing_item {
    my $self = shift;
    TAEB->debug("We don't have item " . $self->item . ", escaping.");
    TAEB->inventory->remove($self->item->slot);
    TAEB->enqueue_message(check => 'inventory');
    $self->aborted(1);
    return "\e";
}

1;

