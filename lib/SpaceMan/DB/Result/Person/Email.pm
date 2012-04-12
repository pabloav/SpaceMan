use utf8;
package SpaceMan::DB::Result::Person::Email;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table("person_emails");

__PACKAGE__->add_columns(
    id                  => {
        data_type           => "integer",
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => "person_emails_id_seq",
    },
    person_id           => {
        data_type           => "integer",
        is_foreign_key      => 1,
        is_nullable         => 0,
    },
    email_address       => {
        data_type           => "varchar",
        is_nullable         => 0,
        size                => 128,
    },
    primary_address     => {
        data_type           => "boolean",
        default_value       => \"false",
        is_nullable         => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( [ "email_address" ] );

__PACKAGE__->belongs_to(
  "person",
  "SpaceMan::DB::Result::Person",
  { id => "person_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
