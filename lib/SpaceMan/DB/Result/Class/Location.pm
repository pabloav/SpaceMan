use utf8;
package SpaceMan::DB::Result::Class::Location;
use strict; use warnings;
use Moose;
use Set::Object;
use Digest::SHA1;
use MIME::Base64;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'class_locations' );

__PACKAGE__->add_columns(
    id              => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
    },
    name            => {
        data_type           => 'varchar',
        size                => 64,
        is_nullable         => 0,
    },
    info            => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    url             => {
        data_type           => 'varchar',
        size                => 255,
        is_nullable         => 1,
    },
    maximum_students    => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->add_unique_constraint( [qw( name )] );

#__PACKAGE__->has_many(
#    'sessions',
#    'SpaceMan::DB::Result::Class::Session',
#    { 'foreign.class_id' => 'self.id' },
#    { cascade_copy => 0, cascade_delete => 0 },
#);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
