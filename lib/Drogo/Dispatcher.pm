package Drogo::Dispatcher;

use base qw(
    Exporter
    Drogo::Dispatcher::Attributes
);

use strict;

our @EXPORT = qw(dig_for_dispatch);

# keep a list of dispatched paths
my %path_cache;

=head1 NAME 

Drogo::Dispatcher

=head1 Synopsis

Automatic dispatcher built on code attributes.

=head1 Methods

=cut

sub dig_for_dispatch
{
    my ($self, %params) = @_;
    my $class        = $params{class};
    my $path         = $params{path};
    my $mapping      = $params{mapping} || {};
    my $called_path  = $path || $params{called_path}; # the complete path
    my $dispatch_url = $params{dispatch_url} || '';
    my $trailing     = $params{trailing} || [];  # unmatched trailing arguments

    # reset self
    $self = $params{self} if $params{self};

    # dereference class
    $class = ref $class ? ref $class : $class;

    # check cache (for fast dispatches)
    return $path_cache{"${class}::${called_path}"}
        if $path_cache{"${class}::${called_path}"};

    # change the class, if applicable to the mapping table
    for my $new_class (keys %$mapping)
    {
        if ($new_class eq $path or 
            $path =~ /^$new_class\//)
        {
            $class = $mapping->{$new_class};
            $path  =~ s/^$new_class//;
        }
    }

    # sanitize path
    {
        # remove starting slash
        $path =~ s/^\///;

        # remove trailing slash
        $path =~ s/\/+$//;

        # remove index trailing (you can't call index directly)
        $path =~ s/(\/|^)index$//;

        # append 'index' if no path given
        $path .= 'index' unless $path;
    }

    # build list of paths
    my @paths = split('/', $path);

    # build method call
    my $call_class   = $class;
    my $method       = pop @paths;
    my $remote_class = $class;
       $remote_class = join('::', $class, join('::', @paths))
           if @paths;

    &_class_is_imported($remote_class) if $params{auto_import};

    if (UNIVERSAL::can($remote_class, 'get_dispatch_flags'))
    {
        my $methods    = $remote_class->get_dispatch_flags;
        my $used_index = 0;

        # if this is a page index, find the index sub name
        if ($method eq 'index')
        {
            ($method) = grep { $methods->{$_} eq 'index' } keys %$methods;
            $used_index = 1;
        }

        if ($methods->{$method})
        {
            # perform dispatch
            {
                no strict 'refs'; # evil
                my $subptr = join('::', $remote_class, $method);

                # store path in cache
                $path_cache{"${class}::${called_path}"} = {
                    class        => $remote_class,
                    method       => $method,
                    sub          => \&$subptr,
                    index        => $used_index,
                    dispatch_url => join('/', $dispatch_url, $path),
                };

                return $path_cache{"${class}::${called_path}"};
            }
        }
        else
        {
            # attempt to jump forward
            {
                my $jump_class = join('::', $remote_class, $method);

                &_class_is_imported($jump_class) if $params{auto_import};
                if (UNIVERSAL::can($jump_class, 'get_dispatch_flags'))
                {
                    return $jump_class->dig_for_dispatch(
                        self         => $self,
                        class        => $jump_class,
                        path         => '',
                        called_path  => $called_path,
                        dispatch_url => $path,
                    );
                }
            }

            return { error => 'bad_dispatch' };
        }
    }
    else # get_dispatch_flags is not assessable
    {
        # attempt to jump backward
        {
            my @jump_paths = @paths;
            my @post_args  = ($method);

            while (@jump_paths)
            {
                my $method     = pop @jump_paths;
                my $jump_class = join('::', $class, @jump_paths);

                if (UNIVERSAL::can($jump_class, 'get_dispatch_flags'))
                {
                    my $dispatch_flags = $jump_class->get_dispatch_flags;

                    if ($dispatch_flags->{$method} and
                        $dispatch_flags->{$method} eq 'action_match')
                    {
                        my $subptr = join('::', $jump_class, $method);

                        return {
                            class        => $jump_class,
                            method       => $method,
                            sub          => \&$subptr,
                            index        => 0,
                            dispatch_url => $called_path,
                            post_args    => \@post_args,
                        };
                    }
                }
                unshift @post_args, $method;
            }
        }

        return { error => 'bad_dispatch' };
    }
}

# _class_is_imported(Some::Class)
#
# If a class is not imported, import it.
#

sub _class_is_imported
{
    my $class = shift;

    (my $class_file = $class) =~ s{::}{/}g;
    $class_file .= '.pm'; # Let's assume all class files end in .pm

    if (not exists $INC{$class_file})
    {
        for my $base_path (@INC)
        {
            my $full_path = join('/', $base_path, $class_file);
            
            if (-e $full_path)
            {
                eval qq{use $class;};
                warn "-->$@<--" if $@;
                return;
            }
        }        
    }
}

=head1 COPYRIGHT

Copyright 2011, 2012 Ohio-Pennsylvania Software, LLC.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

