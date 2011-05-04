#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

# it does not make sense (and does not work) to load the storage component
# (DBIx::Class::OverrideDbhAttributes::PerResultSet) in the main package, so we
# load the DBIC schema that loads the component
use_ok( 'TestSchema' );

diag( "Testing DBIx::Class::OverrideDbhAttributes::PerResultSet $DBIx::Class::OverrideDbhAttributes::PerResultSet::VERSION, Perl $], $^X" );

done_testing;
