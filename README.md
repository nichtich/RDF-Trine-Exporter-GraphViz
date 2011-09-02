# NAME

RDF::Trine::Serializer::GraphViz - Serialize RDF graphs as dot graph diagrams

# VERSION

version 0.002

# SYNOPSIS

  use RDF::Trine::Serializer::GraphViz;

  my $ser = RDF::Trine::Serializer->new( 'graphviz', as => 'dot' );
  my $dot = $ser->serialize_model_to_string( $model );

# DESCRIPTION

[RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) includes a nice but somehow misplaced and non-customizable
method `as_graphviz`. This module puts it into a [RDF::Trine::Serializer](http://search.cpan.org/perldoc?RDF::Trine::Serializer)
object.  This module also includes a command line script `rdfdot` to create
graph diagrams from RDF data.

# CONFIGURATION

- as

Specific serialization format with `dot` as default. Supported formats include
`dot`, `svg`, `png`, and `gif`.

- style

General graph style options as hash reference. Defaults to
`<{ rankdir =` 1, concentrate => 1 }>>.

- node

Hash reference with general options to style nodes. Defaults to
`{ shape => 'plaintext', color => 'gray' }`.

- resource

Hash reference with options to style resource nodes. Defaults to
`<{ shape =` 'box', style => 'rounded', fontcolor => 'blue' }>>.

- literal

Hash reference with options to style literal nodes. Defaults to
`{ shape => 'box' }`.

- blank

Hash reference with options to style blank nodes. Defaults to `<{ label =` '',
shape => 'point', fillcolor => 'white', color => 'gray', width => '0.3' }>>.

- url

Add URLs to nodes. You can either provide a boolean value or a code reference
that returns an URL when given a [RDF::Trine::Node::Resource](http://search.cpan.org/perldoc?RDF::Trine::Node::Resource).

- root

An URI that is marked as 'root' node.

- title

Add a title to the graph.

- mime

Mime type. By default automatically set based on `as`.

# METHODS

This modules derives from [RDF::Trine::Serializer](http://search.cpan.org/perldoc?RDF::Trine::Serializer) with all of its methods. In
addition you can create raw [GraphViz](http://search.cpan.org/perldoc?GraphViz) objects. The following methods are of
interest in particular:

## new ( %options )

Creates a new serializer with [CONFIGURATION](#pod_CONFIGURATION) options.

## media_types

Returns exactely one MIME Type that the serializer is configured for.

## iterator_as_graphviz ( $iterator )

Creates a [GraphViz](http://search.cpan.org/perldoc?GraphViz) object for further processing. This is the core method,
used by all `serialize_...` methods.

## serialize_model_to_file ( $file, $model )

Serialize a [RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) as graph diagram to a file.

## serialize_model_to_string ( $model )

Serialize a [RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) as graph diagram to a string.

## serialize_iterator_to_string ( $iterator, [ %options ] )

Serialize a [RDF::Trine::Iterator](http://search.cpan.org/perldoc?RDF::Trine::Iterator) as graph diagram to a string.

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