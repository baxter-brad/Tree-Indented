#---------------------------------------------------------------------
package Tree::Indented;

use 5.008002;
use strict;
use warnings;

#---------------------------------------------------------------------

=head1 NAME

Tree::Indented - a module to parse indented text into a simple tree
structure

=cut

#---------------------------------------------------------------------

=head1 VERSION

VERSION: 1.00

=cut

our $VERSION = '1.00'; $VERSION = eval $VERSION;

#---------------------------------------------------------------------

=head1 EXPORTS

Nothing is exported by default.  The following may be exported
individually; all three may be exported using the C<:all> tag.

 parse_indented_text()
 traverse_tree_simple()
 traverse_tree()

 use Tree::Indented qw( parse_indented_text traverse_tree );
 use Tree::Indented qw( :all );

=cut

our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );

BEGIN {
    require Exporter;
    @ISA       = qw( Exporter );
    @EXPORT_OK = qw(
        parse_indented_text
        traverse_tree_simple
        traverse_tree
        );
    %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
}

# package globals
our $Strict  = 0  ;  # default is false
our $Char    = ' ';  # default is one space
our $Num     = 4  ;  # default is four spaces

# default comments:
# - blank lines
# - lines with only whitespace
# - lines that start with '#' or ';' after optional whitespace.
our $Comment = qr/^\s*(?:[#;]|$)/;

#---------------------------------------------------------------------

=head1 SYNOPSIS

    use Tree::Indented qw( :all );
    
    # indented text
    my $text = <<'__';
    Fagaceae
        Fagus
            Fagus crenata - Japanese Beech
            Fagus engleriana - Chinese Beech
            Fagus grandifolia - American Beech
    Pinaceae
        Pinus
            Pinus clausa - Sand Pine
            Pinus cubensis - Cuban Pine
            Pinus elliottii - Slash Pine
    __
    
    # create a tree structure (nested arrays)
    my $tree = parse_indented_text( text => $text );

    # this should print the same indented text as above
    print traverse_tree_simple( tree => $tree );
    
    # this should print nested <ul> lists
    print traverse_tree( 
        tree => $tree,
        # defines begin/end tags for groups and items:
        tags => {
            group => {  # $_[0] is the indentation string
                begin => sub { "\n$_[0]<ul>\n" },
                end   => sub { "$_[0]</ul>"    },
            },
            item => {
                begin => sub { "$_[0]<li>" },
                end   => sub { "</li>\n"   },
            },
        },
    );

=cut

#---------------------------------------------------------------------

=head1 DESCRIPTION

This module is designed to provide a simple way of dealing with
indented text as a tree structure, where a more-indented line of text
is considered a child of the less-indented line above it.

=cut

#---------------------------------------------------------------------

=head1 SUBROUTINES

Descriptions and parameters for the exportable subroutines are detailed
below.

Note that all parameters must be passed as named parameters (hash
references are not supported in this version), e.g.,

    my $tree = parse_indented_text( text => $text, char => "\t", num => 1 );

=head2 parse_indented_text()

This routine creates a tree structure from indented text.  It returns
an array reference that will normally include many nested arrays.

A note about newline:

Currently, the newline character C<"\n"> (in the intented text that is
passed to this routine) is special: it always marks the end of a line
of text.

A note about comments:

If $Tree::Indented::Comment is true, it is expected to be a regular
expression that defines a comment line.

By default, it is C<< qr/^\s*(?:[#;]|$)/ >>, so a blank line, a line
containing only whitespace, or a line beginning with C<#> or C<;>
(after optional whitespace) is a comment.

Setting this to a false value will make the routine treat every line as
data--no comments recognized.  Or you can set it to whatever regular
expression you want.

    $Tree::Indented::Comment = qr/^#/;  # stricter comment marker
    my $tree = parse_indented_text( text => $text );

Finally, comments are not retained in the tree structure, so
traverse_tree_simple() will not include them in its output.

=head3 Parameters:

=over 6

=item text

A string or scalar reference to a string that contains indented text.

    my $tree = parse_indented_text( text => $text );

=item char

The indentation character (typically a space or a tab)--default is one
space.  This character x the C<num> parameter will be the indentation
string for each level.

    my $tree = parse_indented_text( text => $text, char => "\t", num => 1 );

You may set $Tree::Indented::Char to change the default.

    $Tree::Indented::Char = "\t";
    my $tree = parse_indented_text( text => $text, num => 1 );

=item num

The number of indentation characters that make up the indentation
string per level of the structure--default is 4, meaning, normally,
four spaces per level.

    my $tree = parse_indented_text( text => $text, num => 2 );  # two spaces

You may set $Tree::Indented::Num to change the default.

    $Tree::Indented::Num = 2;
    my $tree = parse_indented_text( text => $text );

=item strict

A boolean value that determines if badly indented text will cause the
subroutine to die.  The default is false, i.e., badly indented text is
accepted;

If a line begins with more indentation characters than expected, and
C<strict> is false, the extra indentation characters are simply considered
part of the value of that line.  But if C<strict> is true, the subroutine
will die.

    my $tree = parse_indented_text( text => $text, strict => 1 );

Be aware that the default value of false for C<strict> means that the
routine will not die even for pathologically badly indented text, but
the resulting tree in those cases may not be what you expect.

You may set $Tree::Indented::Strict to change the default.

    $Tree::Indented::Strict = 1;
    my $tree = parse_indented_text( text => $text );

=back

=cut

#---------------------------------------------------------------------
sub parse_indented_text {
    my( %parms ) = @_;
    my( $text, $char, $num, $strict ) = @parms{
    qw(  text   char   num   strict ) };

    return            unless defined $text;
    $char   = $Char   unless defined $char;
    $num    = $Num    unless $num;
    $strict = $Strict unless defined $strict;

    my @tree;
    my @a = split "\n", (ref $text? $$text: $text);

    my $level = 0;
    for my $i ( 0 .. $#a ) {

        my $line = $a[ $i ];
        next if $Comment and $line =~ /$Comment/;

        my( $indent, $string ) = $line =~ /^($char*)(.*)/;
        my $len = length( $indent );
        my $extra;
        if( $len/$num > $level + 1 ) {
            $extra = $len - ($num * ($level + 1)) }
        else {
            $extra = $len % $num }
        if( $extra ) {
            die "Uneven indentation, line ".($i+1)." ($line)." if $strict;
            $string = ($char x $extra) . $string;
            $len   -= $extra;
        }
        die "No value, line ".($i+1) if $string eq '' and $strict;

        my( $lookahead ) = $i == $#a ? '': $a[ $i+1 ] =~ /^($char*)/;
        $lookahead = length( $lookahead ) > $len;
        $level = $len/$num;
        my $dref = \@tree;
        $dref = $dref->[-1][-1] for 1 .. $level;
        push @$dref, $lookahead ? [$string,[]] : $string;

    }

    return \@tree;
}

#---------------------------------------------------------------------

=head2 traverse_tree_simple()

This routine traverses a tree to form indented text.  It should be
considered the opposite of parse_indented_text(), i.e., the indented
text that traverse_tree_simple() returns should be parsable by
parse_indented_text() (with proper values for C<char>, C<num>, and C<tab>).

Additionally, the code in this routine may be used as a template for
traversing a tree if neither traverse_tree_simple() nor traverse_tree()
meets your needs.  This implies that the structure of the tree used by
this module is not expected to change, and it's not.

=head3 Parameters:

=over 6

=item tree

This parameter must be a tree structure generated by
parse_indented_text().

    my $tree     = parse_indented_text(  text => $text );
    my $new_text = traverse_tree_simple( tree => $tree );

=item tab

This parameter is the string used to indent each level of text.  The
default is four spaces, which corresponds to the default C<char> and
C<num> parameters in parse_indented_text().

You may ask why it's C<char> and C<num> for one routine and C<tab> for
the other.  Good question. :-) Short answer: the code is simpler this
way.

    my $new_text = traverse_tree_simple( tree => $tree, tab => "\t" );

You may set $Tree::Indented::Char and $Tree::Indented::Num to
change the default for C<tab>.

    $Tree::Indented::Char = "\t";
    $Tree::Indented::Num  = 1;
    my $new_text = traverse_tree_simple( tree => $tree );

=item level

This parameter is an integer that indicates the level we're at.  You
should not pass this--it's used by traverse_tree_simple() itself as it
recurses through the tree.

=back

=cut

#---------------------------------------------------------------------
sub traverse_tree_simple {
    my( %parms ) = @_;
    my( $tree, $tab, $level ) = @parms{
    qw(  tree   tab   level ) };

    $tree = parse_indented_text( text => $tree ) unless ref $tree;
    return unless @$tree;

    $tab       = $Char x $Num unless defined $tab;
    $level   ||= 0;
    my $indent = $tab x $level;

    my @ret;
    
    foreach my $member ( @$tree ) {
        my( $item, $more );
        if( ref $member ) { ( $item, $more ) = @$member }
        else              {            $item =  $member }

        push @ret, "$indent$item\n";  # <--- item processed here

        push @ret, traverse_tree_simple( 
            tree  => $more,
            tab   => $tab, 
            level => $level + 1,
            ) if $more;
    }

    join "", @ret;  # returned
}

#---------------------------------------------------------------------

=head2 traverse_tree()

This routine traverses a tree to form more complex output.  It allows
you to define C<begin> and C<end> tags for each C<item> and each
C<group> (a C<group> is a parent plus its children), and to define
C<change> and C<display> routines to be called for each item.

It also passes along all of an item's parents as it recurses through
the tree.

By the way, to make traverse_tree() produce the same output as
traverse_tree_simple(), pass the following C<display> value:

    my $new_text = traverse_tree(
        tree    => $tree,
        display => sub { "$_[1]$_[0]\n" } 
        );

=head3 Parameters:

=over 6

=item tree, tab, level

These are the same parameters described above for
traverse_tree_simple(), and the same rule applies for C<level>--you
shouldn't pass it.

=item tags

This parameter is a hash reference.  The hash should have two keys,
C<group> and C<item>, and each of their values should be a hash with
two keys, C<begin> and C<end>.  The values for C<begin> and C<end>
should be subroutine references (most likely anonymous subs) that are
callbacks.

As the routine recurses through the tree, each item and each group will
be surrounded by the C<begin> and C<end> subroutines' return values.
These subroutines will expect to get the current indentation string
(C<tab> x C<level>) and the current parents.

The example in the SYNOPSIS shows an example C<tags> hash that
outputs a tree as a set of nested <ul> lists.  Below is a more
complex version that also adds information about parents as
C<title> attributes.

    print traverse_tree(
        tree => $tree,
        tags => {
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
        },
    );

=item change

This parameter is also a callback, i.e., a subroutine reference, and it
expects to get the item value, the indentation string, and the current
parents.

The item value will be I<replaced> with the return value of this
callback (and will then be passed to the C<display> callback if
present).

The following example removes the immediate parent's value from the
beginning of each item.

    print traverse_tree(
        tree => $tree,
        display => sub { "$_[1]$_[0]\n" },
        change => sub {
            my( $item, $indent, $parents ) = @_;
            if( my $p = $parents->[-1] ) {
                $item =~ s/\Q$p //;
            }
            $item;  # don't forget to return this
        } 
    );

Output using the text in the SYNOPSIS:

    Fagaceae
        Fagus
            crenata - Japanese Beech
            engleriana - Chinese Beech
            grandifolia - American Beech
    Pinaceae
        Pinus
            clausa - Sand Pine
            cubensis - Cuban Pine
            elliottii - Slash Pine

=item display

This parameter is also a callback, i.e., a subroutine reference, and it
also expects to get the item value, the indentation string, and the
current parents.

The return value of this callback will be added (instead of the item
value) to the string that traverse_tree_simple() is building as its
return value.

The following example produces the same output as above.

    print traverse_tree(
        tree => $tree,
        display => sub {
            my( $item, $indent, $parents ) = @_;
            if( my $p = $parents->[-1] ) {
                $item =~ s/\Q$p //;
            }
            "$indent$item\n";
        } 
    );

You might wonder: What's the difference between C<change> and
C<display>, since they both affect the value added to the overall
return value?  The answer is: parents.  When you supply a C<change>
callback, the item value is changed not only in the overall return
value, but also in the list of parents associated with each child.  The
C<display> callback will not affect the list of parents.

=item parents

This parameter is an array reference to a list of the current item's
parents (and grandparents, etc.)  This list contains the actual item
values found as the tree is traversed (though the values may have been
changed by a C<change> callback).

This parameter is like C<level>, it is passed along as the subroutine
recurses, and you should not pass it (though I suppose you could if
you wanted everything to start with a particular "root" parent value).

=back

=cut

#---------------------------------------------------------------------
sub traverse_tree {
    my( %parms ) = @_;
    my( $tree, $tab, $level, $parents, $tags, $display, $change ) = @parms{
    qw(  tree   tab   level   parents   tags   display   change  ) };

    $tree = parse_indented_text( text => $tree ) unless ref $tree;
    return unless @$tree;

    $tab     = $Char x $Num unless defined $tab;
    $level ||= 0;

    my $indent   = $tab x $level;

    $parents ||= [];
    $tags    ||= {};

    my @ret;
    for( $tags->{group}{begin} ) {  # XXX autovivication--do we care?
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

    for( $tags->{group}{end} ) {  # XXX autovivication--do we care?
        push @ret, $_->( $indent, $parents ) if defined }

    join "", @ret;  # returned
}

1;  # return true

#---------------------------------------------------------------------

=head1 AUTHOR, COPYRIGHT, AND LICENSE

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

Copyright (C) 2010 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

__END__
