use utf8;
package SpaceMan::DB::Result::MailingList;
use strict; use warnings;
use Moose;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table("mailing_lists");

__PACKAGE__->add_columns(
    id                  => {
        data_type           => "integer",
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => "mailing_list_id_seq",
    },
    name                => {
        data_type           => "varchar",
        is_nullable         => 0,
        size                => 32,
    },
    can_self_subscribe  => {
        data_type           => "boolean",
        default_value       => \"true",
        is_nullable         => 0,
    },
    summary             => {
        data_type           => "varchar",
        size                => 128,
        is_nullable         => 1,
    },
    description         => {
        data_type           => "text",
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key( "id" );

__PACKAGE__->add_unique_constraint( [ 'name' ] );

sub subscribe_emails {
    my $self = shift;

    open( my $act, '|-',
        '/usr/lib/mailman/bin/add_members',
        '--regular-members-file=-',
        '--welcome-msg=no', '--admin-notify=no',
        $self->name
    );
    print $act "$_\n" for @_;
}

sub unsubscribe_emails {
    my $self = shift;

    open( my $act, '|-',
        '/usr/lib/mailman/bin/remove_members',
        '--file=-', '--nouserack', '--noadminack',
        $self->name
    );
    print $act "$_\n" for @_;
}


__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
