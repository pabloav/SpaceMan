use utf8;
package SpaceMan::DB::Result::Event;
use strict; use warnings;
use Moose;
use Set::Object;
use Digest::SHA1;
use MIME::Base64;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'events' );

__PACKAGE__->add_columns(
    id              => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'event_id_seq',
    },
    type            => {
        data_type           => 'varchar',
        size                => 16,
        is_nullable         => 0,
        default_value       => 'Unknown',
    },
    summary         => {
        data_type           => 'varchar',
        is_nullable         => 0,
        size                => 128,
    },
    description     => {
        data_type           => 'text',
        is_nullable         => 1,
        size                => 32,
    },
    datetime        => {
        data_type           => 'timestamp without time zone',
        is_nullable         => 0,
    },
    location        => {
        data_type           => 'varchar',
        size                => 64,
        is_nullable         => 0,
    },
    created_timestamp   => {
        data_type           => 'timestamp without time zone',
        is_nullable         => 0,
        default_value       => \'now()',
    },
    sponsor_id          => {
        data_type           => 'integer',
        is_nullable         => 1,
        is_foreign_key      => 1,
    },
    maximum_attendance  => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );


__PACKAGE__->belongs_to(
    'sponsor',
    'SpaceMan::DB::Result::Person',
    'sponsor_id',
    { join_type => 'left' }
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
