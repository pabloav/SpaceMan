package SpaceMan::DB::Result;
use strict; use warnings;
use Moose;
extends 'DBIx::Class::Core';
use Data::Dumper;
use HTML::Element;

__PACKAGE__->load_components( 'InflateColumn::DateTime' );

sub dump {
    print Dumper( @_ );
}
my %ipe_types = (
    'timestamp with time zone'      => 'datetime',
    'timestamp without time zone'   => 'datetime',
    'boolean'                       => 'boolean',
    'integer'                       => 'integer',
    'text'                          => 'textarea',
    'varchar'                       => 'text',
);

sub ipe {
    my ( $self, $col, $value ) = @_;

    my $info = ref $col ? $col : $self->column_info( $col );

    # %info = (
    #   accessor
    #   data_type
    #   size
    #   is_nullable
    #   is_auto_increment
    #   is_foreign_key
    #   default_value
    #   sequence
    #   extra
    # )

    my $el = HTML::Element->new( 'span', class => 'ipe' );

    unless ( defined $value ) {
        my $accessor = $info->{ 'accessor' } || $info->{ 'name' } || $col;
        $value = $self->$accessor();
    }
    if ( defined $value ) { $el->push_content( $value ) }
    my $size = $info->{ 'size' };
    if ( defined $size ) { $el->attr( size => $size ) }
    $el->attr( nullable => $info->{ 'is_nullable' } || 0 );

    my $type = $info->{ 'data_type' };
    $el->attr( rawtype => $type );

    if ( $info->{ 'is_foreign_key' } ) {
        $type = 'lookup';
    } elsif ( $ipe_types{ $type } ) {
        $type = $ipe_types{ $type };
    } else {
        $type = 'text';
    }
    $el->attr( type => $type );

    return $el->as_HTML;
}

sub infobox {
    my ( $self, %args ) = @_;

    my @out = ();

    push( @out => '<div class="infobox">' );

    if ( $args{ 'title' } ) { push( @out => "<h2>$args{ 'title' }</h2>" ) }

    push( @out => '<table>' );
    push( @out => '<tbody>' );

    my @fields = @{ delete( $args{ 'fields' } ) || [] };
    my $row = 1;
    for my $field ( @fields ) {
        if ( my $ref = ref $field ) {
            if ( $ref eq 'ARRAY' ) {
                my %field = ();
                @field{qw( name label )} = @{ $field };
                $field = \%field;
            }
        } else {
            $field = { name => $field };
        }

        my $name = $field->{ 'name' } || next;
        $field->{ 'label' } ||= $self->column_info( $name )->{ 'label' }
            || join( ' ', map { ucfirst( $_ ) } split( '_', $name ) );

        my $value = $self->render_value( %args, %{ $field } );

        my $row_class = $row++ % 2 ? 'odd' : 'even';
        push( @out => qq{<tr class="$row_class">} );
        push( @out => "<th>$field->{ 'label' }: </th>" );
        push( @out => "<td>".$self->ipe( $field => $value )."</td>" );
        push( @out => '</tr>' );
    }

    push( @out => '</tbody>' );
    push( @out => '</table>' );

    push( @out => '</div>' );

    return join( "\n", @out );
}

sub render_value {
    my ( $self, %opt ) = @_;

    my $value = '';
    my $name = $opt{ 'name' };

    %opt = (
        ( $self->has_column( $name ) ? %{ $self->column_info( $name ) } : () ),
        %opt,
    );

    if ( exists $opt{ 'value' } ) {
        $value = $opt{ 'value' };
        if ( my $ref = ref $value ) {
            if ( $ref eq 'CODE' ) {
                $value = $self->$value();
            }
        }
    } else {
        $value = $self->$name();
    }

    if ( blessed( $value ) ) {
        for my $x (qw( stringify name )) {
            if ( $value->can( $x ) ) {
                $value = $value->$x();
            }
        }
    }

    if ( $opt{ 'data_type' } eq 'boolean' ) {
        $value = $value ? 'TRUE' : 'FALSE';
    }

    if ( my $url = $opt{ 'url' } ) {
        while ( $url =~ /\{\{(\w+)\}\}/ ) {
            my $x = $1;
            my $y = $self->$x();
            $url =~ s/\{\{$x\}\}/$y/g;
        }
        $value = sprintf( '<a href="%s">%s</a>', $url, $value );
    }

    return $value;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
