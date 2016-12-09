#!/usr/bin/perl
# file: eliza.pl
# Figure 10.2: Command-line Eliza Program

use Chatbot::Eliza;
$| = 1;
my $bot = Chatbot::Eliza->new;
$bot->command_interface();
