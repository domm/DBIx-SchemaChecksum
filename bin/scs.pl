#!/usr/bin/perl

use strict;
use warnings;
use DBIx::SchemaChecksum::App;

# PODNAME: scs.pl
# ABSTRACT: run DBIx::SchemaChecksum

DBIx::SchemaChecksum::App->new_with_command->run();

__END__

=head1 USAGE

Please run

  scs.pl help

to get information on available commands and command line options.

=head1 SEE ALSO

See C<perldoc DBIx::SchemaChecksum> for even more info.

