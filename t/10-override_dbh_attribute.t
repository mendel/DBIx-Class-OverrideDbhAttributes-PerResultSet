#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

my %private_attribute_default_values = map {
  ("private_dbic_overridedbhattributes_perresultset_$_" => $_)
} 0 .. 5;

my %private_attribute_new_values = map {
  $_ => 2 * $private_attribute_default_values{$_}
} keys %private_attribute_default_values;

# monkey-patch $dbh->prepare() and $sth->execute() so that we can capture the
# actual value of the $dbh attrs when they're called
my %private_attributes_during_prepare;
my %private_attributes_during_execute;
BEGIN {
  use DBI;

  {
    my $old_dbh_prepare = \&DBI::db::prepare;
    my $new_dbh_prepare = sub {
      my ($self) = @_;

      %private_attributes_during_prepare = map {
        $_ => $self->{$_}
      } keys %private_attribute_default_values;

      goto $old_dbh_prepare;
    };

    no strict 'refs';
    no warnings 'redefine';

    *DBI::db::prepare = $new_dbh_prepare;
  }

  {
    my $old_sth_execute = \&DBI::st::execute;
    my $new_sth_execute = sub {
      my ($self) = @_;

      %private_attributes_during_execute = map {
        $_ => $self->{Database}->{$_}
      } keys %private_attribute_default_values;

      goto $old_sth_execute;
    };

    no strict 'refs';
    no warnings 'redefine';

    *DBI::st::execute = $new_sth_execute;
  }
}

use Test::DBIx::Class;

fixtures_ok 'basic', 'installed the basic fixtures from configuration files';

{
  my %tests = (
    count         => {
      code            => sub { $_->count; },
      expected_value  => 2,
    },
    find          => {
      code            => sub { $_->find({ artist_id => 42 }); },
      expected_value  => Isa('DBIx::Class::Row') && methods( id => 42 ),
    },
    search_single => {
      code            => sub { $_->search({ artist_id => 42 })->single; },
      expected_value  => Isa('DBIx::Class::Row') && methods( id => 42 ),
    },
    search_first  => {
      code            => sub { $_->search({ artist_id => 42 })->first; },
      expected_value  => Isa('DBIx::Class::Row') && methods( id => 42 ),
    },
  );

  while ( my ($test_name, $test) = each %tests ) {
    # tests with setting attributes
    {
      while ( my ($name, $value) = each %private_attribute_default_values ) {
        Schema->storage->dbh->{$name} = $value;
      }

      %private_attributes_during_prepare = ();
      %private_attributes_during_execute = ();

      my $rs_with_attrs = Schema->resultset('Artist')->search(
        undef,
        {
          dbh_attributes => \%private_attribute_new_values,
        }
      );

      lives_and {
        cmp_deeply(
          do {
            local $_ = $rs_with_attrs;
            $test->{code}->();
          },
          $test->{expected_value}
        );
      } "selecting using \$rs returns the expected result "
        . "($test_name, with attrs))";

      cmp_deeply(
        \%private_attributes_during_prepare,
        \%private_attribute_new_values,
        "the attributes are set to the new values during \$dbh->prepare "
          . "($test_name, with attrs)"
      );

      cmp_deeply(
        \%private_attributes_during_execute,
        \%private_attribute_new_values,
        "the attributes are set to the new values during \$sth->execute "
          . "($test_name, with attrs)"
      );

      cmp_deeply(
        {
          map {
            $_ => Schema->storage->dbh->{$_}
          } keys %private_attribute_default_values
        },
        \%private_attribute_default_values,
        "the private attributes are restored to their original values "
          . "($test_name, with attrs)"
      );
    }

    # tests without setting attributes
    {
      while ( my ($name, $value) = each %private_attribute_default_values ) {
        Schema->storage->dbh->{$name} = $value;
      }

      %private_attributes_during_prepare = ();
      %private_attributes_during_execute = ();

      my $rs_without_attrs = Schema->resultset('Artist');

      lives_and {
        cmp_deeply(
          do {
            local $_ = $rs_without_attrs;
            $test->{code}->();
          },
          $test->{expected_value}
        );
      } "selecting using \$rs returns the expected result "
        . "($test_name, with attrs))";

      cmp_deeply(
        \%private_attributes_during_prepare,
        \%private_attribute_default_values,
        "the attributes are not changed during \$dbh->prepare ($test_name, "
          . "without attrs)"
      );

      cmp_deeply(
        \%private_attributes_during_execute,
        \%private_attribute_default_values,
        "the attributes are not changed during \$sth->execute ($test_name, "
          . "without attrs)"
      );

      cmp_deeply(
        {
          map {
            $_ => Schema->storage->dbh->{$_}
          } keys %private_attribute_default_values
        },
        \%private_attribute_default_values,
        "the private attributes kept their original values ($test_name, "
          . "without attrs)"
      );
    }
  }
}

done_testing;
