package TAEB::OO;
use MooseX::ClassAttribute ();
use Moose ();
use Moose::Exporter;

use TAEB::Meta::Trait::Persistent;
use TAEB::Meta::Trait::GoodStatus;
use TAEB::Meta::Trait::DontInitialize;
use TAEB::Meta::Types;
use TAEB::Meta::Overload;

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    also      => ['Moose', 'MooseX::ClassAttribute'],
    with_meta => ['subscribe'],
    install   => [qw(import unimport)],
    base_class_roles => [
        'TAEB::Role::Initialize',
        'TAEB::Role::Subscription',
    ],
    class_metaroles => {
        attribute => ['TAEB::Meta::Trait::Provided'],
    },
);

sub subscribe {
    my $meta = shift;
    my $handler = pop;

    for my $name (@_) {
        my $method_name = "subscription_$name";
        my $super_method = $meta->find_method_by_name($method_name);
        my $method;

        if ($super_method) {
            $method = sub {
                $super_method->execute(@_);
                goto $handler;
            };
        }
        else {
            $method = $handler;
        }

        $meta->add_method($method_name => $method);
    }
}

sub init_meta {
    my ($package, %options) = @_;

    Moose->init_meta(%options);
    $package->$init_meta(%options);
}

1;

