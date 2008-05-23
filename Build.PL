use strict;
use warnings;
use Module::Build;
use 5.010;

my $builder = Module::Build->new(
    module_name       => 'DBIx::SchemaChecksum',
    license           => 'perl',
    dist_author       => 'Thomas Klausner <domm@cpan.org>',
    dist_version_from => 'lib/DBIx/SchemaChecksum.pm',
    build_requires    => {
        'Test::More'       => 0,
        'Test::NoWarnings' => '0.084',
        'DBD::SQLite'      => '1.14',
    },
    requires => {
        'perl'           => '5.010',
        'DBI'            => '1.601',
        'Digest::SHA1'   => '2.11',
        'Moose'          => '0.40',
        'MooseX::Getopt' => '0.12',
    },
    add_to_cleanup     => ['DBIx-SchemaChecksum-*'],
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
