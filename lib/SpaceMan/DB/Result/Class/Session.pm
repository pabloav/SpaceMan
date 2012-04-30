use utf8;
package SpaceMan::DB::Result::Class::Session;
use strict; use warnings;
use Moose;
use Set::Object;
use Digest::SHA1;
use MIME::Base64;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'class_sessions' );

__PACKAGE__->add_columns(
    id              => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'class_id_seq',
    },
    class_id        => {
        data_type           => 'integer',
        is_nullable         => 0,
    },
    location_id     => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    cost            => {
        data_type           => 'money',
        is_nullable         => 1,
    },
    maximum_students    => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
    start_date      => {
        data_type           => 'date',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to(
    'class',
    'SpaceMan::DB::Result::Class',
    'class_id',
);

__PACKAGE__->belongs_to(
    'location',
    'SpaceMan::DB::Result::Class::Location',
    'location_id',
    { join_type => 'left' },
);

__PACKAGE__->has_many(
    'schedules',
    'SpaceMan::DB::Result::Class::Session::Schedule',
    { 'foreign.session_id' => 'self.id' },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    'students',
    'SpaceMan::DB::Result::Class::Session::Student',
    { 'foreign.session_id' => 'self.id' },
    { cascade_copy => 0, cascade_delete => 0 },
);

#sub determine_maximum_students {
#    my $self = shift;
#    return $self->maximum_students || $self->class->maximum_students || 12;
#}

sub registered_students {
    my $self = shift;
    return $self->students->search( { waiting_list => \'!= false' } )->count;
}

sub slots_remaining {
    my $self = shift;

    return $self->maximum_students - $self->registered_students;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
