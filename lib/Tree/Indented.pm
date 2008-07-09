package Tree::Indented;

use 5.008002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    traverse_tree
    traverse_tree_simple
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    parse_indented_text
);

our $VERSION = '0.01';

=for comment

$tree = parse_indented_text(
    text   => $tree,
    strict => 0,
    );

my %tags = (
    group => {
        begin => sub {
            my( $indent, $parents ) = @_;
            my @p = @$parents;
            my $p = @p? qq' title="Parents: @p"': '';
            "\n$indent<ul$p>\n";
        },
        end => sub { "$_[0]</ul>" },
    },
    item => {
        begin => sub {
            my( $indent, $parents ) = @_;
            my $p = $parents->[-1]||'';
            $p = qq' title="Parent: $p"' if $p;
            "$indent<li$p>";
        },
        end => sub { "</li>\n" },
    },
);

my $complex = traverse_tree( 
    tree => $tree,
    tab       => "    ", 
    tags      => \%tags,
    xchange   => sub{
        my( $item, $indent, $parents ) = @_;
        my $p = @$parents? $parents->[-1]: '';
        "$p/$item"
    },
    xdisplay   => sub{
        my( $item, $indent, $parents ) = @_;
        "$indent$item\n"
    },
    );

my $simple = traverse_tree_simple( tree => $tree );

=cut

#---------------------------------------------------------------------
sub traverse_tree {
    my( %parms ) = @_;
    my( $tree, $tab, $level, $parents, $tags, $display, $change ) = @parms{
    qw(  tree   tab   level   parents   tags   display   change  ) };

    $tree = parse_indented_text( text => $tree ) unless ref $tree;
    return unless @$tree;

    $tab       = " " x 4 unless defined $tab;
    $level   ||= 0;
    my $indent = $tab x $level;

    $parents ||= [];
    $tags    ||= {};

    my @ret;
    for( $tags->{group}{begin} ) {
        push @ret, $_->( $indent, $parents ) if defined }
    
    foreach my $member ( @$tree ) {
        my( $item, $more );
        if( ref $member ) { ( $item, $more ) = @$member }
        else              {            $item =  $member }

        for( $tags->{item}{begin} ) {
            push @ret, $_->( $indent, $parents ) if defined }
        if( $change  ) { $item = $change->( $item, $indent, $parents ) }
        if( $display ) { push @ret, $display->( $item, $indent, $parents ) }
        else           { push @ret, $item }

        push @ret, traverse_tree( 
            tree => $more,
            tab       => $tab, 
            level     => $level+1,
            parents   => [ @$parents, $item ],
            tags      => $tags,
            change    => $change,
            display   => $display,
            ) if $more;

        for( $tags->{item}{end} ) {
            push @ret, $_->( $indent, $parents ) if defined }
    }

    for( $tags->{group}{end} ) {
        push @ret, $_->( $indent, $parents ) if defined }

    join "", @ret;  # returned
}

#---------------------------------------------------------------------
sub traverse_tree_simple {
    my( %parms ) = @_;
    my( $tree, $tab, $level ) = @parms{
    qw(  tree   tab   level ) };

    $tree = parse_indented_text( text => $tree ) unless ref $tree;
    return unless @$tree;

    $tab     ||= " " x 4;
    $level   ||= 0;
    my $indent = $tab x $level;

    my @ret;
    
    foreach my $member ( @$tree ) {
        my( $item, $more );
        if( ref $member ) { ( $item, $more ) = @$member }
        else              {            $item =  $member }

        push @ret, "$indent$item\n";  # <--- item processed here

        push @ret, traverse_tree_simple( 
            tree => $more,
            tab       => $tab, 
            level     => $level+1,
            ) if $more;
    }

    join "", @ret;  # returned
}

#---------------------------------------------------------------------
sub parse_indented_text {
    my( %parms ) = @_;
    my( $text, $char, $num, $strict ) = @parms{
    qw(  text   char   num   strict ) };

    return unless defined $text;

    $char = ' ' unless defined $char;
    $num  = 4   unless $num;

    my @tree;
    my @a = split "\n", $text;

    for my $i ( 0 .. $#a ) {

        my( $indent, $string ) = $a[ $i ] =~ /^($char*)(.*)/;
        my $len   = length( $indent );
        my $extra = $len % $num;
        if( $extra ) {
            die "Uneven indentation, line ".($i+1)." ($a[ $i ])." if $strict;
            $string = ($char x $extra) . $string;
        }

        my( $lookahead ) = $i == $#a ? '': $a[ $i+1 ] =~ /^($char*)/;
        $lookahead = length( $lookahead ) > $len;
        my $level = $len/$num;
        my $dref = \@tree;
        $dref = $dref->[-1][-1] for 1 .. $level;
        push @$dref, $lookahead ? [$string,[]] : $string;

    }

    return \@tree;
}

1;  # return true

__END__

=head1 NAME

Tree::Indented -

=head1 SYNOPSIS

  use Tree::Indented;

=head1 DESCRIPTION

=head1 EXPORT

 parse_indented_text()

=head1 SEE ALSO

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
