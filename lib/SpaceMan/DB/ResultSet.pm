package SpaceMan::DB::ResultSet;
use strict; use warnings;
use Moose;
extends 'DBIx::Class::ResultSet';
use DBIx::Class::ResultClass::HashRefInflator;

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
