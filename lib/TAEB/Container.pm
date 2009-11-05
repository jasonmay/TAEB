package TAEB::Container;
use TAEB::OO;
use Bread::Board;

has container => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    builder => '_build_container',
);

sub _config_path {
    # XXX: move the File::HomeDir logic from TAEB::Config here
    return "$ENV{HOME}/.taeb";
}

sub _build_container {
    my $self = shift;
    container 'TAEB' => as {
        service config_file => 'config.yml';
        service config_path => $self->_config_path;
        service config => (
            class     => 'TAEB::Config',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('config_file'),
                depends_on('config_path'),
            ],
        );

        service app => (
            class => 'TAEB',
            block => sub {
                my $s = shift;
                return TAEB->new(
                    # XXX
                );
            },
            dependencies => [
                depends_on('config'),
            ],
        );
    };
}

sub create_taeb {
    my $self = shift;
    return $self->fetch('app')->get;
}

1;
