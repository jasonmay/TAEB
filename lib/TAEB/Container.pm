package TAEB::Container;
use TAEB::OO;
use Bread::Board;

use Cwd 'abs_path';
use File::Spec;
use File::HomeDir;
use Log::Dispatch::Null;
use Scalar::Util qw(weaken);
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
    handles => [qw(fetch)],
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
    my $self = shift;

    container 'Log' => as {
        service dir => $self->config->taebdir_file('log');
        service log => (
            class        => 'TAEB::Logger',
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
            dependencies => wire_names(qw(config Log/log)),
        );
    };
}

sub _build_container {
    my $self = shift;
    my $config = $self->config;
    my $container = weaken($self);

    container 'TAEB' => as {
        $self->_log_container;
        $self->_plugin_container($_) for qw(Interface Display AI);

        service vt => (
            class => 'TAEB::VT',
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
