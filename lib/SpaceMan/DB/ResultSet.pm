package SpaceMan::DB::ResultSet;
use strict; use warnings;
use Moose;
extends 'DBIx::Class::ResultSet';
use DBIx::Class::ResultClass::HashRefInflator;

sub datatable {
    my ( $self, %args ) = @_;

    my @cols = @{ delete $args{ 'columns' } || [] };
    for my $i ( 0 .. $#cols ) {
        my $col = $cols[ $i ];
        unless ( ref $col ) { $col = $cols[ $i ] = { name => $col } }
        $col->{ 'label' } ||= join( ' ', map { ucfirst( $_ ) } split( '_', $col->{ 'name' } ) );
    }

    my @out = ();

    push( @out => '<table class="datatable">' );
    push( @out => '<thead>' );

    push( @out => '<tr>' );
    for my $col ( @cols ) {
        push( @out => "<th>$col->{ 'label' }</th>" );
    }
    push( @out => '</tr>' );

    push( @out => '</thead>' );
    push( @out => '<tbody>' );

    for my $row ( $self->all ) {
        push( @out => '<tr>' );

        for my $col ( @cols ) {
            my $value = $row->render_value( %args, %{ $col } );
            push( @out => "<td>$value</td>" );
        }

        push( @out => '</tr>' );
    }

    push( @out => '</tbody>' );
    push( @out => '</table>' );

    return join( "\n", @out );
}

sub advanced_search {
    my ( $self, $params, $attrs ) = @_;
    my $columns = {};
    for my $column ( keys %{ $params } ) {
        if ( my $search = $self->can( "search_for_$column" ) ) {
            $self = $self->search( $params );
            next;
        }
        my ( $full_name, $relation ) = $self->parse_column( $column );
        $self = $self->search( {}, { join => $relation } );
        $columns->{ $full_name } = $params->{ $column };
    }
    return $self->search( $columns, $attrs );
}

sub parse_column {
    my ( $self, $field ) = @_;

    if ( $field =~ /^(.*?)\.(.*)$/ ) {
        my ( $first, $rest ) = ( $1, $2 );
        my ( $column, $join ) = $self->parse_column( $rest );
        if ( $join ) {
            return ( $column, { $first => $join } );
        } else {
            return ( $first.'.'.$column, $first );
        }
    } elsif ( $field ) {
        return $field;
    } else {
        return;
    }
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
