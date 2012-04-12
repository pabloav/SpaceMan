use utf8;
package SpaceMan::DB::Result::Person;
use strict; use warnings;
use Moose;
use Set::Object;
use Digest::SHA1;
use MIME::Base64;
extends 'SpaceMan::DB::Result';

__PACKAGE__->table( 'people' );

__PACKAGE__->add_columns(
    id              => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        is_nullable         => 0,
        sequence            => 'people_id_seq',
    },
    member_type     => {
        data_type           => 'varchar',
        size                => 16,
        is_nullable         => 0,
        default_value       => 'UNKNOWN',
    },
    name            => {
        data_type           => 'varchar',
        is_nullable         => 1,
        size                => 64,
    },
    username        => {
        data_type           => 'varchar',
        is_nullable         => 1,
        size                => 32,
    },
    password        => {
        data_type           => 'varchar',
        is_nullable         => 1,
        size                => 128,
    },
    posix_uid       => {
        data_type           => 'integer',
        is_nullable         => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->add_unique_constraint( [ 'username' ] );
__PACKAGE__->add_unique_constraint( [ 'posix_uid' ] );

__PACKAGE__->has_many(
    "calendar_events",
    "SpaceMan::DB::Result::Calendar::Event",
    { "foreign.owner_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "emails",
    "SpaceMan::DB::Result::Person::Email",
    { "foreign.person_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "person_roles",
    "SpaceMan::DB::Result::Person::Role",
    { "foreign.person_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many( "roles", "person_roles", "role" );

__PACKAGE__->has_many(
    'person_groups',
    'SpaceMan::DB::Result::Person::Group',
    { 'foreign.person_id' => 'self.id' },
    { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many( 'groups', 'person_groups', 'group' );

sub all_roles {
    my $self = shift;

    my $set = Set::Object->new( $self->roles );
    for my $group ( $self->groups ) {
        $set->insert( $group->roles );
    }
    return wantarray ? $set->members : $set;
}

sub verify_password {
    my ( $self, $input ) = @_;

    my $password = $self->password;
    if ( $password =~ /^{SSHA}(.*)$/ ) { # Salted SHA
        my $salt = substr( decode_base64( $1 ), 20 );
        my $ctx = Digest::SHA1->new;
        $ctx->add( $input );
        $ctx->add( $salt );
        my $found = '{SSHA}'.encode_base64( $ctx->digest.$salt, '' );
        return $found eq $password;
    }
    return 0; # unknown format
}

sub get_password {
    my ( $self, $encoding ) = @_;
    my @pass = split( ' ', $self->password );
    return @pass unless $encoding;
    for my $pass ( @pass ) {
        if ( $pass =~ /^\{$encoding\}/i ) {
            return $pass;
        }
    }
    return;
}

sub set_password {
    my ( $self, $pass ) = @_;

    my $salt = $self->_get_salt( 4 );
    my $ctx = Digest::SHA1->new;
    $ctx->add( $pass );
    $ctx->add( $salt );
    my $ssha = '{SSHA}'.encode_base64( $ctx->digest . $salt, '' );
    $self->password( $ssha );
#    try {
#        $self->txn_do( sub {
#            $self->password( $ssha );
#            $self->update;
#        } );
#        return 1;
#    } catch {
#        my $error = shift;
#        warn "set_password: $error";
#        return 0;
#    };
}

sub _get_salt {
    my ( $self, $length ) = @_;
    $length ||= 4;
    my $salt = '';
    my @chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    while ( length( $salt ) < $length ) {
        $salt .= $chars[ rand( @chars ) ];
    }
    return $salt;
}

sub auth_cookie_expiration { return 60 * 60 * 4 }

sub email {
    my $self = shift;
    my $rs = $self->emails->search( { primary_address => 1 } );
    if ( $rs ) {
        return $rs->first->email_address;
    } else {
        return $self->emails->first->email_address;
    }
}

sub apache_subprocess_env {
    my $self = shift;

    return (
        username    => $self->username,
        email       => $self->email,
        name        => $self->name,
        #groups      => join( ',', $self->group_names ),
    );
}

sub send_email {
    my ( $self, $template, $vars ) = @_;

    # TODO - convert this to use MIME::Lite instead..
    open( my $fh, "| sendmail -t -oi -oem" )
        or die "Can't open pipe to sendmail: $!";
    my $name = $self->name;
    my $email = $self->email;
    print $fh "To: $name <$email>\n";
    print $fh SpaceMan->fill_template( $template => $vars );
    close( $fh ) or die "Can't send mail: $!";
}

sub mailing_lists {
    my $self = shift;

    my %lists = ();
    my @emails = map { $_->email_address } $self->emails;
    open( my $fh, '-|', '/usr/lib/mailman/bin/find_member', '-w', @emails )
        or die "Can't run find_member";
    my $curemail = '';
    while ( local $_ = <$fh> ) {
        chomp;
        if ( /^(\S+) found in:/ ) {
            $curemail = $1;
        }
        if ( /^\s+(\S+)/ ) {
            push( @{ $lists{ lc( $1 ) } ||= [] } => $curemail );
        }
    }
    return wantarray ? keys %lists : \%lists;
}

sub join_mailing_list {
    my ( $self, $list, @emails ) = @_;

    my $ml = SpaceMan->instance->mailing_list( $list )
        or die "Invalid mailing list '$list'";
    if ( @emails ) {
        $ml->subscribe_emails( @emails );
    } else {
        $ml->subscribe_emails( $self->email );
    }
}

sub leave_mailing_list {
    my ( $self, $list, @emails ) = @_;

    my $ml = SpaceMan->instance->mailing_list( $list )
        or die "Invalid mailing list '$list'";
    if ( @emails ) {
        $ml->unsubscribe_emails( @emails );
    } else {
        $ml->unsubscribe_emails( map { $_->email_address } $self->emails );
    }
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
