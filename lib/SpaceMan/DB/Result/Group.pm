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
    restricted_access   => {
        data_type           => "boolean",
        default_value       => \"false",
        is_nullable         => 0,
    },
    restricted_archive  => {
        data_type           => "boolean",
        default_value       => \"false",
        is_nullable         => 0,
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
    "group_roles",
    "SpaceMan::DB::Result::Group::Role",
    { "foreign.group_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many( "roles", "group_roles", "role" );

__PACKAGE__->has_many(
    'group_people',
    'SpaceMan::DB::Result::Person::Group',
    { 'foreign.group_id' => 'self.id' },
    { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many( 'people', 'group_people', 'person' );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
