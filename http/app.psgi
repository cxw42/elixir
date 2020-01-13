#!/usr/bin/env perl
# app.psgi for elixir - wraps http/web.py.

use 5.010;
use strict;
use warnings;

my ($VERBOSE, $logfh);
BEGIN { $VERBOSE = 0; }

use CGI::Emulate::PSGI;
use CGI::Parse::PSGI;
use Data::Dumper::Compact qw(ddc);
use IO::Handle;
use IPC::Run3;
use Perl6::Slurp;
use Plack::App::File;

do './config_local.pl' if -r './config_local.pl';

open $logfh, '>', '/dev/stdout';
$logfh->autoflush(1);

# the Python script requires this directory to exist
do { mkdir $_ unless -d $_ } for '/tmp/elixir-errors';

# Modified from CGI::Emulate::PSGI::handler()
my $main_handler = sub {
    my $env = shift;

    # Set up environment
    local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));
    $ENV{SCRIPT_URL} = $ENV{REQUEST_URI};   # web.py uses SCRIPT_URL

    # Run web.py
    my $stdin = slurp $env->{'psgi.input'};
    my $stdout;

    say $logfh "Got input ", ddc \$stdin if $VERBOSE;

    run3 [qw(python3 ./web.py)],
        \$stdin,
        \$stdout,
        sub { $env->{'psgi.errors'}->print(join '', @_) } # stderr
    ;
    my $exitcode = $?;

    # Produce output
    say $logfh "Exit code $exitcode" if $VERBOSE;
    die "Error: returned $exitcode" if $exitcode;
    return CGI::Parse::PSGI::parse_cgi_output(\$stdout);
};

my $file_handler = Plack::App::File->new(root=>'.')->to_app;

return sub {
    my ($env) = @_;

    say $logfh "Request for $env->{REQUEST_URI}";

    # Rewrite
    if($env->{REQUEST_URI} eq '/') {
        $env->{REQUEST_URI} = $env->{PATH_INFO} = '/test/latest/source';
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
