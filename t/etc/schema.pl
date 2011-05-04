{
  schema_class  => 'TestSchema',
  connect_info  =>
    [ 'dbi:SQLite:dbname=:memory:', '', '', {}, { disable_sth_caching => 1 } ],
  fixture_sets  => {
    basic => {
      'Artist'  => [
        [ 'artist_id' ],
        [ 1,          ],
        [ 42,         ],
      ],
    },
  },
}
