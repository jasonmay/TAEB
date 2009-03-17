package TAEB::Message;
use TAEB::OO;

has text => (
    is            => 'ro',
    isa           => 'Str',
    predicate     => 'has_text',
    documentation => 'The text sent by NetHack that generated this message.',
);

# default name for TAEB::Message::Foo::Bar is foo_bar
sub name {
    my $self = shift;
    my $class = blessed($self) || $self;

    $class =~ s/^TAEB::Message:://;
    $class =~ s/::/_/g;

    return lc $class;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

