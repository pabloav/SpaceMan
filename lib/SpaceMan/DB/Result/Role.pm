use utf8;
package SpaceMan::DB::Result::Role;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table("roles");

__PACKAGE__->add_columns(
    id              => {
        data_type           => "integer",
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => "roles_id_seq",
    },
    name            => {
        data_type           => "varchar",
        is_nullable         => 0,
        size                => 32,
    },
);

__PACKAGE__->set_primary_key( "id" );

__PACKAGE__->add_unique_constraint("roles_name_key", ["name"]);

__PACKAGE__->has_many(
    "person_roles",
    "SpaceMan::DB::Result::Person::Role",
    { "foreign.role_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "people", "person_roles", "person" );

__PACKAGE__->has_many(
    "group_roles",
    "SpaceMan::DB::Result::Group::Role",
    { "foreign.role_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "groups", "group_roles", "group" );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
