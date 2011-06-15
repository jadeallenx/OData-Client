use strict;
use warnings;
package OData::Client;

use Atompub::Client;
use XML::Atom;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use URI;
use Data::Printer;

=head1 SYNOPSIS

  use OData::Client;

  my $client = OData::Client->new(
  	namespace_root => 'ODataDemo',
	service_uri    => 'http://services.odata.org/OData/OData.svc',
    );

  $client->collection[0]->entry[0]->dump();

=cut

has 'namespace_root' => (
	is	=> 'ro',
	isa => 'Str',
	required => 1,
	);

has 'service_url' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	);

has 'collection_factory' => (
	is => 'rw',
	isa => 'OData::Client::CollectionFactory',
	);

has 'collections' => (
	traits => ['Array'],
	is => 'rw',
	isa => 'ArrayRef[Object]',
	default => sub { [] },
	handles => { 
		add_collection => 'push', 
		next_collection => 'shift',
		},
	);

sub BUILD {
	my $self = shift;

	my $atompub_client = Atompub::Client->new();

	my $service_document = $atompub_client->getService($self->service_url) or
		die "Couldn't get a service document from " . $self->service_url;
	
	my @workspaces = $service_document->workspaces;

	$self->collection_factory(OData::Client::CollectionFactory->new);

	if ( scalar @workspaces == 1 ) {
		$self->_build_collections($workspaces[0]->collections);
		return $self;
	}
	else {
		# XXX FIXME
		foreach my $workspace ( @workspaces ) {
			if ( $workspace->title eq "Default" ) {
				$self->_build_collections($workspace->collections);
				return $self;
			}
		}
		die "No default workspace was found.";
	}
}

sub _build_collections {
	my $self = shift;

	foreach my $collection ( @_ ) {
		my $collection_object =
			$self->collection_factory->create(
				$self->namespace_root,
				$self->service_url, 
				$collection
			);

		$self->add_collection($collection_object);
	}
}

sub dump_collections {
	my $self = shift;

	foreach my $collection ( @{ $self->collections } ) {
		p $collection;
	}
}

1;
