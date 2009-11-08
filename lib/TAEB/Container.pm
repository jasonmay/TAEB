package TAEB::Container;
use TAEB::OO;
use Bread::Board;

use Cwd 'abs_path';
use File::Spec;
use File::HomeDir;
use Log::Dispatch::Null;
use TAEB::Config;
use TAEB::Logger;
use TAEB::VT;

has config_file => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => 'config.yml',
);

has config_path => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_config_path',
);

has config => (
    is      => 'ro',
    isa     => 'TAEB::Config',
    lazy    => 1,
    default => sub {
        my $self = shift;
        TAEB::Config->new(
            config_path => $self->config_path,
            config_file => $self->config_file,
        );
    },
);

has container => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    builder => '_build_container',
);

sub _build_config_path {
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

sub _log_container {
    container 'Log' => as {
        service dir => $config->taebdir_file('log');
        service log => (
            block => sub {
                my $s = shift;

                my $log = TAEB::Logger->new(log_dir => $s->param('log_dir'));
                $log->add_as_default(Log::Dispatch::Null->new(
                    name => 'taeb-warning',
                    min_level => 'warning',
                    max_level => 'warning',
                    callbacks => sub {
                        my %args = @_;
                        my $display = $container->fetch('Display/display')->get;
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
                        my $display = $container->fetch('Display/display')->get;
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
            lifecycle    => 'Singleton',
            dependencies => wire_names(qw(dir)),
        );
    };
}

sub _plugin_container {
    my $self = shift;
    my ($plugin) = @_;
    my $lc_plugin = lc($plugin);
    my $config_method = "get_${lc_plugin}_config";
    my $class_method = "get_${lc_plugin}_class";

    container $plugin => as {
        service config     => $self->config->$config_method;
        service $lc_plugin => (
            class        => $self->config->$class_method,
            lifecycle    => 'Singleton',
            dependencies => wire_names(qw(config Log/log)),
        );
    };
}

sub _build_container {
    my $self = shift;
    my $config = $self->config;
    my $container = $self;

    container 'TAEB' => as {
        $self->_log_container;
        $self->_plugin_container($_) for qw(Interface Display AI);

        service vt => (
            block => sub {
                my $s = shift;
                my $vt = TAEB::VT->new(
                    cols => 80,
                    rows => 24,
                    log  => $s->param('log')
                );
                $vt->option_set(LINEWRAP => 1);
                $vt->option_set(LFTOCRLF => 1);
                return $vt;
            },
            dependencies => wire_names(qw(Log/log)),
        );

        service scraper => (
            class => 'TAEB::ScreenScraper',
            dependencies => wire_names(qw(Log/log)),
        );

        service publisher => (
            class => 'TAEB::Publisher',
            dependencies => wire_names(qw(Log/log)),
        );

        service debugger => (
            class => 'TAEB::Debug',
            dependencies => wire_names(qw(Log/log)),
        );

        service dungeon => ( # persistent
            class => 'TAEB::World::Dungeon',
            dependencies => wire_names(qw(Log/log)),
        );

        service senses => ( # persistent
            class => 'TAEB::Senses',
            dependencies => wire_names(qw(Log/log)),
        );

        service spells => ( # persistent
            class => 'TAEB::World::Spells',
            dependencies => wire_names(qw(Log/log)),
        );

        service item_pool => ( # persistent
            class => 'TAEB::World::ItemPool',
            dependencies => wire_names(qw(Log/log)),
        );

        service app => (
            class => 'TAEB',
            dependencies => wire_names(qw(
                Log/log
                Interface/interface Display/display AI/ai
                vt scraper publisher debugger dungeon senses spells item_pool
            )),
        );
    };
}

sub create_taeb {
    my $self = shift;
    return $self->fetch('app')->get;
}

1;
