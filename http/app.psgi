#!/usr/bin/env perl
# app.psgi for elixir - wraps http/web.py.

use 5.010;
use strict;
use warnings;

use Capture::Tiny::Extended qw(capture);
use CGI::Emulate::PSGI;
#use Data::Dumper::Compact qw(ddc);
use IPC::Run3;

#open my $stdout_fh, '<&', *STDOUT;

my $handler = CGI::Emulate::PSGI->handler(sub {
    $ENV{SCRIPT_URL} = $ENV{REQUEST_URI};   # web.py uses SCRIPT_URL
    my ($stdout, $stderr, $exit);# = capture {
    #return system 'bash -c "python3 ./web.py"';
    #};

    #run3 [qw(python3 ./web.py)], undef, \$stdout, \$stderr;
    
    $stdout = `python3 ./web.py`;
    die "Exit code $!: $stderr" if $!;
    print $stdout;
});
