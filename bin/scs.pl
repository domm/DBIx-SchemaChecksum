#!/usr/bin/perl

# PODNAME: scs.pl
# ABSTRACT: run DBIx::SchemaChecksum, but really you should use dbchecksum
# VERSION

use strict;
use warnings;
use DBIx::SchemaChecksum::App;

DBIx::SchemaChecksum::App->new_with_command->run();

__END__

=head1 USAGE

Deprecated, please use C<bin/dbchecksum>

=head1 SEE ALSO

See C<perldoc DBIx::SchemaChecksum> for even more info.

