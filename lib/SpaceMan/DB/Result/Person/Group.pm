use utf8;
package SpaceMan::DB::Result::Person::Group;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'person_groups' );

__PACKAGE__->add_columns(
    person_id   => {
        data_type => "integer", is_foreign_key => 1, is_nullable => 0,
    },
    group_id    => {
        data_type => "integer", is_foreign_key => 1, is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("person_id", "group_id");

__PACKAGE__->belongs_to(
    "person",
    "SpaceMan::DB::Result::Person",
    { id => "person_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "group",
    "SpaceMan::DB::Result::Group",
    { id => "group_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
