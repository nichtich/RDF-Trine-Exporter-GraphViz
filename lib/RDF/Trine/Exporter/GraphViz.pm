use strict;
use warnings;
package RDF::Trine::Exporter::GraphViz;
#ABSTRACT: Serialize RDF graphs as dot graph diagrams

use RDF::Trine;
use GraphViz qw(2.04);
use Scalar::Util qw(reftype blessed);
use Carp;

# TODO: create RDF::Trine::Exporter as base class
use base qw(RDF::Trine::Serializer);

our %FORMATS = (
    dot   => 'text/plain',
    ps    => 'application/postscript',
    hpgl  => 'application/vnd.hp-hpgl',
    pcl   => 'application/vnd.hp-pcl',
    mif   => 'application/vnd.mif',
    gif   => 'image/gif',
    jpeg  => 'image/jpeg',
    png   => 'image/png',
    wbmp  => 'image/vnd.wap.wbmp',
    cmapx => 'text/html',
    imap  => 'application/x-httpd-imap',
    'map' => 'application/x-httpd-imap',
    vrml  => 'model/vrml',
    fig   => 'image/x-xfig',
    svg   => 'image/svg+xml',
    svgz  => 'image/svg+xml',
);

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;

    $self->{as} ||= 'dot';
    croak 'Unknown format ' . $self->{as}
        unless $FORMATS{ $self->{as} };

    $self->{mime} ||= $FORMATS{ $self->{as} };

    $self->{style}    ||= { rankdir => 1, concentrate => 1 };
    $self->{node}     ||= { shape => 'plaintext', color => 'gray' };
    $self->{resource} ||= { shape => 'box', style => 'rounded',
        fontcolor => 'blue' };
    $self->{literal}  ||= { shape => 'box' };
    $self->{blank}    ||= { label => '', shape => 'point',
        fillcolor => 'white', color => 'gray', width => '0.3' };
    $self->{variable} ||= { fontcolor => 'darkslategray' };
    $self->{prevar}   ||= '?';
    $self->{alias}    ||= { };

    if ( $self->{url} and (reftype($self->{url})||'') ne 'CODE' ) {
        $self->{url} = sub { shift->uri };
    }

    return $self;
}

sub media_types {
    my $self = shift;
    return ($self->{mime});
}

# The following two methods may better be moved to RDF::Trine::Exporter.
sub serialize_model_to_string {
    my $self  = shift;
    my $model = shift;
    return $self->serialize_iterator_to_string( $model->as_stream, @_ );
}

sub serialize_model_to_file {
    my $self = shift;
    my $file = shift;
    if (defined $file and !ref $file) {
        open (my $fh, '>', $file);
        $file = $fh;
    }
    print {$file} $self->serialize_model_to_string( @_ );
}

sub to_file {
    my $self = shift;
    my $file = shift;
    if (defined $file and !ref $file and
        $file =~ /\.([^.]+)$/ and $FORMATS{$1} ) {
        $self->serialize_model_to_file( $file, @_, as => $1 );
    } else {
        $self->serialize_model_to_file( $file, @_ );
    }
}

sub serialize_iterator_to_string {
    my ($self, $iter, %options) = @_;

    my $g = $self->iterator_as_graphviz($iter, %options);

    my $format = ($options{as} || $self->{as});
    die "Unknown serialization format $format" unless $FORMATS{$format};

    my $method = "as_$format"; 
    $method = 'as_canon' if $method eq 'as_dot';
    $method = 'as_imap'  if $method eq 'as_map';

    my $data;
    eval {
        # TODO: Catch error message sent to STDOUT by dot if this fails.
        $g->$method( \$data );
    };

    return $data;
}

# sub to_string
# sub to_file (with guessing 'as' from filename)

sub as_graphviz {
   my ($self, $rdf, %options) = @_;
   return unless blessed $rdf;
   $rdf = $rdf->as_stream if $self->isa('RDF::Trine::Model');
   return $self->iterator_as_graphviz( $rdf, %options );
}

sub iterator_as_graphviz {
    my ($self, $iter, %options) = @_;

    # We could make use of named graphs in a later version...
    $options{title}      ||= $self->{title};

    $options{namespaces} ||= $self->{namespaces} || { };
    $options{root}       ||= $self->{root};
    $options{prevar}     ||= $self->{prevar};
    $options{alias}      ||= $self->{alias};

    # Basic options. Should be more configurable.
    my %gopt = %{$self->{style}};
    $gopt{node} ||= $self->{node};

    my %root_style = ( color => 'red' );

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
                $label = $options{prevar}.$n->name;
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
                $g->add_node( $label, %{$self->{variable}} );
            }
        }

        my $label = $options{alias}->{ $t->predicate->uri };
        if (!defined $label) {
            my ($local, $qname) = $t->predicate->qname;
            my $prefix = $nsprefix{$local};
            $label = $prefix ? "$prefix:$qname" : $t->predicate->as_string;
        }
        $g->add_edge( @nodes, label => $label );
    }

    return $g;
}

1;

=head1 DESCRIPTION

L<RDF::Trine::Model> includes a nice but somehow misplaced and non-customizable
method C<as_graphviz>. This module implements an extended version, put in a
extends this method in a RDF::Trine::Exporter object.  (actually it is a
subclass of L<RDF::Trine::Serializer> as long as RDF::Trine has no common class
RDF::Trine::Exporter).  This module also includes a command line script
L<rdfdot> to create graph diagrams from RDF data.

=head1 SYNOPSIS

  use RDF::Trine::Exporter::GraphViz;

  my $ser = RDF::Trine::Exporter::GraphViz->new( as => 'dot' );
  my $dot = $ser->serialize_model_to_string( $model );

  $ser->to_file( 'graph.svg', $model );

  # highly configurable
  my $g = RDF::Trine::Exporter::GraphViz->new( 
      namespaces => { 
          foaf => 'http://xmlns.com/foaf/0.1/'
      },
      alias => { 
          'http://www.w3.org/2002/07/owl#sameAs' => '=',
      },
      prevar => '$',  # variables as '$x' instead of '?x'
      url    => 1,    # hyperlink all URIs

	  # see below for more configuration options
  );
  $g->to_file( 'test.svg', $model );


=head1 METHODS

This modules derives from L<RDF::Trine::Serializer> with all of its methods (a
future version may be derived from RDF::Trine::Exporter). The following methods
are of interest in particular:

=head2 new ( %options )

Creates a new serializer with L<configuration|/CONFIGURATION> options
as described below.

=head2 media_types

Returns the exporter's mime type. For instance if you create an exporter with
C<< as => 'svg' >>, this method returns C<< ('image/svg+xml') >>.

=head2 as_graphviz ( $rdf [, %options ] )

Creates and returns a L<GraphViz> object for further processing. You must
provide RDF data as L<RDF::Trine::Iterator> or as L<RDF::Trine::Model>.

=head2 to_file ( $file, $rdf [, %options ] )

Serialize RDF data, provided as L<RDF::Trine::Iterator> or as
L<RDF::Trine::Model> to a file. C<$file> can be a filehandle or file name.
The serialization format is automatically derived from known file extensions.

=head2 serialize_model_to_file ( $file, $model [, %options ] )

Serialize a L<RDF::Trine::Model> as graph diagram to a file, 
where C<$file> can be a filename or a filehandle.

=head2 serialize_model_to_string ( $model [, %options ] )

Serialize a L<RDF::Trine::Model> as graph diagram to a string.

=head2 serialize_iterator_to_string ( $iterator [, %options ] )

Serialize a L<RDF::Trine::Iterator> as graph diagram to a string.

=head2 iterator_as_graphviz ( $iterator )

This internal the core method, used by all C<serialize_...> methods.

=head1 CONFIGURATION

The following configuration options can be set when creating a new object.

=over 4

=item as

Specific serialization format with C<dot> as default. Supported formats include
canonical DOT format (C<dot>), Graphics Interchange Format (C<gif>), JPEG File
Interchange Format (C<jpeg>), Portable Network Graphics (C<png>), Scalable
Vector Graphics (C<svg> and C<svgz>), server side HTML imape map (C<imap> or
C<map>), client side HTML image map (C<cmapx>), PostScript (C<ps>), Hewlett
Packard Graphic Language (C<hpgl>), Printer Command Language (C<pcl>), FIG
format (C<fig>), Maker Interchange Format (C<mif>), Wireless BitMap format
(C<wbmp>), and Virtual Reality Modeling Language (C<vrml>).

=item mime

Mime type. By default automatically set based on C<as>.

=item style

General graph style options as hash reference. Defaults to
C<< { rankdir => 1, concentrate => 1 } >>.

=item node

Hash reference with general options to style nodes. Defaults to
C<< { shape => 'plaintext', color => 'gray' } >>.

=item resource

Hash reference with options to style resource nodes. Defaults to
C<< { shape => 'box', style => 'rounded', fontcolor => 'blue' } >>.

=item literal

Hash reference with options to style literal nodes. Defaults to
C<< { shape => 'box' } >>.

=item blank

Hash reference with options to style blank nodes. Defaults to C<< { label => '',
shape => 'point', fillcolor => 'white', color => 'gray', width => '0.3' } >>.

=item url

Add clickable URLs to nodes You can either provide a boolean value or a code 
reference that returns an URL when given a L<RDF::Trine::Node::Resource>.

=item alias

Hash reference with URL aliases to show as resource and predicate labels.

=item variable

Hash reference with options to style variable nodes. Defaults to C<< {
fontcolor => 'darkslategray' } >>.

=item prevar

Which character to prepend to variable names. Defaults to '?'. You can
also set it to '$'. By now the setting does not affect variables
in Notation3 formulas.

=item root

An URI that is marked as 'root' node.

=item title

Add a title to the graph.

=back

=head1 LIMITATIONS

This serializer does not support C<negotiate> on purpose. It may optionally be
enabled in a future version. GraphViz may fail on large graphs, its error
message is not catched yet.  Configuration in general is not fully covered by
unit tests. Identifiers of blank nodes are not included.

=cut
