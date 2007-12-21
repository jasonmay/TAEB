#!/usr/bin/env perl
package TAEB::AI::Senses;
use Moose;

has hp => (
    is  => 'rw',
    isa => 'Int',
);

has maxhp => (
    is  => 'rw',
    isa => 'Int',
);

has hunger => (
    is      => 'rw',
    isa     => 'Int',
    default => 700,
);

has in_wereform => (
    is  => 'rw',
    isa => 'Bool',
);

has can_kick => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

sub update {
    my $self = shift;

    my $status = TAEB->vt->row_plaintext(22);
    my $botl   = TAEB->vt->row_plaintext(23);

    if ($botl =~ /HP:(\d+)\((\d+)\)/) {
        $self->hp($1);
        $self->maxhp($2);
    }
    else {
        TAEB->error("Unable to parse HP from '$botl'");
    }

    $self->in_wereform($status =~ /^TAEB the Were/ ? 1 : 0);

    if (TAEB->messages =~ /You can't move your leg/
     || TAEB->messages =~ /You are caught in a bear trap/) {
        $self->can_kick(0);
    }
    # XXX: there's no message when you leave a bear trap. I'm not sure of the
    # best solution right now. a way to say "run this code when I move" maybe

    # we lose 1 hunger per turn. good enough for now
    $self->hunger($self->hunger - 1);

    # we can definitely know some things about our hunger
    if ($botl =~ /\bSat/) {
        $self->hunger(1000) if $self->hunger < 1000;
    }
    elsif ($botl =~ /\bHun/) {
        $self->hunger(149)  if $self->hunger > 149;
    }
    elsif ($botl =~ /\bWea/) {
        $self->hunger(49)   if $self->hunger > 49;
    }
    elsif ($botl =~ /\bFai/) {
        $self->hunger(-1)   if $self->hunger > -1;
    }
    else {
        $self->hunger(999) if $self->hunger > 999;
        $self->hunger(150) if $self->hunger < 150;
    }
}

1;

