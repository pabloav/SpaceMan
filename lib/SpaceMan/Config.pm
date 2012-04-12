package SpaceMan::Config;
use strict; use warnings;
use Path::Class qw( dir file );

my @config_paths = qw(
    /etc/spaceman.conf
    /etc/spaceman/spaceman.conf
    /etc/httpd/spaceman.conf
    /opt/spaceman/spaceman.conf
);

sub _CONFIG {
    my ( $name, $value ) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{ $name } = sub { $value };
}

sub _LOAD_CONFIG_FILE {
    my $path = shift;

    open( my $fh, $path ) or die "Can't read $path: $!";
    while ( local $_ = <$fh> ) {
        chomp;
        my ( $l, $r ) = split( ' ', $_, 2 );
        _CONFIG( $l => $r );
    }
}

_CONFIG( auth_secret        => '---XXX--- '.rand().rand().rand() );
_CONFIG( mason_error_mode   => 'fatal' );   # output or fatal
_CONFIG( spaceman_dir       => '/opt/spaceman' );
_CONFIG( cache_dir          => '/var/cache/spaceman' );
_CONFIG( domain             => 'local' );
_CONFIG( lib_dir            => '/opt/spaceman/lib' );
_CONFIG( db_dsn             => 'DBI:Pg:dbname=spaceman' );
_CONFIG( db_username        => undef );
_CONFIG( db_password        => undef );
_CONFIG( ldap_base          => 'dc=local' );
_CONFIG( ldap_sync_dn       => 'cn=Manager,dc=local' );
_CONFIG( ldap_sync_password => undef );

for my $path ( @config_paths ) {
    if ( -f $path ) {
        _LOAD_CONFIG_FILE( $path );
        last;
    }
}

1;
