package Foo;
use Drogo::Dispatch;
use strict;
use Foo::bar;

sub index :Index
{
    my $self = shift;

    $self->print('howdy friend');
}

sub beaver :Action { shift->print('unicorns') }

sub waffle :ActionMatch
{
    my $self = shift;
    $self->print(join('/', $self->post_args));
}

sub error        { shift->status(404) }
sub bad_dispatch { shift->error       }

1;
