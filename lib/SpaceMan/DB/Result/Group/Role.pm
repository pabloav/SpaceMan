use utf8;
package SpaceMan::DB::Result::Group::Role;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( "group_roles" );

__PACKAGE__->add_columns(
    group_id        => {
        data_type       => "integer",
        is_foreign_key  => 1,
        is_nullable     => 0,
    },
    role_id         => {
        data_type       => "integer",
        is_foreign_key  => 1,
        is_nullable     => 0,
    },
);

__PACKAGE__->set_primary_key(qw( group_id role_id ));

__PACKAGE__->belongs_to(
  "group",
  "SpaceMan::DB::Result::Group",
  { id => "group_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
  "role",
  "SpaceMan::DB::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
