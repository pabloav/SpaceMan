use utf8;
package SpaceMan::DB::Result::Class;
use strict; use warnings;
use Moose;
use Set::Object;
use Digest::SHA1;
use MIME::Base64;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'classes' );

__PACKAGE__->add_columns(
    id              => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
    },
    name            => {
        data_type           => 'varchar',
        size                => 8,
        is_nullable         => 1,
    },
    summary         => {
        data_type           => 'varchar',
        is_nullable         => 0,
        size                => 128,
    },
    description     => {
        data_type           => 'text',
        is_nullable         => 1,
    },
    location_id     => {
        data_type           => 'integer',
        is_nullable         => 1,
        is_foreign_key      => 1,
    },
    url             => {
        data_type           => 'varchar',
        size                => 255,
        is_nullable         => 1,
    },
    cost            => {
        data_type           => 'money',
        is_nullable         => 1,
    },
    created_timestamp   => {
        data_type           => 'timestamp without time zone',
        is_nullable         => 0,
        default_value       => \'now()',
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
    'sessions',
    'SpaceMan::DB::Result::Class::Session',
    { 'foreign.class_id' => 'self.id' },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
    'location',
    'SpaceMan::DB::Result::Class::Location',
    'location_id',
    { join_type => 'left' },
);

sub next_start_date {
    my $self = shift;

    my $rs = $self->sessions->search(
        { date => \'is not null' },
        { order_by => 'date' }
    );
}

sub next_scheduled_session {
    my $self = shift;

    return $self->sessions->in_future->first;
#    search(
#        \[ 'schedules.date >= CURRENT_DATE' ],
#        {
#            join        => 'schedules',
#            order_by    => 'schedules.date ASC, schedules.start_time ASC'
#        },
#    )->first;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
