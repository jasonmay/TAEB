package TAEB::Display;
use TAEB::OO;
use TAEB::Display::Color;
use TAEB::Display::Menu;
use MooseX::ABC;

use Log::Dispatch::Null;
use Scalar::Util qw(weaken);

requires 'get_key';

# whether or not this output writes to the terminal: if it does, we don't want
# to also be sending warnings/errors there, for example.
use constant to_screen => 0;

sub BUILD {
    my $self = shift;
    my $weakself = weaken $self;
    my $log = $self->log;

    $log->remove_as_default('taeb-warning');
    $log->remove_as_default('taeb-error');

    $log->add_as_default(Log::Dispatch::Null->new(
        name => 'taeb-warning',
        min_level => 'warning',
        max_level => 'warning',
        callbacks => sub {
            my %args = @_;
            if (!$weakself->to_screen) {
                local $SIG{__WARN__};
                warn $args{message};
            }
        },
    ));
    $log->add_as_default(Log::Dispatch::Null->new(
        name => 'taeb-error',
        min_level => 'error',
        callbacks => sub {
            my %args = @_;
            if (!$weakself->to_screen) {
                local $SIG{__WARN__};
                confess $args{message};
            }
            else {
                $weakself->complain(Carp::shortmess($args{message}));
            }
        },
    ));
}

sub reinitialize {
    inner();
    shift->redraw(force_clear => 1);
}

sub display_menu {
    my $self = shift;
    my $menu = shift;

    inner($menu);
    $self->redraw(force_clear => 1);

    return $menu->selected;
}

sub deinitialize { }

sub notify { }

sub redraw { }

sub display_topline { }

sub place_cursor { }

sub try_key { }

sub change_draw_mode { }

__PACKAGE__->meta->make_immutable;

1;

