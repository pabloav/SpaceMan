use utf8;
package SpaceMan::DB::Result::Class::Session::Schedule;
use strict; use warnings;
use Moose;
use DateTime::Format::Strptime;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'class_session_schedules' );

__PACKAGE__->add_columns(
    id              => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
    },
    session_id      => {
        data_type           => 'integer',
        is_nullable         => 0,
        is_foreign_key      => 1,
    },
    date            => {
        data_type           => 'date',
        is_nullable         => 0,
    },
    start_time      => {
        data_type           => 'time without time zone',
        is_nullable         => 0,
    },
    end_time        => {
        data_type           => 'time without time zone',
        is_nullable         => 0,
    },
    location_id     => {
        data_type           => 'integer',
        is_nullable         => 1,
        is_foreign_key      => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to(
    'session',
    'SpaceMan::DB::Result::Class::Session',
    'session_id'
);

__PACKAGE__->belongs_to(
    'location',
    'SpaceMan::DB::Result::Class::Location',
    'location_id',
    { join_type => 'left' },
);

sub formatted_date {
    my $self = shift;
    my $df = DateTime::Format::Strptime->new( pattern => '%A, %B %e %Y' );

    my $date = $self->date;
    $date->set_formatter( $df );
}

sub formatted_datetime {
    my $self = shift;
    return sprintf( '%s %s-%s',
        $self->formatted_date,
        $self->formatted_start_time,
        $self->formatted_end_time,
    );
}
sub formatted_start_time {
    return _format_time( shift->start_time );
}
sub formatted_end_time {
    return _format_time( shift->end_time );
}

sub _format_time {
    my $time = shift || return;
    my ( $hour, $minute ) = split( ':', $time );
    my $ampm = 'AM';
    if ( $hour > 12 ) {
        $hour -= 12;
        $ampm = 'PM';
    }
    return sprintf( '%d:%02d %s', $hour, $minute, $ampm );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
