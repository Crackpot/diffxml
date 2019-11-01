#!/usr/bin/env perl
use strict;
use warnings;

use XML::Twig;

my $xml = XML::Twig -> new -> parsefile ('sample.xml');

sub compare_elements {
   ## perl sort uses $a and $b to compare.
   ## in this case, it's nodes we expect;

   #tag is the node name.
   my $compare_by_tag = $a -> tag cmp $b -> tag;
   #conditional return - this works because cmp returns zero
   #if the values are the same.
   return $compare_by_tag if $compare_by_tag;

   #bit more complicated - extract all the attributes of both a and b, and then compare them sequentially:
   #This is to handle case where you've got mismatched attributes.
   #this may be irrelevant based on your input.
   my %all_atts;
   foreach my $key ( keys %{$a->atts}, keys %{$b->atts}) {
      $all_atts{$key}++;
   }
   #iterate all the attributes we've seen - in either element.
   foreach my $key_to_compare ( sort keys %all_atts ) {

      #test if this attribute exists. If it doesn't in one, but does in the other, then that gets sorted to the top.
      my $exists = ($a -> att($key_to_compare) ? 1 : 0) <=> ($b -> att($key_to_compare) ? 1 : 0);
      return $exists if $exists;

      #attribute exists in both - extract value, and compare them alphanumerically.
      my $comparison =  $a -> att($key_to_compare) cmp $b -> att($key_to_compare);
      return $comparison if $comparison;
   }
   #we have fallen through all our comparisons, we therefore assume the nodes are the same and return zero.
   return 0;
}

#recursive sort - traverses to the lowest node in the tree first, and then sorts that, before
#working back up.
sub sort_children {
   my ( $node ) = @_;
   foreach my $child ( $node -> children ) {
      #sort this child if is has child nodes.
      if ( $child -> children ) {
         sort_children ( $child )
      }
   }

   #iterate each of the child nodes of this one, sorting based on above criteria
      foreach my $element ( sort { compare_elements } $node -> children ) {

         #cut everything, then append to the end.
         #because we've ordered these, then this will work as a reorder operation.
         $element -> cut;
         $element -> paste ( last_child => $node );
      }
}

#set off recursive sort.
sort_children ( $xml -> root );

#set output formatting. indented_a implicitly sorts attributes.
$xml -> set_pretty_print ( 'indented_a');
$xml -> print;
