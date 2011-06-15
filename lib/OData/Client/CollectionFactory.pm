package OData::Client::CollectionFactory;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use OData::Client::EntryFactory;

has 'factory' => (
	is => 'rw',
	isa => 'Object',
	predicate => 'has_factory',
	);

sub _setup {
	my $self = shift;
	my $namespace = shift;

	my $metaclass = Moose::Meta::Class->create($namespace);
	$metaclass->add_attribute('collection_namespace', {
		is => 'ro',
		isa => 'Str',
		required => 1,
		} );

	$metaclass->add_attribute('collection_url', {
		is => 'ro',
		isa => 'Str',
		required => 1,
		} );

	$metaclass->add_attribute('entry_factory', {
		is => 'rw',
		isa => 'Object',
		} );

	$metaclass->add_attribute('entries', {
		traits => ['Array'],
		is => 'rw',
		isa => 'Object',
		default => sub { [] },
		handles => {
			add_entry => 'push',
			next_entry => 'shift',
			},
		} );
	
	return $metaclass;
}

sub _build_url {
	my $self = shift;
	my $service_url = shift;
	my $collection_url = shift;

	if ( $collection_url ~~ /^\// ) {
		# collection URL starts with a / - absolute
		return $collection_url;
	}
	else {
		return $service_url . "/" . $collection_url;
	}
}

sub create {
	my $self = shift;
	my $namespace_root = shift;
	my $service_url = shift;
	my $atompub_collection = shift;

	my $namespace = $namespace_root . "::" . $atompub_collection->title;

	unless ( $self->has_factory ) {
		$self->factory( $self->_setup( $namespace ) );
	}

	my $collection = $self->factory->new_object();

	$collection->collection_namespace($namespace);

	$collection->collection_url(
		$self->_build_url(
			$service_url,
			$atompub_collection->href 
			) 
	);

	$collection->entry_factory(
		OData::Client::EntryFactory->new()
	);

	return $collection;

}

1;
