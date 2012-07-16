package Drogo::Dispatcher::Request;

use Drogo;
use strict;

sub new 
{
    my $class = shift;
    my $self = {};
    bless($self);
    return $self;
}

=head3 $self->uri

Returns the uri.

=cut

sub uri { Drogo::uri(@_) }


=head3 $self->header_in

Return value of header_in.

=cut

sub header_in { Drogo::header_in(@_) }

=head3 $self->request_body & $self->request
    
Returns request body.

=cut

sub request_body { Drogo::request_body(@_) }
sub request { Drogo::request(@_) }

=head3 $self->request_method

Returns the request_method.

=cut

sub request_method   { Drogo::request_method(@_) }


=head3 $self->matches

Returns array of post_arguments (matching path after a matched ActionMatch attribute)
Returns array of matching elements when used with ActionRegex.

=cut

sub matches   { Drogo::matches(@_) }

=head3 $self->param(...)

Return a parameter passed via CGI--works like CGI::param.

=cut

sub param { Drogo::param(@_) }

=head3 $self->param_hash
    
Return a friendly hashref of CGI parameters.

=cut

sub param_hash { Drogo::param_hash(@_) }

=head1 COPYRIGHT

Copyright 2011, 2012 Ohio-Pennsylvania Software, LLC.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
