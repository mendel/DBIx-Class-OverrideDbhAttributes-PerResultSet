package TestSchema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components('OverrideDbhAttributes::PerResultSet');

__PACKAGE__->load_namespaces;

1;
