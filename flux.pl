#!/usr/bin/perl

use strict;
use warnings;

use Cairo;
use Math::Trig;
use Gnome2::Rsvg;
use Pango;

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

my $BOTTOM_PARAGRAPH_GAP = 2;

my $card_x = $PAGE_BORDER;
my $card_y = $PAGE_BORDER;

sub render_paragraph
{
    my ($cr, $y, $text) = @_;

    my $x = $INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP;

    $cr->move_to($x, $y);

    $cr->save();

    # Remove the mm scale
    $cr->scale(1.0 / $POINTS_PER_MM, 1.0 / $POINTS_PER_MM);

    my $layout = Pango::Cairo::create_layout($cr);
    my $fd = Pango::FontDescription->from_string("Serif 6.5");
    $layout->set_font_description($fd);
    $layout->set_width(($CARD_WIDTH - $x - $INSET) * $POINTS_PER_MM
                       * Pango->scale);
    $layout->set_text($text);
    Pango::Cairo::show_layout($cr, $layout);

    $cr->restore();

    my ($ink_rect, $logical_rect) = $layout->get_pixel_extents();

    return $logical_rect->{height} / $POINTS_PER_MM;
}

sub add_card
{
    my ($cr, %args) = @_;

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
    if ($args{color})
    {
        $cr->save();
        $cr->set_source_rgb(@{$args{color}});
        $cr->rectangle($INSET, $INSET,
                       $SIDE_TITLE_WIDTH,
                       $CARD_HEIGHT - $INSET * 2);
        $cr->fill();
        $cr->restore();
    }

    # Draw the side title
    if ($args{title})
    {
        $cr->set_font_size($SIDE_TITLE_FONT_SIZE);
        my $font_extents = $cr->font_extents();
        my $text_extents = $cr->text_extents(uc($args{title}));
        $cr->move_to($INSET + $SIDE_TITLE_WIDTH / 2 -
                     ($font_extents->{ascent} + $font_extents->{descent}) / 2 +
                     $font_extents->{ascent},
                     $INSET + $SIDE_TITLE_OFFSET_FROM_TOP +
                     $text_extents->{width});
        $cr->save();
        $cr->rotate(pi / -2);
        $cr->show_text(uc($args{title}));
        $cr->restore();
    }

    # Render the top icon
    if ($args{icon})
    {
        # Fit into the side bar
        $cr->save();
        $cr->translate($INSET, $INSET);
        $cr->scale($SIDE_TITLE_WIDTH / 100.0, $SIDE_TITLE_WIDTH / 100.0);
        $args{icon}->render_cairo($cr);
        $cr->restore();
    }

    my $y = $INSET;

    # Draw the top title
    if ($args{type})
    {
        $cr->set_font_size($TOP_TITLE_FONT_SIZE);
        my $font_extents = $cr->font_extents();
        $cr->move_to($INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP,
                     $y + $TOP_TITLE_HEIGHT / 2 -
                     ($font_extents->{ascent} + $font_extents->{descent}) / 2 +
                     $font_extents->{ascent});
        $cr->show_text(uc($args{type}));
    }
    $y += $TOP_TITLE_HEIGHT + $TOP_TITLE_GAP;

    # Draw the top paragraph
    if ($args{top_paragraph})
    {
        render_paragraph($cr, $y, $args{top_paragraph});;
    }

    $y += $TOP_PARAGRAPH_HEIGHT + $TOP_PARAGRAPH_GAP;

    # Draw the center title
    if ($args{title})
    {
        $cr->set_font_size($CENTER_TITLE_FONT_SIZE);
        my $font_extents = $cr->font_extents();
        $cr->move_to($INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP,
                     $y + $CENTER_TITLE_HEIGHT / 2 -
                     ($font_extents->{ascent} + $font_extents->{descent}) / 2 +
                     $font_extents->{ascent});
        $cr->show_text($args{title});
    }
    $y += $CENTER_TITLE_HEIGHT + $CENTER_TITLE_GAP;

    # Draw the horizontal rule
    $cr->rectangle($INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP, $y,
                   $CARD_WIDTH - $INSET * 2 - $SIDE_TITLE_WIDTH - $SIDE_GAP,
                   $RULE_HEIGHT);
    $cr->fill();
    $y += $RULE_HEIGHT + $RULE_GAP;

    # Draw the bottom paragraph
    if ($args{bottom_paragraph})
    {
        $y += render_paragraph($cr, $y, $args{bottom_paragraph});
        $y += $BOTTOM_PARAGRAPH_GAP;
    }

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

sub svg_size_cb
{
    # Let's just fix the size of all of the svgs to 100,100 so we can
    # scale it to the right size later
    return (100, 100);
}

sub load_image
{
    my ($filename) = @_;

    my $rsvg = Gnome2::Rsvg::Handle->new();
    $rsvg->set_size_callback(\&svg_size_cb);
    my $fin;

    open($fin, $filename) or die("failed opening '$filename'");

    while (my $line = <$fin>)
    {
        $rsvg->write($line) or die("Couldn't parse '$filename'");
    }

    close($fin);

    $rsvg->close();

    return $rsvg;
}

my $surface = Cairo::PdfSurface->create("flux.pdf",
                                        $PAGE_WIDTH * $POINTS_PER_MM,
                                        $PAGE_HEIGHT * $POINTS_PER_MM);

my $cr = Cairo::Context->create($surface);

# Use mm for the units from now on
$cr->scale($POINTS_PER_MM, $POINTS_PER_MM);

# Use ½mm line width
$cr->set_line_width(0.5);

my $rsvg = load_image("action.svg");

add_card($cr,
         color => $ACTION_COLOR,
         title => "Go Fish",
         type => "Action",
         top_paragraph => "When you play this card, do whatever it says.",

         bottom_paragraph => "Name a card. If someone has that card in "
         . "their hand, they must give it to you. If no one does, draw a "
         . "card. In either case, if you got the card you requested, you "
         . "get to play it immediately.",

         icon => $rsvg);
