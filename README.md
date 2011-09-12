# NAME

RDF::Trine::Exporter::GraphViz - Serialize RDF graphs as dot graph diagrams

# VERSION

version 0.004

# SYNOPSIS

  use RDF::Trine::Exporter::GraphViz;

  my $ser = RDF::Trine::Exporter::GraphViz->new( as => 'dot' );
  my $dot = $ser->serialize_model_to_string( $model );

# DESCRIPTION

[RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) includes a nice but somehow misplaced and non-customizable
method `as_graphviz`. This module puts it into a RDF::Trine::Exporter object.
(actually it is a subclass of [RDF::Trine::Serializer](http://search.cpan.org/perldoc?RDF::Trine::Serializer) as long as RDF::Trine
has no common RDF::Trine::Exporter superclass).  This module also includes a
command line script [rdfdot](http://search.cpan.org/perldoc?rdfdot) to create graph diagrams from RDF data.

# METHODS

This modules derives from [RDF::Trine::Serializer](http://search.cpan.org/perldoc?RDF::Trine::Serializer) with all of its methods (a
future version may be derived from RDF::Trine::Exporter). The following methods
are of interest in particular:

## new ( %options )

Creates a new serializer with [CONFIGURATION](#pod_CONFIGURATION) options
as described below.

## media_types

Returns the exporter's mime type. For instance if you create an exporter with
`as => 'svg'`, this method returns `('image/svg+xml')`.

## as_graphviz ( $rdf [, %options ] )

Creates and returns a [GraphViz](http://search.cpan.org/perldoc?GraphViz) object for further processing. You must
provide RDF data as [RDF::Trine::Iterator](http://search.cpan.org/perldoc?RDF::Trine::Iterator) or as [RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model).

## serialize_model_to_file ( $file, $model )

Serialize a [RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) as graph diagram to a file.

## serialize_model_to_string ( $model )

Serialize a [RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) as graph diagram to a string.

## serialize_iterator_to_string ( $iterator, [ %options ] )

Serialize a [RDF::Trine::Iterator](http://search.cpan.org/perldoc?RDF::Trine::Iterator) as graph diagram to a string.

## iterator_as_graphviz ( $iterator )

This internal the core method, used by all `serialize_...` methods.

# CONFIGURATION

The following configuration options can be set when creating a new object.

- as

Specific serialization format with `dot` as default. Supported formats include
canonical DOT format (`dot`), Graphics Interchange Format (`gif`), JPEG File
Interchange Format (`jpeg`), Portable Network Graphics (`png`), Scalable
Vector Graphics (`svg` and `svgz`), server side HTML imape map (`imap` or
`map`), client side HTML image map (`cmapx`), PostScript (`ps`), Hewlett
Packard Graphic Language (`hpgl`), Printer Command Language (`pcl`), FIG
format (`fig`), Maker Interchange Format (`mif`), Wireless BitMap format
(`wbmp`), and Virtual Reality Modeling Language (`vrml`).

- mime

Mime type. By default automatically set based on `as`.

- style

General graph style options as hash reference. Defaults to
`{ rankdir => 1, concentrate => 1 }`.

- node

Hash reference with general options to style nodes. Defaults to
`{ shape => 'plaintext', color => 'gray' }`.

- resource

Hash reference with options to style resource nodes. Defaults to
`{ shape => 'box', style => 'rounded', fontcolor => 'blue' }`.

- literal

Hash reference with options to style literal nodes. Defaults to
`{ shape => 'box' }`.

- blank

Hash reference with options to style blank nodes. Defaults to `{ label => '',
shape => 'point', fillcolor => 'white', color => 'gray', width => '0.3' }`.

- url

Add URLs to nodes. You can either provide a boolean value or a code reference
that returns an URL when given a [RDF::Trine::Node::Resource](http://search.cpan.org/perldoc?RDF::Trine::Node::Resource).

- root

An URI that is marked as 'root' node.

- title

Add a title to the graph.

# LIMITATIONS

This serializer does not support `negotiate` on purpose. It may optionally be
enabled in a future version. GraphViz may fail on large graphs and its error
message is not catched yet. By now, only simple statement graphs are supported.
Serialization of [RDF::Trine::Node::Variable](http://search.cpan.org/perldoc?RDF::Trine::Node::Variable) may be added later. Configuration
in general is not fully tested yet.

# AUTHOR

Jakob Voß <voss@gbv.de>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.