package SpaceMan::Util;
use strict; use warnings;
use Moose;
use JSON::XS qw( encode_json decode_json );
use MIME::Base64 qw( encode_base64 decode_base64 );
use Digest::SHA qw( sha256_hex );
use Sub::Exporter -setup => {
    exports => [qw(
        generate_action_token validate_action_token
        encode_json decode_json
        encode_base64 decode_base64
        sha256_hex
    )],
};
#use namespace::autoclean;

sub generate_action_token {
    my ( $expires, @args ) = @_;
    my @values = ( time + ( $expires * 60 ), @args );
    my $token = join( '!', _hash( @values ), @values );
    return $token;
}

sub validate_action_token {
    my $token = shift;
    my ( $hash, $expires, @args ) = split( '!', $token );
    my $ehash = _hash( $expires, @args );
    return ( 'invalid token' ) unless $ehash eq $hash;
    return ( 'expired token' ) unless time < $expires;
    return ( '', @args );
}

sub _hash {
    my $secret = SpaceMan::Config->action_token_secret;
    return sha256_hex( join( '', $secret, @_ ) );
}

__PACKAGE__->meta->make_immutable;
1;
