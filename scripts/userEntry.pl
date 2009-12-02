#!/usr/bin/perl -w
package userEntry;

use strict;

#constructor
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $parent = ref($proto) && $proto;
	
	my $self = {};
		
	if ($parent){
		$self->{FIRST_NAME} = $parent->firstName;
		$self->{LAST_NAME} = $parent->lastName;
		$self->{USER_NAME} = $parent->userName;
		$self->{PASSWORD} = $parent->password;
		$self->{QUOTA} = $parent->quota;
		$self->{SUSPENDED} = $parent->suspended;
			
		bless($self, $class);
		return $self;
	}
	
	$self->{FIRST_NAME} = undef;
	$self->{LAST_NAME} = undef;
	$self->{USER_NAME} = undef;
	$self->{PASSWORD} = undef;
	$self->{QUOTA} = undef;
	$self->{SUSPENDED} = undef;
	
	bless($self, $class);
	return $self;
}

#gets and sets
sub firstName {
	my $self = shift;
	if (@_) { $self->{FIRST_NAME} = shift }
	return $self->{FIRST_NAME};
}

sub lastName {
	my $self = shift;
	if (@_) { $self->{LAST_NAME} = shift }
	return $self->{LAST_NAME};
}

sub userName {
	my $self = shift;
	if (@_) { $self->{USER_NAME} = shift }
	return $self->{USER_NAME};
}

sub password {
	my $self = shift;
	if (@_) { $self->{PASSWORD} = shift }
	return $self->{PASSWORD};
}

sub quota {
	my $self = shift;
	if (@_) { $self->{QUOTA} = shift }
	return $self->{QUOTA};
}

sub suspended {
	my $self = shift;
	if (@_) { $self->{SUSPENDED} = shift }
	return $self->{SUSPENDED};
}

#WORK FUNCTIONS
sub toXML{
	my $self = shift;
	my $suspendedStr = $self->suspended unless !defined($self->suspended);
	#if($self->suspended == 0 ){ $suspendedStr = "false";}
	#elsif($self->suspended == 1){$suspendedStr = "true";}
	#else {$suspendedStr = $self->suspended unless $self->suspended == -1;}
	
	my $str = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:apps="http://schemas.google.com/apps/2006">
    <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>';
	
	$str .= "\n	    <apps:login " unless !defined $suspendedStr && !defined $self->userName && !defined $self->password;
	$str .= 'userName="'.$self->userName.'" ' unless !defined $self->userName;
	$str .= 'password="'.$self->password.'" ' unless !defined $self->password;
	$str .= 'suspended="'.$suspendedStr.'" ' unless !defined $suspendedStr;
	$str .= '/>' unless !defined $suspendedStr && !defined $self->userName && !defined $self->password;
	
	$str .="\n    <apps:quota limit=\"".$self->quota.'"/>' unless !defined $self->quota;

	$str .="\n    <apps:name " unless !defined $self->firstName && !defined $self->lastName;
	$str .= 'familyName="'.$self->lastName.'" ' unless !defined $self->lastName;
	$str .= 'givenName="'.$self->firstName.'"' unless !defined $self->firstName;
	$str .= '/>' unless !defined $self->firstName && !defined $self->lastName;
	
	$str.="\n</atom:entry>";
	return $str;
}

sub fromXML{
	my $self = shift;
	my $str = undef;
	if (@_){$str = shift;}
	else {die "no arguments passed into fromXML.\n";}
	if(!($str)) { return; }
	if($str =~ /userName=.([a-zA-Z0-9]*)./){ 
		$self->userName($1);
	}
	if($str =~ /familyName=.([a-zA-Z0-9]*)./){ 
		$self->lastName($1);
	}
	if($str =~ /givenName=.([a-zA-Z0-9]*)./){ 
		$self->firstName($1);
	}
	if($str =~ /quota limit=.([a-zA-Z0-9]*)./){ 
		$self->quota($1);
	}
	if($str =~ /suspended=.([a-zA-Z0-9]*)./){ 
		$self->suspended($1);
	}	
}

sub empty{
	my $self = shift;
	$self->{USER_NAME} = undef;
	$self->{PASSWORD} = undef;
	$self->{FIRST_NAME} = undef;
	$self->{LAST_NAME} = undef;
   $self->{SUSPENDED} = undef;
	$self->{QUOTA} = undef;
}

sub pprint{
	my $self = shift;
	print "userName: ".$self->userName."\n" unless !defined $self->userName;
	print "password: ".$self->password."\n" unless !defined $self->password;
	print "firstName: ".$self->firstName."\n" unless !defined $self->firstName;
	print "lastName: ".$self->lastName."\n" unless !defined $self->lastName;
	print "suspended: ".$self->suspended."\n" unless !defined $self->suspended;
	print "quota: ".$self->quota."\n\n" unless !defined $self->quota;
}


1;
