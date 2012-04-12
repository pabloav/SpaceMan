use utf8;
package SpaceMan::DB::Result::Person::Role;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table("person_roles");

__PACKAGE__->add_columns(
  "person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("person_id", "role_id");

__PACKAGE__->belongs_to(
  "person",
  "SpaceMan::DB::Result::Person",
  { id => "person_id" },
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
