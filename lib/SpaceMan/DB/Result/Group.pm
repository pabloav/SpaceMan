use utf8;
package SpaceMan::DB::Result::Group;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table("groups");

__PACKAGE__->add_columns(
    id                  => {
        data_type           => "integer",
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => "groups_id_seq",
    },
    name                => {
        data_type           => "varchar",
        is_nullable         => 0,
        size                => 64,
    },
    posix_gid           => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    description         => {
        data_type           => "text",
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key( "id" );

__PACKAGE__->add_unique_constraint( [ 'name' ] );
__PACKAGE__->add_unique_constraint( [ 'posix_gid' ] );

__PACKAGE__->has_many(
    'group_people',
    'SpaceMan::DB::Result::Person::Group',
    { 'foreign.group_id' => 'self.id' },
    { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many( 'people', 'group_people', 'person' );

sub dn {
    return sprintf( "cn=%s,ou=Groups,%s",
        shift->name,
        SpaceMan->config->ldap_base
    );
}

sub ldap_attrs {
    my $self = shift;

    return (
        objectClass     => [qw( posixGroup )], 
        gidNumber       => $self->posix_gid,
        ( $self->people->count ? (
            memberUid       => [ map { $_->username } $self->people ], 
        ) : () ),
    );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
