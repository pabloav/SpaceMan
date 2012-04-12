package SpaceMan;
use strict; use warnings;
use Moose;
use SpaceMan::DB;
use SpaceMan::Config;
#use SpaceMan::Util qw();
use HTML::Mason::Interp;
use namespace::autoclean;

has '_database'  => (
    is          => 'ro',
    isa         => 'SpaceMan::DB',
    lazy_build  => 1,
);
sub _build__database {
    my $self = shift;
    return SpaceMan::DB->connect(
        $self->config->db_dsn,
        $self->config->db_username,
        $self->config->db_password,
        {
            AutoCommit  => 1,
            quote_char  => '"',
            name_sep    => '.',
        }
    )
}

sub person {
    my ( $self, $id ) = @_;

    if ( $id =~ /@/ ) {
        return $self->find_person_by_email( $id );
    } elsif ( $id =~ /^\d+$/ ) {
        return $self->rs( 'Person' )->find( { id => $id } );
    } else {
        return $self->rs( 'Person' )->find( { username => $id } )
    }
#    return $rs->find( [
#        { username => $id },
#        { 'emails.email_address' => $id },
#    ], { join => [qw( emails )] } );
}

sub find_person_by_email {
    return shift->resultset( 'Person' )->find(
        { 'emails.email_address' => { -in => \@_ } },
        { join => [qw( emails )] },
    );
}

#sub create_person_by_email {
#    my ( $self, @email ) = @_;
#    my $person = $self->resultset( 'Person' )->new( {} );
#    $person->add_to_emails( { email_address => $_ } ) for @email;
#    $person->update;
#    return $person;
#}
#
#sub find_or_create_person_by_email {
#    my $self = shift;
#
#    return $self->find_person_by_email( @_ )
#        || $self->create_person_by_email( @_ );
#}

sub is_username_available {
    my ( $res, @errors ) = shift->_is_username_available( @_ );
    return wantarray ? ( $res, @errors ) : $res;
}

sub _is_username_available {
    my ( $self, $username ) = @_;

    return ( 0 => 'empty' ) unless $username;

    if ( $username =~ /^[^a-z0-9-]+$/ ) {
        return ( 0 => 'invalid characters' );
    }

    unless ( $username =~ /[a-z]/i ) {
        return ( 0 => 'must contain at least one letter' );
    }

    $username = lc( $username );

    my @files = qw(
        /etc/passwd
        /etc/group
        /etc/aliases
    );

    for my $file ( @files ) {
        open( my $fh, $file ) or die "Can't open $file for reading: $!";
        while ( local $_ = <$fh> ) {
            chomp;
            s/#.*$//;
            s/:.*$//;
            s/^\s*|\s*$//g;
            next unless $_;
            if ( $username eq $_ ) { return ( 0 => 'already in use' ) }
        }
    }

    {
        my $rs = $self->resultset( 'Person' )->search( {
            username => $username
        } );
        if ( $rs > 0 ) { return ( 0 => 'already in use' ) }
    }

    {
        my $rs = $self->resultset( 'Group' )->search( {
            name => $username
        } );
        if ( $rs > 0 ) { return ( 0 => 'already in use' ) }
    }

    return ( 1 => $username );
}


sub fill_template {
    my $self = shift->instance;
    my $template = shift;
    my %vars = ( @_ == 1 ) ? %{ shift() } : @_;

    my $interp = HTML::Mason::Interp->new( comp_root => [
        [ main => '/etc/spaceman/templates' ],
        [ spaceman => '/opt/spaceman/templates' ],
    ] );

    my $content;
    $interp->out_method( \$content );
    $interp->exec( "/$template" => %vars );
    return $content;
}

sub database { return shift->instance->_database }

sub resultset {
    my $self = shift->instance;
    return $self->_database->resultset( @_ );
}
sub rs { return shift->resultset( @_ ) }

sub mailing_lists { return shift->instance->rs( 'MailingList' ) }

sub mailing_list {
    my ( $self, $name ) = @_;
    return $self->mailing_lists->search( { name => $name } )->single;
}

{
    my $instance;
    sub instance {
        my $self = shift;
        return $self if blessed $self;
        return $instance ||= $self->new;
    }
}

sub config {
    my $self = shift;
    if ( @_ ) {
        my $method = shift;
        return SpaceMan::Config->$method();
    } else {
        return 'SpaceMan::Config';
    }
}

__PACKAGE__->meta->make_immutable;
1;
