use strict;
use warnings;

use utf8;
use Test::More;

use RDF::Trine qw(iri statement literal blank variable);
use RDF::Trine::Model;

my $model = RDF::Trine::Model->new;
$model->add_statement(
    statement( blank('x1'), iri('u:ri'), literal('データ') )
);

use RDF::Trine::Exporter::GraphViz;

my $g = RDF::Trine::Exporter::GraphViz->new( as => 'dot' );

my $dot = $g->serialize_model_to_string( $model );
like $dot, qr/digraph/, "dot format";

# print $dot;

#$model = RDF::Trine::Model->new;
#$model->add_statement(
#    statement( blank('x1'), iri('u:ri'), variable('foo') )
#);
#$model->add_statement(
#    statement( blank('x1'), iri('u:rv'), iri('bar:z') )
#);	
#$model->add_statement(
#    statement( iri('bar:z'), iri('x:y'), literal('bla') )
#);	
#$dot = $g->serialize_model_to_string( $model );
#$g = RDF::Trine::Exporter::GraphViz->new( as => 'png' );
#open(my $fh, '>', 'test.png');
#$dot = $g->serialize_model_to_file( $fh, $model );
#print $dot;

done_testing;
