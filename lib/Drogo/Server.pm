package Drogo::Server;
use strict;

my %SERVER_VARIABLES;

sub initialize { }
sub cleanup    { }
sub post_limit { shift->variable('post_limit') || 1_048_576 }

=head1 NAME

Drogo::Server - Shared methods for server implementations

=cut

=head1 COPYRIGHT

Copyright 2011, 2012 Ohio-Pennsylvania Software, LLC.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
