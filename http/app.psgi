#!/usr/bin/env perl
# app.psgi for elixir - wraps http/web.py.

my ($VERBOSE, $logfh);
BEGIN { $VERBOSE = 0; }

{
    package HandleFromRead;
    use 5.010;
    use strict;
    use warnings;
    use Data::Dumper::Compact qw(ddc);

    use parent 'Tie::StdHandle';

    sub TIEHANDLE {
        my ($class, %args) = (@_);
        print $logfh "Tying: ", ddc(\%args);
        bless \%args, $class;
    }

    sub READ {
        my $self = shift;
        my $bufref = \$_[0];
        my(undef,$len,$offset) = @_;
        say $logfh "READ called, \$buf=$bufref, \$len=$len, \$offset=$offset";
        # add to $$bufref, set $len to number of characters read
        return $self->{psgi_stream}->read($$bufref, $len, $offset);
    }

    sub WRITE {
        my $self = shift;
        my($buf,$len,$offset) = @_;
        say $logfh "WRITE called, \$buf=$buf, \$len=$len, \$offset=$offset";
        return $self->{psgi_stream}->print(substr($buf, $offset, $len));
    }
}

use 5.010;
use strict;
use warnings;

use CGI::Emulate::PSGI;
use Data::Dumper::Compact qw(ddc);
use IO::Handle;
use Plack::App::File;

do './config_local.pl' if -r './config_local.pl';

open $logfh, '>', '/dev/stdout';
$logfh->autoflush(1);

my $main_handler = CGI::Emulate::PSGI->handler(sub {
    $ENV{SCRIPT_URL} = $ENV{REQUEST_URI};   # web.py uses SCRIPT_URL
    my $stdout = `unbuffer python3 ./web.py`;
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

        # Make the file handles work with read()
        local *fh_stdin;
        tie *fh_stdin, 'HandleFromRead', psgi_stream => $env->{'psgi.input'};
        $env->{'psgi.input'} = *fh_stdin;

        local *fh_stderr;
        tie *fh_stderr, 'HandleFromRead', psgi_stream => $env->{'psgi.errors'};
        $env->{'psgi.errors'} = *fh_stderr;

        goto &$main_handler;
    } else {
        say $logfh "Using file handler" if $VERBOSE;
        goto &$file_handler;
    }
};
