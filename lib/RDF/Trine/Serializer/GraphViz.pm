use strict;
use warnings;
package RDF::Trine::Serializer::GraphViz;
#ABSTRACT: Serialize RDF graphs as dot graph diagrams

use RDF::Trine;
use GraphViz;
use Scalar::Util qw(reftype);
use Carp;

use base qw(RDF::Trine::Serializer);

our %formats = (
    'png' => { mime => 'image/png', method => 'as_png' },
    'dot' => { mime => 'text/plain', method => 'as_canon' },
    'svg' => { mime => 'image/svg+xml', method => 'as_svg' },
    'gif' => { mime => 'image/gif', method => 'as_gif' },
    # ...
);

BEGIN {
    $RDF::Trine::Serializer::serializer_names{ 'graphviz' } = __PACKAGE__;
#    my @media_types = ... # this could be controlled by 'import'
#    foreach my $type (@media_types) {
#        $RDF::Trine::Serializer::media_types{ $type } = __PACKAGE__;
#    }
}

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;

    $self->{as} ||= 'dot';
    croak 'Unknown format ' . $self->{as}
        unless $formats{ $self->{as} };

    $self->{mime} ||= $formats{ $self->{as} }->{mime};

    $self->{style}    ||= { rankdir => 1, concentrate => 1 };
    $self->{node}     ||= { shape => 'plaintext', color => 'gray' };
    $self->{resource} ||= { shape => 'box', style => 'rounded',
        fontcolor => 'blue' };
    $self->{literal}  ||= { shape => 'box' };
    $self->{blank}    ||=  { label => '', shape => 'point',
        fillcolor => 'white', color => 'gray', width => '0.3' };

    if ( $self->{url} and (reftype($self->{url})||'') ne 'CODE' ) {
        $self->{url} = sub { shift->uri };
    }

    return $self;
}

sub media_types {
    my $self = shift;
    return ($self->{mime});
}

sub serialize_model_to_string {
    my ($self, $model) = @_;
    return $self->serialize_iterator_to_string( $model->as_stream );
}

sub serialize_model_to_file {
    my ($self, $file, $model) = @_;
    print {$file} $self->serialize_model_to_string( $model );
}

sub serialize_iterator_to_string {
    my ($self, $iter) = @_;

    my $g = $self->iterator_as_graphviz($iter);

    my $method = $formats{ $self->{as} }->{method};
    my $data;

    eval {
        # TODO: Catch error message sent to STDOUT by dot if this fails.
        $g->$method( \$data );
    };

    return $data;
}

sub iterator_as_graphviz {
    my ($self, $iter, %options) = @_;

    # We could make use of named graphs in a later version...
    $options{title} ||= $self->{title};

    $options{namespaces} ||= $self->{namespaces} || { };
    $options{root}       ||= $self->{root};

    # Basic options. Should be more configurable.
    my %gopt = %{$self->{style}};
    $gopt{node} ||= $self->{node};

    my %root_style  = ( color => 'red' );

    $gopt{name} = $options{title} if defined $options{title};
    my $g = GraphViz->new( %gopt );
    my %nsprefix = reverse %{$options{namespaces}};

    my %seen;
    while (my $t = $iter->next) {
        my @nodes;
        foreach my $pos (qw(subject object)) {
            my $n = $t->$pos();
            my $label;
            if ($n->is_literal) {
                $label = $n->literal_value;
            } elsif( $n->is_resource ) {
                $label = $n->uri;
            } elsif( $n->is_blank ) {
                $label = $n->as_string;
            } elsif( $n->is_variable ) {
                # TODO
            }
            push(@nodes, $label);
            next if ($seen{ $label }++);
            if ( $n->is_literal ) {
                # TODO: add language / datatype
                $g->add_node( $label, %{$self->{literal}} );
            } elsif ( $n->is_resource ) {
                my %layout = %{$self->{resource}};
                $layout{URL} = $self->{url}->( $n ) if $self->{url};
                if ( ($options{'root'} ||  '') eq $n->uri ) {
                    $layout{$_} = $root_style{$_} for keys %root_style;
                }
                $g->add_node( $label, %layout );
            } elsif ( $n->is_blank ) {
                $g->add_node( $label, %{$self->{blank}} );
            } elsif ( $n->is_variable ) {
                # TODO
            }
        }

        my ($local, $qname) = $t->predicate->qname;
        my $prefix = $nsprefix{$local};
        my $label = $prefix ? "$prefix:$qname" : $t->predicate->as_string;
        $g->add_edge( @nodes, label => $label );
    }

    return $g;
}

1;

=head1 DESCRIPTION

L<RDF::Trine::Model> includes a nice but somehow misplaced and non-customizable
method C<as_graphviz>. This module puts it into a L<RDF::Trine::Serializer>
object.  This module also includes a command line script C<rdfdot> to create
graph diagrams from RDF data.

=head1 SYNOPSIS

  use RDF::Trine::Serializer::GraphViz;

  my $ser = RDF::Trine::Serializer->new( 'graphviz', as => 'dot' );
  my $dot = $ser->serialize_model_to_string( $model );

=head1 CONFIGURATION

=over 4

=item as

Specific serialization format with C<dot> as default. Supported formats include
C<dot>, C<svg>, C<png>, and C<gif>.

=item style

General graph style options as hash reference. Defaults to
C<<{ rankdir => 1, concentrate => 1 }>>.

=item node

Hash reference with general options to style nodes. Defaults to
C<< { shape => 'plaintext', color => 'gray' } >>.

=item resource

Hash reference with options to style resource nodes. Defaults to
C<<{ shape => 'box', style => 'rounded', fontcolor => 'blue' }>>.

=item literal

Hash reference with options to style literal nodes. Defaults to
C<< { shape => 'box' } >>.

=item blank

Hash reference with options to style blank nodes. Defaults to C<<{ label => '',
shape => 'point', fillcolor => 'white', color => 'gray', width => '0.3' }>>.

=item url

Add URLs to nodes. You can either provide a boolean value or a code reference
that returns an URL when given a L<RDF::Trine::Node::Resource>.

=item root

An URI that is marked as 'root' node.

=item title

Add a title to the graph.

=item mime

Mime type. By default automatically set based on C<as>.

=back

=head1 METHODS

This modules derives from L<RDF::Trine::Serializer> with all of its methods. In
addition you can create raw L<GraphViz> objects. The following methods are of
interest in particular:

=head2 new ( %options )

Creates a new serializer with L<configuration|/CONFIGURATION> options.

=head2 media_types

Returns exactely one MIME Type that the serializer is configured for.

=head2 iterator_as_graphviz ( $iterator )

Creates a L<GraphViz> object for further processing. This is the core method,
used by all C<serialize_...> methods.

=head2 serialize_model_to_file ( $file, $model )

Serialize a L<RDF::Trine::Model> as graph diagram to a file.

=head2 serialize_model_to_string ( $model )

Serialize a L<RDF::Trine::Model> as graph diagram to a string.

=head2 serialize_iterator_to_string ( $iterator, [ %options ] )

Serialize a L<RDF::Trine::Iterator> as graph diagram to a string.

=head1 LIMITATIONS

This serializer does not support C<negotiate> on purpose. It may optionally be
enabled in a future version. GraphViz may fail on large graphs and its error
message is not catched yet. By now, only simple statement graphs are supported.
Serialization of L<RDF::Trine::Node::Variable> may be added later. Configuration
in general is not fully tested yet.

=cut
