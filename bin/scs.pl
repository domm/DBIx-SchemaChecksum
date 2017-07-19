#!/usr/bin/perl

use strict;
use warnings;
use DBIx::SchemaChecksum::App;

# PODNAME: scs.pl
# ABSTRACT: run DBIx::SchemaChecksum, but really you should use dbchecksum

DBIx::SchemaChecksum::App->new_with_command->run();

__END__

=head1 USAGE

Deprecated, please use C<bin/dbchecksum>

=head1 SEE ALSO

See C<perldoc DBIx::SchemaChecksum> for even more info.

