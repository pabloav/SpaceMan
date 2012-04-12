#!/usr/bin/perl
use strict;
use NovaLabs::Web;
use NovaLabs;
use Digest::SHA;

my $SECRET = 'iejae6oowaht6iegeexawoofeichie5ij7bimoa6shah9Daidi';

my %p = params();

if ( $p{ 'token' } ) {
    my ( $hash, $uid, $expire ) = split( '!', $p{ 'token' } );
    log_error( "hash=$hash" );
    log_error( "uid=$uid expire=$expire" );
    my $ehash = hash( $uid, $expire );
    log_error( "ehash=$ehash" );
    if ( $hash ne $ehash ) {
        log_error( "invalid hash" );
        page( 'forgot-password/request.html' => {
            failure => 'Reset link is invalid, please try again.',
        } );
    }
    if ( time > $expire ) {
        page( 'forgot-password/request.html' => {
            failure => 'Reset link is expired, please try again.',
        } );
    }
    if ( $p{ 'password1' } || $p{ 'password2' } ) {
        if ( $p{ 'password1' } eq $p{ 'password2' } ) {
            my $user = NovaLabs->find_user( $uid );
            if ( $user ) {
                $user->set_password( $p{ 'password1' } );
                page( 'forgot-password/success.html' => {
                    message => 'Password changed!',
                } );
            } else {
                log_error( "No user" );
                page( 'forgot-password/request.html' => {
                    failure => 'Reset link is invalid, please try again.',
                } );
            }
        } else {
            page( 'forgot-password/reset.html' => {
                error => 'Passwords do not match, please try again.',
                token   => $p{ 'token' },
            } );
        }
    }
    page( 'forgot-password/reset.html' => { token => $p{ 'token' } } );
} elsif ( $p{ 'id' } ) {
    my %status = ();
    my $user = NovaLabs->find_user( $p{ 'id' } );
    log_error( "Password reset requested for $user" );
    if ( $user ) {
        local $@;
        my @vals = (
            $user->uid,
            time + ( 60 * 60 * 12 ), # 12 hour expiration
        );
        my $token =  join( '!', hash( @vals ), @vals );
        eval {
            $user->send_email( 'forgot-password/email.txt' => {
                token   => $token,
            } );
        };
        if ( $@ ) {
            page( 'forgot-password/request.html' => {
                failure => 'An error occurred.',
            } );
        } else {
            page( 'forgot-password/success.html' => {
                message => qq{
                    <p>Check your email for a link to reset your password.</p>
                },
            } );
        }
    } else {
        page( 'forgot-password/request.html' => {
            failure => "Couldn't find your user record",
        } );
    }
} else {
    page( 'forgot-password/request.html' => {} );
}

sub make_token {
    my $user = shift;
    my @values = (
        $user->uid,
        time + ( 60 * 60 * 12 ), # 12 hour expiration
    );
    return join( '!', hash( @values ), @values );
}

sub hash {
    my $self = shift;
    return Digest::SHA::sha256_hex( join( '', $SECRET, @_ ) );
}

