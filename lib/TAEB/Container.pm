package TAEB::Container;
use TAEB::OO;
use Bread::Board;

use Cwd 'abs_path';
use File::Spec;
use File::HomeDir;
use Log::Dispatch::Null;
use TAEB::VT;
use TAEB::Logger;

has container => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    builder => '_build_container',
);

sub _config_path {
    $ENV{TAEBDIR} ||= do {
        File::Spec->catdir(File::HomeDir->my_home, '.taeb');
    };

    $ENV{TAEBDIR} = abs_path($ENV{TAEBDIR});

    -d $ENV{TAEBDIR} or mkdir($ENV{TAEBDIR}, 0700) or do {
        local $SIG{__DIE__} = 'DEFAULT';
        die "Please create a $ENV{TAEBDIR} directory.\n";
    };
    return $ENV{TAEBDIR};
}

sub _build_container {
    my $self = shift;
    container 'TAEB' => as {
        service config_file => 'config.yml';
        service config_path => $self->_config_path;
        service config => (
            class        => 'TAEB::Config',
            dependencies => [
                depends_on('config_file'),
                depends_on('config_path'),
            ],
        );

        service interface => (
            block => sub {
                my $s = shift;
                my $config = $s->param('config');

                my $interface_config = $config->get_interface_config;
                return $config->get_interface_class->new($interface_config);
            },
            dependencies => [
                depends_on('config'),
            ],
        );

        service scraper => (
            class => 'TAEB::ScreenScraper',
        );

        service vt => (
            block => sub {
                my $vt = TAEB::VT->new(cols => 80, rows => 24);
                $vt->option_set(LINEWRAP => 1);
                $vt->option_set(LFTOCRLF => 1);
                return $vt;
            },
        );

        service log => (
            block => sub {
                my $s = shift;
                my $display = $s->param('display');

                my $log = TAEB::Logger->new;
                $log->add_as_default(Log::Dispatch::Null->new(
                    name => 'taeb-warning',
                    min_level => 'warning',
                    max_level => 'warning',
                    callbacks => sub {
                        my %args = @_;
                        # XXX: do we need to test for definedness?
                        if (!$display->to_screen) {
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
                        # XXX: do we need to test for definedness?
                        if (!$display->to_screen) {
                            local $SIG{__WARN__};
                            confess $args{message};
                        }
                        else {
                            # XXX: this needs to move from TAEB to TAEB::Display
                            $display->complain(Carp::shortmess($args{message}));
                        }
                    },
                ));
                # XXX: this method needs to move from TAEB to TAEB::Logger
                $log->setup_handlers;
                return $log;
            },
            dependencies => [
                depends_on('display'),
            ],
        );

        service publisher => (
            class => 'TAEB::Publisher',
        );

        service debugger => (
            class => 'TAEB::Debug',
        );

        service display => (
            block => sub {
                my $s = shift;
                my $config = $s->param('config');

                return $config->get_display_class->new;
            },
            dependencies => [
                depends_on('config'),
            ],
        );

        service ai => ( # persistent
            block => sub {
                my $s = shift;
                my $config = $s->param('config');

                return $config->get_ai_class->new;
            },
            dependencies => [
                depends_on('config'),
            ],
        );

        service dungeon => ( # persistent
            class => 'TAEB::World::Dungeon',
        );

        service senses => ( # persistent
            class => 'TAEB::Senses',
        );

        service spells => ( # persistent
            class => 'TAEB::World::Spells',
        );

        service item_pool => ( # persistent
            class => 'TAEB::World::ItemPool',
        );

        service app => (
            class => 'TAEB',
            dependencies => [
                depends_on('config'),
                depends_on('interface'),
                depends_on('scraper'),
                depends_on('vt'),
                depends_on('log'),
                depends_on('publisher'),
                depends_on('debugger'),
                depends_on('display'),
                depends_on('ai'),
                depends_on('dungeon'),
                depends_on('senses'),
                depends_on('spells'),
                depends_on('item_pool'),
            ],
        );
    };
}

sub create_taeb {
    my $self = shift;
    return $self->fetch('app')->get;
}

1;
