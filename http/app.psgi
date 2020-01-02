#!/usr/bin/env perl
# app.psgi for elixir - wraps http/web.py.

use 5.010;
use strict;
use warnings;

my ($VERBOSE, $logfh);
BEGIN { $VERBOSE = 0; }

use CGI::Emulate::PSGI;
use Data::Dumper::Compact qw(ddc);
use IO::Handle;
use Plack::App::File;

open $logfh, '>', '/dev/stdout';
$logfh->autoflush(1);

my $main_handler = CGI::Emulate::PSGI->handler(sub {
    $ENV{SCRIPT_URL} = $ENV{REQUEST_URI};   # web.py uses SCRIPT_URL
    my $stdout = `python3 ./web.py`;
    die "Error $! $^E" if $!;
    print $stdout;
});

my $file_handler = Plack::App::File->new(root=>'.')->to_app;

return sub {
    my ($env) = @_;

    say $logfh "Request for $env->{REQUEST_URI}";

    # Rewrite
    if($env->{REQUEST_URI} eq '/') {
        $env->{REQUEST_URI} = $env->{PATH_INFO} = '/linux/latest/source';
        $env->{SCRIPT_NAME} = '';
    }

    print $logfh ddc $env if $VERBOSE;

    # Dispatch
    if($env->{REQUEST_URI} =~ m{/(?:source|ident|search)\b}) {
        say $logfh "Using main handler" if $VERBOSE;
        goto &$main_handler;
    } else {
        say $logfh "Using file handler" if $VERBOSE;
        goto &$file_handler;
    }
};
