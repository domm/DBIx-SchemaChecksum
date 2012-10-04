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
        'Test::Deep'       => '0.099',
        'DBD::SQLite'      => '1.14',
        'Test::Most'       => '0.31',
        'Module::Pluggable' => '4.0',
    },
    requires => {
        'perl'             => '5.010',
        'DBI'              => '1.601',
        'Digest::SHA1'     => '2.11',
        'Moose'            => '0.40',
        'MooseX::Getopt'   => '0.12',
        'Path::Class'      => '0.16',
        'File::Find::Rule' => '0.30',
        'IO::Capture'      => '0.05',
    },
    add_to_cleanup     => ['DBIx-SchemaChecksum-*'],
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
