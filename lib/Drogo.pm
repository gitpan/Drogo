package Drogo;
use strict;
our $VERSION = '0.10';

=head1 NAME

Drogo - Lightweight web framework

=head1 SYNOPSIS

Kick-start a project: drogo --create=[projectname]

or

app.psgi:

   use Drogo::Server::PSGI;
   use Example::App;

   my $app = sub {
       my $env = shift;

       return sub {
           my $respond = shift;

           # create new server object
           my $server = Drogo::Server::PSGI->new( env => $env, respond => $respond );

           Example::App->handler( server  => $server );
       }
   };

Example/App.pm:

   package Example::App;
   use strict;

   use Drogo::Dispatch( auto_import => 1 );

   sub init
   {
       my $self = shift;

       $self->{foo} = 'bar';
   }

   sub primary :Index
   {
       my $self = shift;

       # $self->r is a shared response/requet object
       # $self->request/req gives a request object
       # $self->response/res gives a response object
       # $self->dispatcher returns drogo object
       # $self->server is a server object

       $self->r->header('text/html'); # default
       $self->r->status(200); # defaults to 200 anyways

       $self->r->print('Welcome!');
       $self->r->print(q[Go here: <a href="/moo">Mooville</a>]);
   }

   # referenced by /foo
   sub foo :Action
   {
       my $self = shift;
       my $stuff = $self->r->param('stuff');

       $self->r->print('Howdy!');
   }

   sub stream_this :Action
   {
       my $self = shift;

       # stop dispatcher
       $self->dispatcher->dispatching(0);

       $self->server->header_out('ETag' => 'fakeetag');
       $self->server->header_out('Cache-Control' => 'public, max-age=31536000');
       $self->server->send_http_header('text/html');
       $self->server->print('This was directly streamed');
   }

   # referenced by /moo/whatever
   sub moo :ActionMatch
   {
       my $self = shift;
       my @args = $self->r->matches;

       $self->r->print('Howdy: ' . $args[0]);
   }

   # referenced by /king/whatever/snake/whatever
   sub beavers :ActionRegex('king/(.*)/snake/(.*)')
   {
       my $self = shift;
       my @args = $self->matches;

       $self->r->print("roar: $args[0], $args[1]");
   }
}

=cut

=head1 COPYRIGHT

Copyright 2011, 2012 Ohio-Pennsylvania Software, LLC.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
