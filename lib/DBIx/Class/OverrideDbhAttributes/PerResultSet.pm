package DBIx::Class::OverrideDbhAttributes::PerResultSet;

use strict;
use warnings;

=head1 NAME

DBIx::Class::OverrideDbhAttributes::PerResultSet - Lets you override $dbh attributes per resultset

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package MyApp::Schema;

  use strict;
  use warnings;

  use base 'DBIx::Class::Schema';

  __PACKAGE__->load_components('OverrideDbhAttributes::PerResultSet');

  ...

  1;

See L<DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet> for the
actual documentation.

=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

This module allows you to use the
L<DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet> storage
component without requiring you to write an own storage class.

It creates a custom storage class for you that inherits from your current
storage class (L<DBIx::Class::Schema/storage_type>) and makes sure that it
loads the L<DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet>
component then sets it as your storage class
(L<DBIx::Class::Schema/storage_type>).

=head1 METHODS

=cut

=head2 connection

Overridden from L<DBIx::Class::Schema/connection> to replace the
L<DBIx::Class::Schema/storage_type>) with a subclass of it that loaded the
L<DBIx::Class::Storage::DBI::OverrideDbhAttributes::PerResultSet> component.

=cut

sub connection {
  my ($self, @info) = (shift, @_);

  if (@info || !$self->storage) {
    #FIXME code copy-pasted from DBIx::Class::Schema::connection() - should extract it to a separate method in ::Schema and reuse it from here
    my ($storage_class, $args) = ref $self->storage_type
      ? ( $self->_normalize_storage_type($self->storage_type), {} )
      : ( $self->storage_type, {} );

    $storage_class = 'DBIx::Class::Storage'.$storage_class
      if $storage_class =~ m/^::/;

    (my $storage_component = __PACKAGE__)
      =~ s/(DBIx::Class::)/$1Storage::DBI::/;
    my $storage_subclass
      = __PACKAGE__ . "::CustomStorageSubClassFor::$storage_class";

    # hey, this is where i pay the price of not using Class::MOP...
    if ( do { no strict 'refs'; !exists ${"$storage_subclass\::"}{ISA} } ) {
      eval <<"END_STORAGE_CLASS";
      package $storage_subclass;

      use strict;
      use warnings;

      use base '$storage_class';

      __PACKAGE__->load_components('+$storage_component');

      1;
END_STORAGE_CLASS
      if ($@ ne "") {
        $self->throw_exception("Error creating $storage_class subclass "
          . "($storage_subclass) that loads $storage_component: $@");
      }
    }
    $self->storage_type([ $storage_subclass => $args ]);
  }

  return $self->next::method(@_);
}

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-overridedbhattributes-perresultset at rt.cpan.org>, or through the
web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-OverrideDbhAttributes-PerResultSet>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::OverrideDbhAttributes::PerResultSet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-OverrideDbhAttributes-PerResultSet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-OverrideDbhAttributes-PerResultSet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-OverrideDbhAttributes-PerResultSet>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-OverrideDbhAttributes-PerResultSet/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2011 Norbert Buchmuller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIx::Class::OverrideDbhAttributes::PerResultSet
