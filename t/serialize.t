use strict;
use warnings;

use utf8;
use Test::More;

use RDF::Trine qw(iri statement literal blank);
use RDF::Trine::Model;

my $model = RDF::Trine::Model->new;
$model->add_statement(
    statement( blank('x1'), iri('u:ri'), literal('データ') )
);

use RDF::Trine::Serializer::GraphViz;

my $g = RDF::Trine::Serializer->new( 'graphviz', as => 'dot' );

my $dot = $g->serialize_model_to_string( $model );
like $dot, qr/digraph/, "dot format";

print $dot;

done_testing;
