package SpaceMan::DB::Result;
use strict; use warnings;
use Moose;
extends 'DBIx::Class::Core';
use Data::Dumper;

__PACKAGE__->load_components( 'InflateColumn::DateTime' );

sub dump {
    print Dumper( @_ );
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
