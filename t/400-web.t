#!/usr/bin/env perl
# t/400-web.pl: Test web.py
#
# Copyright (c) 2020 Christopher White, <cxwembedded@gmail.com>.
#
# Elixir is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Elixir is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# # You should have received a copy of the GNU Affero General Public License
# along with Elixir.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# This file uses core Perl modules only.

use FindBin '$Bin';
use lib $Bin;

use Test::More;

use TestEnvironment;
use TestHelpers;

# ===========================================================================
# Main

# This block is all that's required to set up for a test.
my $tenv = TestEnvironment->new;
$tenv->build_repo(sibling_abs_path('tree'));	# dies on error
$tenv->build_db;
$tenv->update_env;

print($tenv->report);

my ($exit_status, $lrStdout, $lrStderr) = $tenv->make_web_request('/linux/v5.4/ident/gsb_buffer');

cmp_ok $exit_status, '==', 0, 'Program reported success';
cmp_ok @$lrStderr, '==', 0, 'no stderr output';
cmp_ok @$lrStdout, '>', 0, 'stdout output';
my ($http_status) = map { /^Status: (\d+)/ ? ($1) : () } @$lrStdout;
ok $http_status, 'Got HTTP status';
is $http_status, '200', '200 OK';

diag join "\n", @$lrStdout;


done_testing;
