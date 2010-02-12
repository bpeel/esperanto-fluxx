#!/usr/bin/perl

use strict;
use warnings;

use Cairo;
use Math::Trig;

my $POINTS_PER_MM = 2.8346457;

my $PAGE_WIDTH = 210;
my $PAGE_HEIGHT = 297;

my $CARD_WIDTH = 56;
my $CARD_HEIGHT = 86;
my $CARD_GAP = 6;

my $PAGE_BORDER = 8;

my $CORNER_RADIUS = 4;

my $INSET = 3;

my $SIDE_TITLE_WIDTH = 8;

my $ACTION_COLOR = [ 61 / 255.0, 193 / 255.0, 185 / 255.0 ];

my $SIDE_GAP = 2;

my $TOP_TITLE_FONT_SIZE = 9;
my $SIDE_TITLE_FONT_SIZE = 6;
my $CENTER_TITLE_FONT_SIZE = 5;

my $SIDE_TITLE_OFFSET_FROM_TOP = 9;

my $TOP_TITLE_HEIGHT = 9;
my $TOP_TITLE_GAP = 2;

my $TOP_PARAGRAPH_HEIGHT = 28;
my $TOP_PARAGRAPH_GAP = 2;
my $CENTER_TITLE_HEIGHT = 5;
my $CENTER_TITLE_GAP = 2;
my $RULE_HEIGHT = 1;
my $RULE_GAP = 2;

my $card_x = $PAGE_BORDER;
my $card_y = $PAGE_BORDER;

sub add_card
{
    my ($cr, $color, $title, $type) = @_;

    $cr->save();

    # Set the origin to the top left of the card
    $cr->translate($card_x, $card_y);

    $cr->new_path();

    # Draw the card outline as a curved rectangle
    $cr->arc($CORNER_RADIUS,
             $CORNER_RADIUS,
             $CORNER_RADIUS,
             pi, pi * 3 / 2);
    $cr->line_to($CARD_WIDTH - $CORNER_RADIUS, 0);
    $cr->arc($CARD_WIDTH - $CORNER_RADIUS,
             $CORNER_RADIUS,
             $CORNER_RADIUS,
             pi * 3 / 2, pi * 2);
    $cr->line_to($CARD_WIDTH, $CARD_HEIGHT - $CORNER_RADIUS);
    $cr->arc($CARD_WIDTH - $CORNER_RADIUS,
             $CARD_HEIGHT - $CORNER_RADIUS,
             $CORNER_RADIUS,
             0, pi / 2);
    $cr->line_to($CORNER_RADIUS, $CARD_HEIGHT);
    $cr->arc($CORNER_RADIUS,
             $CARD_HEIGHT - $CORNER_RADIUS,
             $CORNER_RADIUS,
             pi / 2, pi);
    $cr->close_path();
    $cr->stroke();

    # Draw the background of side title
    $cr->save();
    $cr->set_source_rgb(@$color);
    $cr->rectangle($INSET, $INSET,
                   $SIDE_TITLE_WIDTH,
                   $CARD_HEIGHT - $INSET * 2);
    $cr->fill();
    $cr->restore();

    # Draw the side title
    $cr->set_font_size($SIDE_TITLE_FONT_SIZE);
    my $font_extents = $cr->font_extents();
    my $text_extents = $cr->text_extents(uc($title));
    $cr->move_to($INSET + $SIDE_TITLE_WIDTH / 2 -
                 ($font_extents->{ascent} + $font_extents->{descent}) / 2 +
                 $font_extents->{ascent},
                 $INSET + $SIDE_TITLE_OFFSET_FROM_TOP +
                 $text_extents->{width});
    $cr->save();
    $cr->rotate(pi / -2);
    $cr->show_text(uc($title));
    $cr->restore();

    my $y = $INSET;

    # Draw the top title
    $cr->set_font_size($TOP_TITLE_FONT_SIZE);
    $font_extents = $cr->font_extents();
    $cr->move_to($INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP,
                 $y + $TOP_TITLE_HEIGHT / 2 -
                 ($font_extents->{ascent} + $font_extents->{descent}) / 2 +
                 $font_extents->{ascent});
    $cr->show_text(uc($type));
    $y += $TOP_TITLE_HEIGHT + $TOP_TITLE_GAP;

    # Draw the top paragraph
    # FIXME
    $y += $TOP_PARAGRAPH_HEIGHT + $TOP_PARAGRAPH_GAP;

    # Draw the center title
    $cr->set_font_size($CENTER_TITLE_FONT_SIZE);
    $font_extents = $cr->font_extents();
    $cr->move_to($INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP,
                 $y + $CENTER_TITLE_HEIGHT / 2 -
                 ($font_extents->{ascent} + $font_extents->{descent}) / 2 +
                 $font_extents->{ascent});
    $cr->show_text($title);
    $y += $CENTER_TITLE_HEIGHT + $CENTER_TITLE_GAP;

    # Draw the horizontal rule
    $cr->rectangle($INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP, $y,
                   $CARD_WIDTH - $INSET * 2 - $SIDE_TITLE_WIDTH - $SIDE_GAP,
                   $RULE_HEIGHT);
    $cr->fill();
    $y += $RULE_HEIGHT + $RULE_GAP;

    $cr->restore();

    # Move to the next horizontal card space
    $card_x += $CARD_WIDTH + $CARD_GAP;
    # If this card won't fix then move to the next line
    if ($card_x + $CARD_WIDTH > $PAGE_WIDTH - $PAGE_BORDER * 2)
    {
        $card_x = $PAGE_BORDER;
        $card_y += $CARD_HEIGHT + $CARD_GAP;
        # If this card would go off the end of the page then start a
        # new page
        if ($card_y + $CARD_HEIGHT > $PAGE_HEIGHT - $PAGE_BORDER * 2)
        {
            $cr->show_page();
            $card_y = $PAGE_BORDER;
        }
    }
}

my $surface = Cairo::PdfSurface->create("flux.pdf",
                                        $PAGE_WIDTH * $POINTS_PER_MM,
                                        $PAGE_HEIGHT * $POINTS_PER_MM);

my $cr = Cairo::Context->create($surface);

# Use mm for the units from now on
$cr->scale($POINTS_PER_MM, $POINTS_PER_MM);

# Use ½mm line width
$cr->set_line_width(0.5);

add_card($cr, $ACTION_COLOR, "Go Fiŝ", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
add_card($cr, $ACTION_COLOR, "Go Fish", "Action");
