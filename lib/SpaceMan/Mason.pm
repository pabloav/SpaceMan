package SpaceMan::Mason;
use strict;
use HTML::Mason::ApacheHandler;
use Apache2::Request;
use Apache2::Const qw( DECLINED );
use SpaceMan::Config;
  
my $cache = SpaceMan::Config->cache_dir;
my $ah = HTML::Mason::ApacheHandler->new(
    error_mode              => SpaceMan::Config->mason_error_mode,
    comp_root               => [
        [ main      => '/var/www/html' ],
        [ spaceman  => SpaceMan::Config->spaceman_dir.'/html' ],
    ],
    data_dir                => "$cache/mason",
    request_class           => 'MasonX::Request::WithApacheSession',
    session_cookie_domain   => '.'.SpaceMan::Config->domain,
    session_class           => 'Apache::Session::File',
    session_directory       => "$cache/mason/session-data",
    session_lock_directory  => "$cache/mason/session-locks",
    args_method             => 'mod_perl',
    decline_dirs            => 0,
);
  
sub handler {
    my $r = shift;  # Apache request object;

    return DECLINED if $r->uri =~ m#/~#;

    my $section = '';
    if ( $r->uri =~ m#^/(\w+)# ) { $section = $1 }

    return DECLINED if $section eq 'blog';
    return DECLINED if $section eq 'wiki';
  
    return $ah->handle_request($r);
}

use SpaceMan;

package HTML::Mason::Commands;
use HTML::FromText qw( text2html );
use Apache2::Request ();
use Data::Dumper qw( Dumper );
use SpaceMan;
use vars qw( $SpaceMan $User @_messages );

$SpaceMan = SpaceMan->new;

# To access the request object from inside a component, use
# my $m = HTML::Mason::Request->instance;

sub message {
    my $type = shift;
    push( @_messages => {
        type    => $type,
        content => join( ' ', @_ ),
    } );
    return;
}

sub error { message( error => @_ ) }
sub success { message( success => @_ ) }
sub warning { message( warning => @_ ) }
sub info { message( info => @_ ) }

1;
