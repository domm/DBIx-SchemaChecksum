use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'DBIx::SchemaChecksum',
    license            => 'perl',
    dist_author        => 'Thomas Klausner <domm@cpan.org>',
    dist_version_from  => 'lib/DBIx/SchemaChecksum.pm',
    build_requires     => { 'Test::More' => 0, },
    requires           => { DBI => '1.604', },
    add_to_cleanup     => ['DBIx-SchemaChecksum-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
