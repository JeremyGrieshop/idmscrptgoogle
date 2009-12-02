#!/usr/bin/perl -w
package connectionManager;


use strict;
use LWP::UserAgent;
use HTTP::Request;

use lib "/opt/novell/usdrv/scripts"; #driver use only

eval ( 'require "userEntry.pl";' );
if($@){ 
   print "> Error Including userEntry: $@\n"; 
}
eval ( 'require "userFeed.pl";' );
if($@){ 
   print "> Error Including userFeed: $@\n";
}
eval ( 'require "authTokenManager.pl";' );
if($@){ 
   print "> Error Including authTokenManager: $@\n";
}
#print "> conman passed require\n";

#constructor
sub new {
	my $class = shift;
	my $self = {};
	$self->{AUTH_TOKEN} = undef;
	$self->{URL} = undef;
	$self->{XML} = undef;
	$self->{RETURNED} = undef;
	$self->{RETURNED_ERROR} = undef;
	$self->{RETURNED_ERRORMSG} = undef;
	$self->{CONNECTION_TYPE} = undef;
	$self->{DOMAIN} = shift;
	$self->{API_USER} = shift;
	$self->{API_PASSWD} = shift;
	
	bless($self, $class);
	return $self;
}

#GETS AND SETS

sub token {
	my $self = shift;
	if (@_) { $self->{AUTH_TOKEN} = shift }
	return $self->{AUTH_TOKEN};
}

sub url {
	my $self = shift;
	if (@_) { $self->{URL} = shift }
	return $self->{URL};
}

sub xml {
	my $self = shift;
	if (@_) { $self->{XML} = shift }
	return $self->{XML};
}

sub connType {
	my $self = shift;
	if (@_) { $self->{CONNECTION_TYPE} = shift }
	return $self->{CONNECTION_TYPE};
}

sub returned {
	my $self = shift;
	if (@_) { $self->{RETURNED} = shift }
	return $self->{RETURNED};
}

sub returnedError {
	my $self = shift;
	if (@_) { $self->{RETURNED_ERROR} = shift }
	return $self->{RETURNED_ERROR};
}

sub returnedErrorMsg {
	my $self = shift;
	if (@_) { $self->{RETURNED_ERRORMSG} = shift }
	return $self->{RETURNED_ERRORMSG};
}

#this one is read only
sub domain{
	my $self = shift;
	return $self->{DOMAIN};
}

#WORK FUNCTIONS

#uses credentials to obtain an authentication token
#from google, stores in token
sub getAuthToken{
	my $self = shift;

	my $authMan = authTokenManager->new();

        #print "[".$self->{API_USER}."-".$self->{DOMAIN}."-".$self->{API_PASSWD}."]\n";
	
	$authMan->authFilePath("token");
	$authMan->login($self->{API_USER}.'@'.$self->{DOMAIN});
	$authMan->password($self->{API_PASSWD});

        if ($authMan->token() eq "notoken") {
           return 0;
        } else {
	   $self->{AUTH_TOKEN} = $authMan->token();
           return 1;
        }
}

sub send{
	my $self = shift;
	
        if (!defined($self->connType)) {
	   $self->returnedError("100");
           $self->returnedErrorMsg("no connection type specified");
           return;
        }

        if (!defined($self->url)) {
	   $self->returnedError("101");
           $self->returnedErrorMsg("no url specified");
           return;
        }

        if (!defined($self->token)) {
	   $self->returnedError("102");
           $self->returnedErrorMsg("no auth token specified");
           return;
        }
	
	if($self->connType eq "POST"){
		my $userAgent = LWP::UserAgent->new(agent => 'perl post');


		my $response = $userAgent->post( $self->url,
		'Content_Type', 'application/atom+xml',
		'Authorization', 'GoogleLogin auth='.$self->token,
		'Content', $self->xml);

                if (!$response->is_success) {
		   $self->returnedError($response->status_line);
                   $self->returnedErrorMsg($response->message);
                   return;
                }

		$self->returned($response->content);
		
	}elsif($self->connType eq "GET"){
		my $userAgent = LWP::UserAgent->new(agent => 'perl get');


		my $response = $userAgent->get($self->url,
		'Content_Type', 'application/atom+xml',
		'Authorization', 'GoogleLogin auth='.$self->token);

                if (!$response->is_success) {
		   $self->returnedError($response->status_line);
		   $self->returnedErrorMsg($response->message);
                   return;
                }

		$self->returned($response->content);
		
	}elsif($self->connType eq "PUT"){	
	   my $userAgent = LWP::UserAgent->new(agent => 'perl put');

		my $hdr = HTTP::Headers->new(Content_Type => 'application/atom+xml',
		Authorization => 'GoogleLogin auth='.$self->token);
		
		my $req = HTTP::Request->new("PUT",$self->url,$hdr);
		$req->content($self->xml);

		my $response = $userAgent->request($req);

                if (!$response->is_success) {
		   $self->returnedError($response->status_line);
		   $self->returnedErrorMsg($response->message);
                   return;
                }

		$self->returned($response->content);
		
	}elsif($self->connType eq "DELETE"){
		my $userAgent = LWP::UserAgent->new(agent => 'perl delete');

		my $hdr = HTTP::Headers->new(Content_Type => 'application/atom+xml',
		Authorization => 'GoogleLogin auth='.$self->token);

		my $req = HTTP::Request->new("DELETE",$self->url,$hdr);

		my $response = $userAgent->request($req);
		
                if (!$response->is_success) {
		   $self->returnedError($response->status_line);
		   $self->returnedErrorMsg($response->message);
                   return;
                }

		$self->returned($response->content);

	}else{
		$self->returnedError(103);
		$self->returnedErrorMsg("Unknown connection type ".$self->connType);
	}
}


1;
