package DBIx::SchemaChecksum::App::ShowUpdatePath;
use 5.010;

# ABSTRACT: DBIx::SchemaChecksum command show_update_path

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);
use Carp qw(croak);

option 'from_checksum'  => ( is => 'ro', isa => 'Str' );
option '+sqlsnippetdir' => ( required => 1);

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
    say $file->relative($self->sqlsnippetdir) ." ($checksum)";
}

__PACKAGE__->meta->make_immutable();
1;
