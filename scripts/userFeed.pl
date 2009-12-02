#!/usr/bin/perl -w
package userFeed;

use lib "/opt/novell/usdrv/scripts";

require "userEntry.pl";
use strict;

#constructor
sub new {
	my $class = shift;
	my @ary = ();
	my $self = \@ary;
	bless($self, $class);
	return $self;
}

#work functions

#returns 'ok' or the next feed url
sub fromXML{
	my $self = shift;
	#die "No XML feed defined.\n" unless @_;
	
	my $str = shift;
	
	my @parray = split(/<\/?entry>/, $str);
	
	my $tmpstring = undef;
	my $entry = userEntry->new;
	foreach $tmpstring(@parray){
		$entry->fromXML($tmpstring);
		$self->pushEntry($entry);
		$entry->empty;
	}
	
	if ($str=~/<link\srel='next'\stype='application\/atom\+xml'\shref='(.*)'/){
		return $1;
	}else{
		return 'ok';
	}
}

sub pushEntry{
	my $self = shift;
	if (@_){ 
		push @$self, shift->new;
	}else{
		#die "no entry specified.\n";
	}
	
	
}

sub pprint{
	my $self = shift;
	my $entry;
	foreach $entry (@$self){
		$entry->pprint;
	}
}


1;
