package SpaceMan::AuthHandler;
use strict;
use Carp;
use CGI '3.12';
use mod_perl2 '1.99022';
use Apache2::Const qw(:common HTTP_FORBIDDEN);
use Apache2::RequestRec;
use Apache2::RequestIO;
use Digest::SHA ();
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Log;
use Apache2::Access;
use Apache2::Response;
use Apache2::Util;
use APR::Table;
use SpaceMan;
use Apache2::Const qw( :common M_GET HTTP_FORBIDDEN HTTP_MOVED_TEMPORARILY );


my $SECRET = SpaceMan->config( 'auth_secret' );
my $COOKIE = 'AuthCookie';
my $P3P = '';
my $PATH = '/';
my $DOMAIN = '.'.SpaceMan->config( 'domain' );

sub allow_anonymous {
    my $uri = shift;

    # TODO - make these configuration options instead of hardcoded regexes
    return 1 if $uri =~ m#^/(auth|css|js|icons|images|novabar|img|blog)($|/)#;
    return 1 if $uri =~ m#^/(calendar|mailman|wiki|about|contact)($|/)#;
    return 1 if $uri =~ m#^/(about)\.html$#;
    return 1 if $uri =~ m#^/~#;
    return 1 if $uri =~ m#^/favicon\.ico$#;
    return 1 if $uri =~ m#^/$#;
    return 0;
}

sub get_cookie {
    my ( $self, $r ) = @_;
    my $allcook = ($r->headers_in->get("Cookie") || "");
	
    return ($allcook =~ /(?:^|\s)$COOKIE=([^;]*)/)[0];
}

sub get_user {
    my ( $self, $r ) = @_;

    my $cookie = $self->get_cookie( $r ) or return;

    my ( $hash, $username, $expires ) = split( '!', $cookie );

    return unless $hash eq $self->hash( $username, $expires );
    return if $expires < time;
    return SpaceMan->person( $username );
}

sub recognize_user {
    my ( $self, $r ) = @_;

    # Skip if user is already defined
    return DECLINED if $r->user;

    return $self->get_user( $r ) || DECLINED;
}

sub hash {
    my $self = shift;
    return Digest::SHA::sha256_hex( join( '', $SECRET, @_ ) );
}

sub authenticate {
    my ( $self, $r ) = @_;

    unless ( $r->is_initial_req ) { # we are in a subrequest
        if ( defined $r->prev ) {
            $r->user( $r->prev->user ); # just copy from prev
        }
        return OK;
    }

    if ( $self->get_cookie( $r ) ) {
        if ( my $user = $self->get_user( $r ) ) {
            $r->ap_auth_type( $self );
            $r->user( $user->username );
            my %env = $user->apache_subprocess_env;
            for my $i ( keys %env ) {
                $r->subprocess_env( "SpaceMan_User_\U$i" => $env{ $i } );
            }
            return OK;
        } else {
            return OK if allow_anonymous( $r->uri );
            $self->remove_cookie( $r );
            $r->subprocess_env( 'AuthReason' => 'bad_cookie' );
        }
    } else {
        return OK if allow_anonymous( $r->uri );
        $r->subprocess_env( 'AuthReason' => 'no_cookie' );
    }
    if ( $r->uri =~ m#^/files/# ) { return DECLINED }
    return $self->login_form( $r );
}

sub login_form {
    my ( $self, $r ) = @_;

    my $auth_name = $r->auth_name;
    my $ip = $r->connection->remote_ip;
    my $path = '/auth/login.html';
    # if ( $ip eq '71.246.219.53' ) { $path = '/auth/login.html' }
    $r->custom_response( HTTP_FORBIDDEN, $path );
    return HTTP_FORBIDDEN;
}

sub authorize {
    my ( $self, $r ) = @_;

    return OK unless $r->is_initial_req; # don't need to authorize sub-reqs
    return OK if allow_anonymous( $r->uri );

    return DECLINED unless $self eq $r->auth_type;

    my @reqs = @{ $r->requires || [] };
    return DECLINED unless @reqs;

    my $user = $self->get_user( $r ) || return HTTP_FORBIDDEN;

    for ( @reqs ) {
        my ( $req, @args ) = split( ' ', $_->{ 'requirement' } );
        $r->log_error( "req: $req (@args)" );
        if ( $req eq 'group' ) {
            if ( $user->is_member_of( @args ) ) { return OK }
        }
        if ( $req eq 'open' ) { return OK }
        if ( $req eq 'member' ) { return OK }
    }
    return HTTP_FORBIDDEN;
}

sub remove_cookie {
    my ( $self, $r ) = @_;

    my $cookie = sprintf(
        '%s=; expires=Mon, 21-May-1971 00:00:00 GMT; path=%s; domain=%s',
        $COOKIE, $PATH, $DOMAIN,
    );
    $r->err_headers_out->add( 'Set-Cookie' => $cookie );
    $r->headers_out->add( 'Set-Cookie' => $cookie );
}

sub login {
    my ( $self, $r ) = @_;

    my $args = CGI->new( $r )->Vars();

    my $dest = $args->{ 'dest' } || '/';
    $dest =~ s/([\r\n\t])/sprintf("%%%02X", ord $1)/ge;

    my $username = $args->{ 'username' };
    my $password = $args->{ 'password' };

    if ( my $user = SpaceMan->person( $username ) ) {
        if ( $user->verify_password( $password ) ) {
            $self->send_cookie( $r, $user );
            $self->handle_cache( $r );
            $r->headers_out->set( Location => $dest );
            return HTTP_MOVED_TEMPORARILY;
        }
    }
    $r->subprocess_env( 'AuthReason' => 'bad_credentials' );
    $r->uri( $dest );
    return $self->login_form( $r );
}

sub send_cookie {
    my ( $self, $r, $user ) = @_;
    my @token = (
        scalar $user->username,
        scalar time() + $user->auth_cookie_expiration,
    );
    my $ticket = join( '!', $self->hash( @token ), @token );
    my $cookie = sprintf(
        '%s=%s; path=%s; domain=%s',
        $COOKIE, $ticket, $PATH, $DOMAIN,
    );
    $self->handle_cache( $r );
    if ( $P3P ) { $r->err_headers_out->set( P3P => $P3P ) }
    $r->err_headers_out->add( 'Set-Cookie' => $cookie );
}

sub logout {
    my ( $self, $r ) = @_;
    $self->remove_cookie( $r );
    $self->handle_cache( $r );
    $r->headers_out->set( Location => '/' );
    return HTTP_MOVED_TEMPORARILY;
}

sub handle_cache {
    my ($self, $r) = @_;

    $r->no_cache( 1 );
    $r->err_headers_out->set( Pragma => 'no-cache' );
}

1;
__END__
# WordPress cookies
wp-settings-time-2 1332532549
wordpress_logged_in_83724aee39a9bd57034bdd21fd94e076 jason%7C1332705348%7Cab70be5f49674f945a2c56eea4840b54
wordpress_test_cookie WP+Cookie+check
wp-settings-time-1 1322846364
wordpress_sec_83724aee39a9bd57034bdd21fd94e076 jason%7C1332705348%7C9d7faae8d6d29336e4a2f81d42c8d0a6 www.nova-labs.org /blog/wp-admin
