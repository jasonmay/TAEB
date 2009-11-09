package TAEB::Role::Logger;
use Moose::Role;

has log => (
    is       => 'ro',
    isa      => 'TAEB::Logger',
    required => 1,
);

no Moose::Role;
1;
