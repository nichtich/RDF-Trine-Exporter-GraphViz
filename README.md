# NAME

RDF::Trine::Serializer::GraphViz - Serialize RDF graphs as dot graph diagrams

# VERSION

version 0.001

# SYNOPSIS

  use RDF::Trine::Serializer::GraphViz;
 

  my $ser = RDF::Trine::Serializer->new( 'graphviz', as => 'dot' );
  my $dot = $ser->serialize_model_to_string( $model );

# DESCRIPTION

[RDF::Trine::Model](http://search.cpan.org/perldoc?RDF::Trine::Model) includes a nice but somehow misplaced and non-customizable
method `as_graphviz`. This module puts it into an object for serialization.  

# AUTHOR

Jakob Voß <voss@gbv.de>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.