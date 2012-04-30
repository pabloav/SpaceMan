use utf8;
package SpaceMan::DB::Result::Class::Session::Student;
use strict; use warnings;
use Moose;
use Set::Object;
use Digest::SHA1;
use MIME::Base64;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'class_session_students' );

__PACKAGE__->add_columns(
    session_id      => {
        data_type           => 'integer',
        is_nullable         => 0,
        is_foreign_key      => 1,
    },
    person_id       => {
        data_type           => 'integer',
        is_nullable         => 0,
        is_foreign_key      => 1,
    },
    registered_timestamp    => {
        data_type           => 'timestamp without time zone',
        is_nullable         => 0,
        default_value       => \'now()',
    },
    paid_timestamp          => {
        data_type           => 'timestamp without time zone',
        is_nullable         => 1,
    },
    waiting_list            => {
        data_type           => 'boolean',
        is_nullable         => 0,
        default_value       => \'false',
    },
);

__PACKAGE__->set_primary_key(qw( session_id person_id ));

__PACKAGE__->belongs_to(
    'session',
    'SpaceMan::DB::Result::Class::Session',
    'session_id'
);

__PACKAGE__->belongs_to(
    'person',
    'SpaceMan::DB::Result::Person',
    'person_id'
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
