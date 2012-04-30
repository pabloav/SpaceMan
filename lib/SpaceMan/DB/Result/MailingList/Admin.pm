use utf8;
package SpaceMan::DB::Result::MailingList::Admin;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'mailing_list_admins' );

__PACKAGE__->add_columns(
    mailing_list_id    => {
        data_type => "integer", is_foreign_key => 1, is_nullable => 0,
    },
    person_id   => {
        data_type => "integer", is_foreign_key => 1, is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key(qw( mailing_list_id person_id ));

__PACKAGE__->belongs_to(
    "person",
    "SpaceMan::DB::Result::Person",
    { id => "person_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "mailing_list",
    "SpaceMan::DB::Result::MailingList",
    { id => "mailing_list_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
