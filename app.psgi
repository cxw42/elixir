#!/usr/bin/env perl
# app.psgi for elixir - wraps http/web.py.

use 5.010;
use strict;
use warnings;

use CGI::Emulate::PSGI;
#use Data::Dumper::Compact qw(ddc);

#open my $stdout_fh, '<&', *STDOUT;

CGI::Emulate::PSGI->handler(sub {
    #my $env = shift;
    #local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));
    $ENV{SCRIPT_URL} = $ENV{REQUEST_URI};   # web.py uses SCRIPT_URL
    #print $stdout_fh, ddc \%ENV;
    system 'http/web.py';
});
