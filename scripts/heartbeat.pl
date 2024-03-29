#!/usr/bin/perl
#

use strict;

# include the IDM Library
use IDMLib;
my $idmlib = new IDMLib();

# set the SCRIPT_DIR path
my $SCRIPT_DIR = $ENV{'INSTALL_PATH'}."/scripts/";

# call out to globals script
require $ENV{'INSTALL_PATH'}."/scripts/globals.sh";


# The purpose of the heartbeat script is to check the health of the
# application and report it back in the form of a status document.
# In this environment, we'll just report back a success status.
$idmlib->heartbeat_success();

# log a message to the system log
$idmlib->logger("heartbeat.pl", " **** heartbeat.pl *** ");

