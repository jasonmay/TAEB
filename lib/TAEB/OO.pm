package TAEB::OO;
use Moose ();
use MooseX::ClassAttribute ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use namespace::autoclean ();

use TAEB::Meta::Trait::Persistent;
use TAEB::Meta::Trait::GoodStatus;
use TAEB::Meta::Trait::DontInitialize;
use TAEB::Meta::Types;
use TAEB::Meta::Overload;

my ($moose_import, $moose_unimport) = Moose::Exporter->build_import_methods(
    also      => ['Moose', 'MooseX::ClassAttribute'],
    with_meta => ['extends', 'subscribe'],
);

# make sure using extends doesn't wipe out our base class roles
sub extends {
    my ($meta, @superclasses) = @_;
    Class::MOP::load_class($_) for @superclasses;
    for my $parent (@superclasses) {
        goto \&Moose::extends if $parent->can('does')
                              && $parent->does('TAEB::Role::Initialize');
    }
    # i'm assuming that after apply_base_class_roles, we'll have a single
    # base class...
    my ($superclass_from_metarole) = $meta->superclasses;
    push @_, $superclass_from_metarole;
    goto \&Moose::extends;
}

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
    shift;
    my %options = @_;
    Moose->init_meta(%options);
    my @base_class_roles = (
        'TAEB::Role::Initialize',
        'TAEB::Role::Subscription',
        'TAEB::Role::Logger',
    );
    # the memory leak doesn't exist in 5.8, and will (hopefully) be fixed by
    # the 5.10.1 release
    push @base_class_roles, 'TAEB::Role::WeakenFix' if $] == 5.010;
    Moose::Util::MetaRole::apply_base_class_roles(
        for_class => $options{for_class},
        roles     => \@base_class_roles,
    );
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class                 => $options{for_class},
        #metaclass_roles           => ['MooseX::NonMoose::Meta::Role::Class'],
        #constructor_class_roles   => ['MooseX::NonMoose::Meta::Role::Constructor'],
        $options{for_class} =~ /^TAEB::Action/ ?
            (attribute_metaclass_roles => ['TAEB::Meta::Trait::Provided'])
          : (),
    );
    return $options{for_class}->meta;
}

sub import {
    my $caller = caller;
    namespace::autoclean->import(
        -cleanee => $caller,
    );

    goto $moose_import;
}

sub unimport {
    warn "no TAEB::OO is no longer necessary";
    goto $moose_unimport;
}

1;

