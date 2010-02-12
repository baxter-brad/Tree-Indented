use Test::More tests => 19;
BEGIN { use_ok('Tree::Indented', qw( :all ) ) };

# POD_EXPORTS
BEGIN { use_ok('Tree::Indented', qw( parse_indented_text traverse_tree traverse_tree_simple ) ); }
BEGIN { use_ok('Tree::Indented', qw( :all ) ); }

POD_SYNOPSIS: {{

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
#--- print traverse_tree_simple( tree => $tree );
is( $text, traverse_tree_simple( tree => $tree ), "pod_synopsys: parse_indented_text(text)/traverse_tree_simple(tree)" );
#---

# this should print nested <ul> lists
#--- print traverse_tree( 
my $new_text = traverse_tree( 
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
is( "$new_text\n" , <<_end_, "pod_synopsys: traverse_tree(tree,tags)" );

<ul>
<li>Fagaceae
    <ul>
    <li>Fagus
        <ul>
        <li>Fagus crenata - Japanese Beech</li>
        <li>Fagus engleriana - Chinese Beech</li>
        <li>Fagus grandifolia - American Beech</li>
        </ul></li>
    </ul></li>
<li>Pinaceae
    <ul>
    <li>Pinus
        <ul>
        <li>Pinus clausa - Sand Pine</li>
        <li>Pinus cubensis - Cuban Pine</li>
        <li>Pinus elliottii - Slash Pine</li>
        </ul></li>
    </ul></li>
</ul>
_end_

}}

POD_SUBROUTINES: {{

my $text = <<"__";
Fagaceae
\tFagus
\t\tFagus crenata - Japanese Beech
\t\tFagus engleriana - Chinese Beech
\t\tFagus grandifolia - American Beech
Pinaceae
\tPinus
\t\tPinus clausa - Sand Pine
\t\tPinus cubensis - Cuban Pine
\t\tPinus elliottii - Slash Pine
__

my $tree = parse_indented_text( text => $text, char => "\t", num => 1 );

is( $text, traverse_tree_simple( tree => $tree, tab => "\t" ), "pod_subroutines: parse_indented_text(text,char,num)" );

}}


POD_parse_indented_text_text: {{

my $scalar = <<'__';
l1.1
    l2.1
    l2.2
        l3.1
l1.2
__
my $text = \$scalar;

my $tree = parse_indented_text( text => $text );
is( $scalar, traverse_tree_simple( tree => $tree ), "pod_parse_indented_text_text: parse_indented_text(text)" );

}}


POD_parse_indented_text_char: {{

# tabs are used here
my $text = <<"__";
l1.1
\tl2.1
\tl2.2
\t\tl3.1
l1.2
__

{
    my $tree = parse_indented_text( text => $text, char => "\t", num => 1 );
    is( $text, traverse_tree_simple( tree => $tree, tab => "\t" ), "pod_parse_indented_text_char: parse_indented_text(text,char,num)" );
}
{ local
    $Tree::Indented::Char = "\t";
    my $tree = parse_indented_text( text => $text, num => 1 );
    is( $text, traverse_tree_simple( tree => $tree, tab => "\t" ), "pod_parse_indented_text_char: parse_indented_text(text,num) (Char)" );
}

}}

POD_parse_indented_text_num: {{
my $text = <<'__';
l1.1
  l2.1
  l2.2
    l3.1
l1.2
__
{
    my $tree = parse_indented_text( text => $text, num => 2 );  # two spaces
    is( $text, traverse_tree_simple( tree => $tree, tab => "  " ), "pod_parse_indented_text_num: parse_indented_text(text,num)" );
}

{ local
    $Tree::Indented::Num = 2;
    my $tree = parse_indented_text( text => $text );
    is( $text, traverse_tree_simple( tree => $tree ), "pod_parse_indented_text_num: parse_indented_text(text) (Num)" );
}
}}

POD_parse_indented_text_strict: {{

# l1.2 is uneven
my $text = <<'__';
l1.1
    l2.1
    l2.2
        l3.1
 l1.2
__
{
    eval{
    my $tree = parse_indented_text( text => $text, strict => 1 );
    };
    like( $@, qr/^Uneven/, "pod_parse_indented_text_strict: parse_indented_text(text,strict)" );
}
{ local
    $Tree::Indented::Strict = 1;
    eval {
    my $tree = parse_indented_text( text => $text );
    };
    like( $@, qr/^Uneven/, "pod_parse_indented_text_strict: parse_indented_text(text) (Strict)" );
}

}}

POD_traverse_tree_simple_tree: {{

my $text = <<'__';
l1.1
    l2.1
    l2.2
        l3.1
l1.2
__
    my $tree     = parse_indented_text(  text => $text );
    my $new_text = traverse_tree_simple( tree => $tree );
    is( $new_text, $text, "pod_traverse_tree_simple_tree: traverse_tree_simple(tree)" );

}}

POD_traverse_tree_simple_tab: {{

my $text_in = <<'__';
l1.1
    l2.1
    l2.2
        l3.1
l1.2
__

my $text_out = <<"__";
l1.1
\tl2.1
\tl2.2
\t\tl3.1
l1.2
__

my $tree = parse_indented_text( text => $text_in );

{
    my $new_text = traverse_tree_simple( tree => $tree, tab => "\t" );
    is( $new_text, $text_out, "pod_traverse_tree_simple_tab: traverse_tree_simple(tree,tab)" );
}
{ local
    $Tree::Indented::Char = "\t";
  local
    $Tree::Indented::Num  = 1;
    my $new_text = traverse_tree_simple( tree => $tree );
    is( $new_text, $text_out, "pod_traverse_tree_simple_tab: traverse_tree_simple(tree) (Char,Num)" );
}

}}

POD_traverse_tree_tags: {{

my $text_in = <<'__';
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

my $text_out = <<'__';

<ul>
<li>Fagaceae
    <ul title="Parents: Fagaceae">
    <li title="Parent: Fagaceae">Fagus
        <ul title="Parents: Fagaceae Fagus">
        <li title="Parent: Fagus">Fagus crenata - Japanese Beech</li>
        <li title="Parent: Fagus">Fagus engleriana - Chinese Beech</li>
        <li title="Parent: Fagus">Fagus grandifolia - American Beech</li>
        </ul></li>
    </ul></li>
<li>Pinaceae
    <ul title="Parents: Pinaceae">
    <li title="Parent: Pinaceae">Pinus
        <ul title="Parents: Pinaceae Pinus">
        <li title="Parent: Pinus">Pinus clausa - Sand Pine</li>
        <li title="Parent: Pinus">Pinus cubensis - Cuban Pine</li>
        <li title="Parent: Pinus">Pinus elliottii - Slash Pine</li>
        </ul></li>
    </ul></li>
</ul>
__

my $tree = parse_indented_text( text => $text_in );
    #--- print traverse_tree(
    my $new_text = traverse_tree(
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
    is( "$new_text\n", $text_out, "pod_traverse_tree_tags: traverse_tree(tree,tags)" );

}}

POD_traverse_tree_change: {{

my $text_in = <<'__';
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

my $text_out = <<'__';
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
__

my $tree = parse_indented_text( text => $text_in );

    #--- print traverse_tree(
    my $new_text = traverse_tree(
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
    is( $new_text, $text_out, "pod_traverse_tree_change: traverse_tree(tree,display,change)" );

}}

POD_traverse_tree_display: {{

my $text_in = <<'__';
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

my $text_out = <<'__';
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
__

my $tree = parse_indented_text( text => $text_in );

    #--- print traverse_tree(
    my $new_text = traverse_tree(
        tree => $tree,
        display => sub {
            my( $item, $indent, $parents ) = @_;
            if( my $p = $parents->[-1] ) {
                $item =~ s/\Q$p //;
            }
            "$indent$item\n";
        } 
    );
    is( $new_text, $text_out, "pod_traverse_tree_display: traverse_tree(tree,display)" );
}}

__END__
