use strict;
use warnings;
package RDF::Trine::Serializer::GraphViz;
#ABSTRACT: Serialize RDF graphs as dot graph diagrams

use RDF::Trine;
use GraphViz;

use base qw(RDF::Trine::Serializer);

our %mime_types = (
    'png' => 'image/png',
    'dot' => 'text/plain',
    'svg' => 'image/svg+xml',
    # TODO ...
);

BEGIN {
    $RDF::Trine::Serializer::serializer_names{ 'graphviz' } = __PACKAGE__;
#    foreach my $type (qw(image/svg+xml image/png)) {
#        $RDF::Trine::Serializer::media_types{ $type } = __PACKAGE__;
#    }
}

sub new {
    my ($class, %args) = @_;
    
    my $self = bless \%args, $class;

    $self->{as} ||= 'dot';
    $self->{mime} ||= $mime_types{ $self->{as} };

    return $self;
}

sub mime_types {
    my $self = shift;
    return ($self->{mime});
}

sub serialize_model_to_string {
    my ($self, $model) = @_;
    return $self->serialize_iterator_to_string( $model->as_stream );
}

sub serialize_model_to_file {
    my ($self, $file, $model) = @_;
    print {$file} $self->serialize_model_to_string($model);
}

sub serialize_iterator_to_string {
    my ($self, $iter) = @_;

    my $g = $self->iterator_as_graphviz($iter);

    my $data;

    my $as = $self->{as} || 'dot';
    if ($as eq 'png') {
        $g->as_png(\$data);
    } elsif ($as eq 'gif') {
        $g->as_gif(\$data);
    } elsif ($as eq 'jpg') {
        $g->as_jpeg(\$data);
    } elsif ($as eq 'gif') {
        $g->as_gif(\$data);
    } elsif ($as eq 'dot') {
        $g->as_canon(\$data);
    }
    
    return $data;
}

sub iterator_as_graphviz {
    my ($self, $iter) = @_;
    my $g   = GraphViz->new();
    my %seen;
    while (my $t = $iter->next) {
        my @nodes;
        foreach my $pos (qw(subject object)) {
            my $n   = $t->$pos();
            my $label   = ($n->isa('RDF::Trine::Node::Literal')) ? $n->literal_value : $n->as_string;
            push(@nodes, $label);
            unless ($seen{ $label }++) {
                $g->add_node( $label );
            }
        }
        $g->add_edge( @nodes, label => $t->predicate->as_string );
    }
    return $g;
}

1;

=head1 DESCRIPTION

L<RDF::Trine::Model> includes a nice but somehow misplaced and non-customizable
method C<as_graphviz>. This module puts it into an object for serialization.  

=head1 SYNOPSIS

  use RDF::Trine::Serializer::GraphViz;
 
  my $ser = RDF::Trine::Serializer->new( 'graphviz', as => 'dot' );
  my $dot = $ser->serialize_model_to_string( $model );

=cut
