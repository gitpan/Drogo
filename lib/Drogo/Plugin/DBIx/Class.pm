package Drogo::Plugin::DBIx::Class;
use strict;

use base qw/DBIx::Class::Schema DBIx::Class::Core/;
use Drogo::Plugin::DBIx::Class::ResultSet;

__PACKAGE__->load_namespaces;

our %CONFIG;

use overload q[""] => sub {
    my $self = shift;

    return ref($self) && ref($self) ne 'Abe::DB::DBObject'
        ? $self->id : $self;

}, fallback => 1;

sub init
{
    my ($class, %params) = @_;

    $class = $params{class} if $params{class};

    $CONFIG{$class}{TABLE_NAME}      = $params{table};
    $CONFIG{$class}{PRIMARY_KEY}     = $params{primary_key};
    $CONFIG{$class}{REFERENCE_TABLE} = $params{references} || {};
    $CONFIG{$class}{OBJECTS}         = $params{objects}    || {};
    $CONFIG{$class}{DEFINITION}      = $params{definition} || [];
    $CONFIG{$class}{NONLOCAL}        = $params{nonlocal};

    $CONFIG{$class}{COLUMNS}         = [];

    push @{$CONFIG{$class}{COLUMNS}}, $_->{key}
        for @{ $params{definition} || [] };

    # reverse mapping
    $CONFIG{$params{table}}          = $class;

    my @columns =
        map { $_->{key} } @{ $params{definition} || [] };

    $class->table($params{table});
    $class->source_name("$class");
    $class->add_columns(@columns);
    $class->set_primary_key($params{primary_key});

    for my $rkey (keys %{ $params{references} || { } })
    {
        my $reference  = $params{references}{$rkey};
        my $local_col  = $reference->{local_column};
        my $remote_col = $reference->{foreign_column};
        {
            no strict 'refs';
            *{"$class\:\:$rkey"} = sub { shift->$local_col(@_) };
        }
    }

    for my $okey (keys %{ $CONFIG{$class}{OBJECTS} || { }})
    {
        my $obj = $CONFIG{$class}{OBJECTS}{$okey};

        {
            no strict 'refs';
            my $def = join('::', $obj, 'deflate');

            $class->inflate_column($okey, {
                inflate => sub { $obj->inflate(shift) },
                deflate => sub { &$def(shift) },
            });
        }
    }

    $class->resultset_class('Abe::DB::DBObject::ResultSet');

    __PACKAGE__->source_registrations->{$class} =
        $class->result_source_instance;
}

sub build_relations
{
    for my $module (keys %CONFIG)
    {
        my $table_conf = $CONFIG{$module};
        next unless ref $table_conf;

        for my $rkey (keys %{ $table_conf->{REFERENCE_TABLE} || { } })
        {
            my $reference  = $table_conf->{REFERENCE_TABLE}{$rkey};
            my $local_col  = $reference->{local_column};
            my $remote_col = $reference->{foreign_column};
            my $table      = $table_conf->{table};

            {
                if ($reference->{has_many})
                {
                    $module->has_many(
                        $rkey, $reference->{class},
                        { "foreign.$remote_col", "self.$local_col" },
                        {
                            cascade_delete => 0,
                            cascade_copy   => 0,
                            cascade_update => 0,
                            accessor       => 'multi',
                        },
                    );
                    $reference->{class}->belongs_to( $remote_col => $module );
                }
                else
                {
                    my $meth = $reference->{might_have} ? 'might_have' : 'has_one';

                    $module->$meth(
                        $local_col, $reference->{class},
                        { "foreign.$remote_col", "self.$local_col" },
                        {
                            cascade_delete => 0,
                            cascade_copy   => 0,
                            cascade_update => 0,
                            accessor       => 'filter',
                        },
                    );
                }
            }
        }
    }
}

=item $self->_nonlocal 

Returns true if nonlocal.

=cut

sub _nonlocal 
{ 
    my $class      = shift; 
    my $class_name = ref $class ? ref $class : $class; 

    return $CONFIG{$class}{NONLOCAL};
}

=item $self->_definition 

Returns the db definition. 

=cut

sub _definition 
{ 
    my $class      = shift; 
    my $class_name = ref $class ? ref $class : $class; 

    return $CONFIG{$class}{DEFINITION};
}

sub as_hashref
{
    my $self = shift;

    return {
        map { $_ => $self->$_ } $self->columns
    };
}

=item $self->id

Return ID.

=cut

sub id 
{ 
    my $self = shift;
    my $pk   = $self->primary_key;
    return $self->$pk;
}

sub primary_key {
    my $self  = shift;
    my $class = ref $self;
    my $pk    = $CONFIG{$class}{PRIMARY_KEY};
    return $pk;
}

sub dbh { shift->result_source->storage->dbh }
sub begin_work     { shift->dbh->do('BEGIN WORK')    }
sub commit_work    { shift->dbh->do('COMMIT WORK')   }
sub rollback_work  { shift->dbh->do('ROLLBACK WORK') }

sub rs
{
    my $self = shift;

    return $self->result_source->resultset;
}

sub get            { shift->rs->get(@_)            }
sub create         { shift->rs->create(@_)         }
sub search         { shift->rs->search(@_)         }
sub search_rs      { shift->rs->search_rs(@_)      }
sub find           { shift->rs->find(@_)           }
sub find_or_create { shift->rs->find_or_create(@_) }

sub model
{
    my ($self, $table) = @_;

    my $source = ref $self eq 'Abe::DB::DBObject' 
        ? $self : $self->result_source->schema;

    die "$table does not exist" unless $CONFIG{$table};

    my $rs  = $source->resultset($CONFIG{$table});
    my $obj = $rs->new({ });

    return $obj;
}

=head1 AUTHOR

    2011 Ohio-Pennsylvania Software, LLC

=cut

1;
