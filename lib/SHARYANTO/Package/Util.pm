package SHARYANTO::Package::Util;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       package_exists
                       list_package_contents
                       list_subpackages
               );

our $VERSION = '0.56'; # VERSION

sub package_exists {
    no strict 'refs';

    my $pkg = shift;

    return unless $pkg =~ /\A\w+(::\w+)*\z/;
    if ($pkg =~ s/::(\w+)\z//) {
        return !!${$pkg . "::"}{$1 . "::"};
    } else {
        return !!$::{$pkg . "::"};
    }
}

# XXX incomplete/improper
sub list_package_contents {
    no strict 'refs';

    my $pkg = shift;

    return () unless !length($pkg) || package_exists($pkg);
    my $symtbl = \%{$pkg . "::"};

    my %res;
    while (my ($k, $v) = each %$symtbl) {
        next if $k =~ /::$/; # subpackage
        my $n;
        if ("$v" !~ /^\*/) {
            # constant
            $res{$k} = $v;
            next;
        }
        if (defined *$v{CODE}) {
            $res{$k} = *$v{CODE}; # subroutine
            $n++;
        }
        if (defined *$v{HASH}) {
            $res{"\%$k"} = \%{*$v}; # hash
            $n++;
        }
        if (defined *$v{ARRAY}) {
            $res{"\@$k"} = \@{*$v}; # array
            $n++;
        }
        if (defined(*$v{SCALAR}) # XXX always defined?
                && defined(${*$v})) { # currently we filter undef values
            $res{"\$$k"} = \${*$v}; # scalar
            $n++;
        }

        if (!$n) {
            $res{"\*$k"} = $v; # glob
        }
    }

    %res;
}

sub list_subpackages {
    no strict 'refs';

    my ($pkg, $recursive, $cur_res, $ref_mem) = @_;

    return () unless !length($pkg) || package_exists($pkg);

    # this is used to avoid deep recursion. for example (the only one?) %:: and
    # %main:: point to the same thing.
    $ref_mem //= {};

    my $symtbl = \%{$pkg . "::"};
    return () if $ref_mem->{"$symtbl"}++;

    my $res = $cur_res // [];
    for (sort keys %$symtbl) {
        next unless s/::$//;
        my $name = (length($pkg) ? "$pkg\::" : "" ) . $_;
        push @$res, $name;
        list_subpackages($name, 1, $res, $ref_mem) if $recursive;
    }

    @$res;
}

1;
# ABSTRACT: Package-related utilities

__END__

=pod

=encoding utf-8

=head1 NAME

SHARYANTO::Package::Util - Package-related utilities

=head1 VERSION

version 0.56

=head1 SYNOPSIS

 use SHARYANTO::Package::Util qw(
     package_exists
     list_package_contents
     list_subpackages
 );

 print "Package Foo::Bar exists" if package_exists("Foo::Bar");
 my %content   = list_package_contents("Foo::Bar");
 my @subpkg    = list_subpackages("Foo::Bar");
 my @allsubpkg = list_subpackages("Foo::Bar", 1); # recursive

=head1 DESCRIPTION

=head2 package_exists($name) => BOOL

Return true if package "exists". By "exists", it means that the package has been
defined by C<package> statement or some entries have been created in the symbol
table (e.g. C<$Foo::var = 1;> will make the C<Foo> package "exist").

This function can be used e.g. for checking before aliasing one package to
another. Or to casually check whether a module has been loaded.

=head2 list_package_contents($name) => %res

Return a hash containing package contents. For example:

 (
     sub1  => \&Foo::Bar::sub1,
     sub2  => \&Foo::Bar::sub2,
     '%h1' => \%Foo::Bar::h1,
     '@a1' => \@Foo::Bar::a1,
     ...
 )

This module won't list subpackages. Use list_subpackages() for that.

=head2 list_subpackages($name[, $recursive]) => @res

List subpackages, e.g.:

 (
     "Foo::Bar::Baz",
     "Foo::Bar::Qux",
     ...
 )

If $recursive is true, will also list subpackages of subpackages, and so on.

=head1 FAQ

=head2 How to list all existing packages?

You can recurse from the top, e.g.:

 list_subpackages("", 1);

=head1 SEE ALSO

L<perlmod>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 FUNCTIONS


None are exported by default, but they are exportable.

=cut
