package ChatObjects::ChatCodes;
# Figure 19.4: The ChatObjects::ChatCodes module

# NOTE: this contains the STILL_HERE modification for timing out idle clients
# as well as the SET_MCAST_PORT constant from chapter 21.

use strict;
require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT = qw(
             ERROR
             LOGIN_REQ     LOGIN_ACK
             JOIN_REQ      JOIN_ACK
             PART_REQ      PART_ACK
             SEND_PUBLIC   PUBLIC_MSG
             SEND_PRIVATE  PRIVATE_MSG
             USER_JOINS    USER_PARTS
             LIST_CHANNELS CHANNEL_ITEM
             LIST_USERS    USER_ITEM
             LOGOFF        STILL_HERE
	     SET_MCAST_PORT
             );

use constant ERROR        => 10;
use constant LOGIN_REQ    => 20;
use constant LOGIN_ACK    => 30;
use constant LOGOFF       => 40;
use constant JOIN_REQ     => 50;
use constant JOIN_ACK     => 60;
use constant PART_REQ     => 70;
use constant PART_ACK     => 80;
use constant SEND_PUBLIC  => 90;
use constant PUBLIC_MSG   => 100;
use constant SEND_PRIVATE => 120;
use constant PRIVATE_MSG  => 130;
use constant USER_JOINS   => 140;
use constant USER_PARTS   => 150;
use constant LIST_CHANNELS => 160;
use constant CHANNEL_ITEM  => 170;
use constant LIST_USERS    => 180;
use constant USER_ITEM     => 190;
use constant STILL_HERE    => 200;
use constant SET_MCAST_PORT => 210;

1;
