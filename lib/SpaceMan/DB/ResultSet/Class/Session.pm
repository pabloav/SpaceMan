package SpaceMan::DB::ResultSet::Class::Session;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::ResultSet';

sub in_future {
    my $self = shift;

    return $self->search(
        { start_date => { '>=' => \'CURRENT_DATE' } },
        { order_by => [ 'start_date' ] },
    );
}

#sub in_month {
#    my ( $self, $date ) = @_;
#
#    my $sessions = $self->related_resultset( 'sessions' );
#    my $schedules = $sessions->related_resulset( 'schedules' );
#    return $self->search(
#    return $self->related_resultset( 'sessions' )
#        ->related_resultset( 'schedules' )
#        ->search(
#    return $self->search( \[
#        "date_trunc( 'month', sessions.schedules.date ) = date_trunc( 'month', ? )", [ date => $date ],
#
#    ], {
#        '+select'   => { 'sessions.schedules.date', -as => 'schedule_date' },
#        join        => { 'sessions' => 'schedules' },
#        prefetch    => 'sessions',
#    } );
#}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
