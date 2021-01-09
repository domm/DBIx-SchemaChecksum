package DBIx::SchemaChecksum::App::ShowUpdatePath;

# ABSTRACT: Show the update path
# VERSION

use 5.010;

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);
use Carp qw(croak);
use Moose::Util::TypeConstraints;

option 'from_checksum'  => ( is => 'ro', isa => 'Str',documentation => q[start update path from this checksum]
 );
option 'output'  => ( is => 'ro',  default=>'nice',isa=>enum([qw[ nice concat psql ]]),);
option 'dbname' => ( is=>'ro', isa=>'Str', default=>'datebase_name');
option '+sqlsnippetdir' => ( required => 1);

has '_concat' => (is=>'rw',isa=>'Str', default=>'');

sub run {
    my $self = shift;

    $self->show_update_path( $self->from_checksum || $self->checksum );

}

sub show_update_path {
    my ($self, $this_checksum) = @_;
    my $update_path = $self->_update_path;

    my $update = $update_path->{$this_checksum}
        if ( exists $update_path->{$this_checksum} );

    unless ($update) {
        print "# " if $self->output eq 'psql';
        print "-- " if $self->output eq 'concat';
        say "No update found that's based on $this_checksum.";
        return;
    }

    if ( $update->[0] eq 'SAME_CHECKSUM' ) {
        my ( $file, $post_checksum ) = splice( @$update, 1, 2 );
        $self->report_file($file, $post_checksum);
        $self->show_update_path($post_checksum);
    }
    else {
        $self->report_file($update->[0],$update->[1]);
        $self->show_update_path($update->[1]);
    }
}

sub report_file {
    my ($self, $file, $checksum) = @_;

    if ($self->output eq 'nice') {
        say $file->relative($self->sqlsnippetdir) ." ($checksum)";
    }
    elsif ($self->output eq 'psql') {
        say 'psql '.$self->dbname.' -1 -f '.$file->relative($self->sqlsnippetdir);
    }
    elsif ($self->output eq 'concat') {
        say "\n-- file: ".$file->relative($self->sqlsnippetdir)."\n".join('',$file->slurp)."\n";
    }
}

__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 DESCRIPTION

Show the whole update path starting from the current checksum, or from
the one provided via C<--from_checksum>. Use 'C<--output concat>' to
concat all changes to STDOUT. Use 'C<--output psql --dbname your-db>'
to print some C<psql> commands to apply changes.

=cut

