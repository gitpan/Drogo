package Drogo::Dispatch;

use Exporter;
use strict;

use Drogo;
use Drogo::Dispatcher;
use Drogo::Server::Test;

# Configure exporter.
our @ISA    = qw(Exporter Drogo::Dispatcher);
our @EXPORT = (@Nginx::Simple::HTTP_STATUS_CODES);

our $VERSION = '0.02';

=head1 NAME

Drogo::Dispatch - Who knows what it does, it's a magical box!

usage:

use Drogo::Disaptch ( mapping => {
    'tornado' => 'Tornado::App',
} );

=cut

sub import
{
    my ($class, %params) = @_;
    my $caller = $params{class} || caller;

    # inject a handler method
    {
        no strict 'refs';

        my $caller_isa = "$caller\::ISA";

        @{$caller_isa} = qw(
            Drogo
            Drogo::Dispatcher
        );

        *{"$caller\::handler"} = sub {
            my ($self, %custom_params) = @_;
            my $server_obj = $custom_params{server} || $self;

            return local_dispatch(
                $server_obj,
                class         => $caller,
                app_path      => $params{app_path},
                auto_import   => $params{auto_import},
                auto_redirect => $params{auto_redirect},
                mapping       => $params{mapping},
                %custom_params,
            );
        };
    }

    __PACKAGE__->export_to_level(1, $class);
}

# where do we dispatch to

sub local_dispatch
{
    my ($self, %params) = @_;
    my $class    = $params{class};
    my $app_path = $params{app_path} || '';
    my $path     = $params{uri}      || $self->uri;

    # self should be a server object, if it's not create a fake one
    $self = Drogo::Server::Test->new(%params)
        unless ref $self;

    # trip the app_path off $path, when applicable
    $path =~ s/^$app_path// if $app_path;

    my $dispatch_data = 
        __PACKAGE__->dig_for_dispatch(
            class       => $class,
            path        => $path,
            auto_import => $params{auto_import},
            mapping     => $params{mapping},
        );

    # ensure indexes always end in a slash
    if ($params{auto_redirect} and $dispatch_data->{index} and $path !~ /\/$/)
    {
        $self->status(302);
        $self->header_out(Location => $self->uri . '/');
        $self->send_http_header;

        return;
    }

    if ($dispatch_data->{error} eq 'bad_dispatch')
    {
        return dispatch(
            $self, 
            class  => $class,
            method => 'bad_dispatch',
            bless  => 1,
            psgi   => $params{psgi},
        );
    }
    elsif ($dispatch_data->{error})
    {
        return dispatch(
            $self, 
            class  => $class,
            method => 'error',
            error  => $dispatch_data->{error},
            bless  => 1,
            psgi   => $params{psgi},
        );
    }
    else # prepare to dispatch for real
    {
        return dispatch(
            $self,
            class        => $dispatch_data->{class},
            method       => $dispatch_data->{method},
            base_class   => $class,
            dispatch_url => $dispatch_data->{dispatch_url},
            bless        => 1,
            post_args    => ($dispatch_data->{post_args} || [ ]),
            psgi         => $params{psgi},
        );
    }
}

=head1 COPYRIGHT

Copyright 2011, 2012 Ohio-Pennsylvania Software, LLC.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
