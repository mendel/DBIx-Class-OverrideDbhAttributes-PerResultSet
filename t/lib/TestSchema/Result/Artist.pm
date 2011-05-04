package TestSchema::Result::Artist;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artist_id => { is_auto_increment => 1 },
);

__PACKAGE__->set_primary_key('artist_id');

1;
