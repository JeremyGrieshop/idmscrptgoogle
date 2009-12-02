#!/usr/bin/perl -w
package authTokenManager;

use strict;
use HTTP::Date;
use IO::File;
use LWP::UserAgent;

sub new {
	my $class = shift;
	my $self = {};
	$self->{AUTH_FILE_PATH} = "token";
	$self-> {LOGIN} = undef;
	$self-> {PASS} = undef;
	bless($self, $class);
	return $self;
}

#gets/sets
sub authFilePath {
	my $self = shift;
	if (@_) { $self->{AUTH_FILE_PATH} = shift }
	return $self->{AUTH_FILE_PATH};
}

sub login {
	my $self = shift;
	if (@_) { $self->{LOGIN} = shift }
	return $self->{LOGIN};
}

sub password {
	my $self = shift;
	if (@_) { $self->{PASS} = shift }
	return $self->{PASS};
}

sub token{
	my $self = shift;
	my $token = $self->checkStamp();
	if ($token eq "fail"){
		$token = $self->refreshToken();
                if ($token == -1) {
                   return "notoken";
                }
		
		open FILE_OUT, "> ".$self->authFilePath;
		print FILE_OUT time."\n".$token;
		close FILE_OUT;
		return $token;
	} 
        if ($token == -1) {
           return "notoken";
        }
	return $token;
}

sub checkStamp{
	my $self = shift;
	
	my $input = IO::File->new($self->authFilePath) or return "fail";
	
	my $oldStamp = $input->getline();
	my $oldToken = $input->getline();
	
	my $newStamp = time;
	my $diffStamp = $newStamp - $oldStamp;
	
	$input->close();
	if ($diffStamp > 82800){
		return "fail";
	}else {return $oldToken;}
}

sub refreshToken{
	my $self = shift;
	
	# Create an LWP object to make the HTTP POST request
	my $lwp_object = LWP::UserAgent->new;

	# Define the URL to submit the request to
	my $url = 'https://www.google.com/accounts/ClientLogin';

	# Submit the request with values for the Email, Passwd, 
	# accountType and service variables.
	my $response = $lwp_object->post( $url,
		    [ 'accountType' => 'HOSTED',
		      'Email' => $self->login, 
		      'Passwd' => $self->password,
		      'service' => 'apps'
		    ]
	);

	print "$url error: ", $response->status_line unless $response->is_success;
        if (!$response->is_success) {
           return -1;
        }

	# Extract the authentication token from the response
	my $auth_token;
	foreach my $line (split/\n/, $response->content) {
	    if ($line =~ m/^Auth=(.+)$/) {
		$auth_token = $1;
		last;
	    }
	}

	return $auth_token;

}


1;
