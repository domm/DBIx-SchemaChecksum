#!/usr/bin/perl

use strict;
use warnings;
use DBIx::SchemaChecksum::App;

# PODNAME: scs.pl
# ABSTRACT: run DBIx::SchemaChecksum

DBIx::SchemaChecksum::App->new_with_command->run();

