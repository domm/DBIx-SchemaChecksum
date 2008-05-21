#!/usr/bin/perl

use strict;
use warnings;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new_with_options();

print $sc->schemadump ."\n" if $sc->verbose;
print $sc->checksum,"\n";


