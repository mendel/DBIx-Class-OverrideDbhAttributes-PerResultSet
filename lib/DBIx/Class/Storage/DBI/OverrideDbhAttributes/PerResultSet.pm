package DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet;

use strict;
use warnings;

=head1 NAME

DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet - Storage component that lets you override $dbh attributes per resultset

=head1 SYNOPSIS

  package MyApp::Storage;

  use strict;
  use warnings;

  use base 'DBIx::Class::Storage';

  __PACKAGE__->load_components(
    'Storage::DBI::OverrideDbhAttributes::PerResultSet');

  ...

  1;


  package MyApp::Schema;

  use strict;
  use warnings;

  use base 'DBIx::Class::Schema';

  __PACKAGE__->load_components('OverrideDbhAttributes::PerResultSet');

  ...

  1;


  # this enables tracing - only for the SELECTs generated by this resultset
  my $nr1_artists_rs = $schema->resultset('Artist')->search(
    {
      rank => 1,
    },
    {
      dbh_attributes => { TraceLevel => 'SQL' },
    }
  );

  my $num_rank1_artists = $artist_rs->count;    # this will print trace info

  my $first_rank1_artist = $artist_rs->single;  # this will print trace info

  # this will not print trace info
  my $num_rank2_3_artists = $schema->resultset('Artist')->search(
    {
      rank => [ 2, 3 ],
    }
  )->count;

  # this disables server-side prepared statements for DBD::Pg - only for the
  # SELECTs generated by this resultset
  my $djs_rs = $schema->resultset('Artist')->search(
    {
      name => { -like => 'DJ. %' },
    },
    {
      dbh_attributes => { pg_server_prepare => 0 },
    }
  );

  # now it can benefit from a b-tree index on "name" (the planner sees that the
  # pattern starts with literal chars)
  my $num_djs = $artist_rs->count;

See L<DBIx::Class::OverrideDbhAttributes::PerResultSet> if you don't care to
write your own storage subclass.

=head1 DESCRIPTION

This storage component allows you to temporarily override L<DBI> attributes
(see L<DBI/ATTRIBUTES COMMON TO ALL HANDLES> and L<DBI/DBI DATABASE HANDLE
OBJECTS>, see also DBD-specific db handle attributes) on a per resultset basis:
they will have the desired values while DBIC C<prepare()>s (see L<DBI/prepare>)
and C<execute()>s (see L<DBI/execute>) the generated SQL statements but are
restored afterwards.

The primary usage of this module is to make the DBD to not use prepared
statements for the SQL generated by a certain resultset (so that the query
planner will have more information to choose a more optimal plan). Of course
this only works for some DBDs and they have differently named dbh attributes to
achive this. (A module that knows the DBD-specific details and hides them
behind a portable interface might be useful for some purposes..  we'll see
later)

Internally it local()izes and changes the given dbh attributes before
L<DBIx::Class::Storage/_select> is called (which means they're restored to
their previous value after L<DBIx::Class::Storage/_select> returns).

B<Warning>: L<DBIx::Class> caches the statement handles by default (see
L<DBI/prepare_cached> and L<DBIx::Class::Storage::DBI/disable_sth_caching>),
which means that the overridden $dbh B<< attributes are seen by L<DBI/prepare>
only the first time the same SQL statement is prepared >> (but L<DBI/execute>
still sees them).

Consider this example:

  # this caches the prepared statement for
  # "SELECT artist_id, name FROM artist WHERE artist_id = ? OR ?"
  my @artists = $rs->search(
    {
      artist_id => [ 1, 2 ],
    }
  )->all;

  # this one also generates the same SQL, so the 'dbh_attributes' has no
  # effect on $dbh->prepare()! (they still affect $sth->execute() though)
  my @more_artists = $rs->search(
    {
      artist_id => [ 3, 4 ],
    },
    {
      dbh_attributes => {
        fetch_them_real_fast_please => 1,
      },
    }
  )->all;

If that really matters for you, consider setting the
L<DBIx::Class::Storage::DBI/disable_sth_caching> DBIC connection attribute.

=head1 METHODS

=cut

=head2 _select

Overridden from L<DBIx::Class::Storage/_select> to temporarily override dbh
attributes while running the original method.

=cut

sub _select {
  my ($self, $from, $select, $where, $attrs) = (shift, @_);
        
  # $storage->dbh is a tied hash, avoid reading/writing it unnecessarily
  if (exists $attrs->{dbh_attributes}) {
    my $attributes = $attrs->{dbh_attributes} || {};
    local @{ $self->dbh }{ keys %$attributes } = values %$attributes;

    return $self->next::method(@_);
  }
  else {
    return $self->next::method(@_);
  }
}

=head1 SEE ALSO

L<DBIx::Class>, L<DBI>, L<DBD>

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=cut

1; # End of DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet
