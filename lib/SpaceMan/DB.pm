use utf8;
package SpaceMan::DB;
use strict; use warnings;
use Moose;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    result_namespace        => 'Result',
    resultset_namespace     => 'ResultSet',
    default_resultset_class => 'ResultSet',
);
#__PACKAGE__->storage->sql_maker->quote_char( '"' );

sub connection {
    my $self = shift;
    my $rv = $self->next::method( @_ );
    $rv->storage->sql_maker->quote_char( '"' );
    $rv->storage->sql_maker->name_sep( '.' );
    return $rv;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
