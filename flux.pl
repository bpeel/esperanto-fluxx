#!/usr/bin/perl
#
# Esperanto-fluxx - A script for generating an Esperanto version of Fluxx
# Copyright (C) 2010  Neil Roberts
# Copyright (C) 2010  Thomas Preece
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use Cairo;
use Math::Trig;
use Gnome2::Rsvg;
use Pango;
use utf8;

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
my $HIGHLIGHT_WIDTH = 0.5;

my $NEW_RULE_COLOR = [ 244 / 255.0, 217 / 255.0, 0 / 255.0 ];
my $BASIC_RULES_COLOR = [ 255 / 255.0, 97 / 255.0, 27 / 255.0 ];
my $ACTION_COLOR = [ 35 / 255.0, 184 / 255.0, 220 / 255.0 ];
my $KEEPER_COLOR = [ 0 / 255.0, 246 / 255.0, 64 / 255.0 ];
my $GOAL_COLOR = [ 251 / 255.0, 48 / 255.0, 110 / 255.0 ];

my $SIDE_GAP = 2;

my $TOP_TITLE_FONT_SIZE = 9;
my $SIDE_TITLE_FONT_SIZE = 5.8;
my $CENTER_TITLE_FONT_SIZE = 5;

my $SIDE_TITLE_OFFSET_FROM_TOP = 9;

my $TOP_TITLE_HEIGHT = 9;
my $TOP_TITLE_GAP = 1;

my $RULE_POS = $INSET + 37 + 5 + 2;
my $RULE_HEIGHT = 1;
my $RULE_GAP = 2;

my $BOTTOM_PARAGRAPH_GAP = 2;

my $BOTTOM_IMAGE_GAP = 2;

my $card_x = $PAGE_BORDER;
my $card_y = $PAGE_BORDER;

my %keepers;

sub render_paragraph
{
    my ($cr, $y, $text, $font, $align_top) = @_;

    my $x = $INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP;

    $font ||= "Serif 6.5";

    $cr->save();

    $cr->move_to($x, $y);

    # Remove the mm scale
    $cr->scale(1.0 / $POINTS_PER_MM, 1.0 / $POINTS_PER_MM);

    my $layout = Pango::Cairo::create_layout($cr);
    my $fd = Pango::FontDescription->from_string($font);
    $layout->set_font_description($fd);
    $layout->set_width(($CARD_WIDTH - $x - $INSET) * $POINTS_PER_MM
                       * Pango->scale);
    $layout->set_text($text);

    my ($ink_rect, $logical_rect) = $layout->get_pixel_extents();

    if ($align_top)
    {
        $cr->rel_move_to(0, -$logical_rect->{height});
    }

    Pango::Cairo::show_layout($cr, $layout);

    $cr->restore();

    return $logical_rect->{height} / $POINTS_PER_MM;
}

sub fit_image
{
    my ($cr, $image, $x, $y, $width, $height) = @_;

    if (ref($image) eq "CODE")
    {
        &$image($cr, $x, $y, $width, $height);
        return;
    }

    my $scale = 1;

    my $dim = $image->get_dimensions();

    if ($dim->{width} / $dim->{height} > $width / $height)
    {
        # scale to fit the width
        $scale = $width / $dim->{width};
    }
    else
    {
        # scale to fit the height
        $scale = $height / $dim->{height};
    }

    $cr->save();

    $cr->translate($x + $width / 2 - $dim->{width} * $scale / 2,
                   $y + $height / 2 - $dim->{height} * $scale / 2);
    $cr->scale($scale, $scale);
    $image->render_cairo($cr);

    $cr->restore();
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

    # Draw the side title highlight
    if ($args{side_highlight})
    {
        $cr->save();
        $cr->set_source_rgb(@{$args{side_highlight}});
        $cr->rectangle($INSET, $INSET, $HIGHLIGHT_WIDTH,
                       $CARD_HEIGHT - $INSET * 2);
        $cr->rectangle($INSET + $SIDE_TITLE_WIDTH - $HIGHLIGHT_WIDTH,
                       $INSET, $HIGHLIGHT_WIDTH,
                       $CARD_HEIGHT - $INSET * 2);
        $cr->fill();
        $cr->restore();
    }

    # Render the top icon
    if ($args{icon})
    {
        # Fit into the side bar
        fit_image($cr, $args{icon},
                  $INSET, $INSET,
                  $SIDE_TITLE_WIDTH, $SIDE_TITLE_WIDTH);
    }

    my $y = $INSET;

    # Draw the top title
    if ($args{type})
    {
        my $x = $INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP;
        my $max_width = $CARD_WIDTH - $x - $INSET;
        my $scale = 1.0;
        my $title_string = uc($args{type});

        $cr->set_font_size($TOP_TITLE_FONT_SIZE);

        my $text_extents = $cr->text_extents($title_string);

        # If the title is too wide then scale it to fit
        if ($text_extents->{width} > $max_width)
        {
            $scale = $max_width / $text_extents->{width};
        }

        $cr->move_to($x, $y);

        $cr->save();
        $cr->scale($scale, $scale);

        my $font_extents = $cr->font_extents();
        $cr->rel_move_to(0, $TOP_TITLE_HEIGHT / 2
                         - ($font_extents->{ascent}
                            + $font_extents->{descent}) / 2
                         + $font_extents->{ascent});
        $cr->show_text($title_string);

        $cr->restore();

        $y += $TOP_TITLE_HEIGHT * $scale + $TOP_TITLE_GAP;
    }

    # Draw the top image
    if ($args{top_image})
    {
        my $image = $args{top_image};
        my $dim = $image->get_dimensions();
        my $x = $INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP;
        my $max_width = $CARD_WIDTH - $x - $INSET;
        my $scale = $max_width / $dim->{width};
        fit_image($cr, $image, $x, $y,
                  $max_width, $scale * $dim->{height});
        $y += $dim->{height} * $scale + $TOP_TITLE_GAP;
    }

    # Draw the top paragraph
    if ($args{top_paragraph})
    {
        render_paragraph($cr, $y, $args{top_paragraph});;
    }

    # Draw the center title
    if ($args{title})
    {
        render_paragraph($cr, $RULE_POS,
                         $args{title}, "Arial Black 11.2", 1);
    }

    $y = $RULE_POS;

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

    # Draw the bottom images
    if ($args{bottom_images})
    {
        my $images = $args{bottom_images};
        my $x = $INSET + $SIDE_TITLE_WIDTH + $SIDE_GAP;
        my $total_gaps = (@$images - 1) * $BOTTOM_IMAGE_GAP;
        my $x_size = ($CARD_WIDTH - $INSET - $x - $total_gaps) / @$images;
        my $y_size = $CARD_HEIGHT - $INSET - $y;

        foreach my $image (@$images)
        {
            fit_image($cr, $image,
                      $x, $y,
                      $x_size, $y_size);

            $x += $x_size + $BOTTOM_IMAGE_GAP;
        }
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

sub load_image
{
    my $filename = 'images/' . shift;

    my $rsvg = Gnome2::Rsvg::Handle->new();

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

sub make_disallowed_sign
{
    my ($image) = @_;

    return sub
    {
        my ($cr, $x, $y, $width, $height) = @_;
        # Thickness of the line in the sign
        my $SIGN_WIDTH = 1.3;

        # Draw the image underneath
        fit_image($cr, $image, $x, $y, $width, $height);

        my $sign_size = $width < $height ? $width : $height;
        my $radius = $sign_size / 2;
        my $angle_offset = atan($SIGN_WIDTH / 2.0 / $radius);

        $cr->save();

        $cr->translate($width / 2 + $x, $height / 2 + $y);

        $cr->set_source_rgba(0.0, 0.0, 0.0, 0.7);

        $cr->arc(0, 0,
                 $radius - $SIGN_WIDTH,
                 pi * 5.0 / 4.0 + $angle_offset,
                 pi / 4.0 - $angle_offset);
        $cr->close_path();

        $cr->new_sub_path();
        $cr->arc(0, 0,
                 $radius - $SIGN_WIDTH,
                 pi / 4.0 + $angle_offset,
                 pi * 5.0 / 4.0 - $angle_offset);
        $cr->close_path();

        $cr->new_sub_path();
        $cr->arc_negative(0, 0,
                          $radius,
                          2 * pi, 0);

        $cr->fill();

        $cr->restore();
    };
}

sub add_basic_rules
{
    my ($cr) = @_;

    my $icon = load_image('basic-rules.svg');
    my $image = load_image('scary-hand.svg');

    add_card($cr,
             color => $NEW_RULE_COLOR,
             title => 'Prenu 1, Ludu 1',
             type => 'Bazaj Reguloj',
             top_image => $image,
             top_paragraph =>
             'Por komenci, miksi la kartaron kaj disdoni po 3 kartojn '
             . 'al ĉiu ludanto. Metu ĉi tiun karton en la mezo de la tablo.',
             bottom_paragraph =>
             "Je via vico:\nPrenu 1 karton.\nLudu 1 karton.\n\n"
             . "Ĉi tiu karto restu sur la tablo eĉ se novaj reguloj "
             . "anstataŭigas la bazajn regulojn.",
             side_highlight => $BASIC_RULES_COLOR,
             icon => $icon);
}

sub add_action_card
{
    my ($cr, $title, $description, $icon) = @_;

    add_card($cr,
             color => $ACTION_COLOR,
             title => $title,
             type => "Ago",
             top_paragraph => ('Kiam vi ludus tiun ĉi karton, faru tion, '
                               . 'kio estas skribita, kaj poste metu ĝin '
                               . 'sur la forĵetstaplon.'),
             bottom_paragraph => $description,
             icon => $icon);
}

sub add_actions
{
    my ($cr) = @_;

    my $icon = load_image("action.svg");

    my $title = "";
    my $description = "";
    my $fin;

    open($fin, "<:encoding(UTF-8)", "actions.txt")
        or die("Error opening actions.txt");
    while (my $line = <$fin>)
    {
        chomp($line);

        if ($line =~ /^:(.*)/)
        {
            if ($title)
            {
                add_action_card($cr, $title, $description, $icon);
                $description = "";
            }
            $title = $1;
        }
        elsif ($title && $line =~ /./)
        {
            $description .= " " if ($description);
            $description .= $line;
        }
    }
    close($fin);

    if ($title)
    {
        add_action_card($cr, $title, $description, $icon);
        $description = "";
    }
}

sub add_keepers
{
    my ($cr) = @_;
    my $icon = load_image("keeper.svg");
    my $fin;

    open($fin, "<:encoding(UTF-8)", "keepers.txt")
        or die("Error opening keepers.txt");
    while (my $line = <$fin>)
    {
        chomp($line);

        if ($line =~ /^(.+):(.+)$/)
        {
            my $keeper = { image => load_image($1),
                           name => $2 };
            # Generate a shortname using the last word of the name
            $keeper->{name} =~ /([[:alpha:]]+)$/;
            # Store the keeper data in a hash indexed by the short
            # name so we can letter to refer to it for the goals
            $keepers{lc($1)} = $keeper;

            add_card($cr,
                     type => "Tenaĵo",
                     title => $keeper->{name},
                     icon => $icon,
                     color => $KEEPER_COLOR,
                     top_paragraph => ('Kiam vi ludas tiun ĉi karton, '
                                       . 'metu ĝin sur la tablon, antaŭ vi, '
                                       . 'montrante la facon.'),
                     bottom_images => [ $keeper->{image} ]);
        }
    }
    close($fin);
}

sub add_rules
{
    my ($cr) = @_;
    my $icon = load_image('basic-rules.svg');
    my $fin;

    open($fin, "<:encoding(UTF-8)", "rules.txt")
        or die("Error opening rules.txt");

    while (<$fin>)
    {
        chomp;
        if ($_ =~ /^(.+):(.+):(.+)$/)
        {
            my $image = load_image($1);
            my $name = $2;
            my $desc = $3;

            add_card($cr,
                     type => 'Regulo',
                     title => $name,
                     icon => $icon,
                     color => $NEW_RULE_COLOR,
                     top_paragraph => ('Kiam vi ludus tiun ĉi karton, '
                                       . 'metu ĝin en la mezo de la tablo. '
                                       . 'Forĵetu antaŭajn regulojn, kiujn '
                                       . 'ĉi tiu karto kontraŭdiras. La regulo '
                                       . 'tuj validas.'),
                     bottom_images => [$image],
                     bottom_paragraph => $desc);
        }
    }
}

sub parse_keeper
{
    my ($keeper_name) = @_;

    $keeper_name =~ /^(!?)(.*)$/;
    my $inverted = $1 ? 1 : 0;
    $keeper_name = $2;

    my $keeper = $keepers{$keeper_name};
    die("Unknown keeper \"$keeper_name\"") unless defined($keeper);

    # Copy the keeper hash
    $keeper = { %$keeper };
    $keeper->{inverted} = $inverted;

    return $keeper;
}

sub add_goals
{
    my ($cr) = @_;
    my $icon = load_image("goal.svg");
    my $fin;

    open($fin, "<:encoding(UTF-8)", "goals.txt")
        or die("Error opening goals.txt");
    while (my $line = <$fin>)
    {
        chomp($line);

        if ($line =~ /^(@)?(.+?):(.+?):(.+?)(?::(.+))?$/)
        {
            my $special_goal = $1;
            my $name = $2;
            my $images;
            my $note;

            if (defined($special_goal))
            {
                $images = [ load_image($3) ];
                $note = $4;
            }
            else
            {
                my @goal_keepers = map(parse_keeper($_), $3, $4);
                $note = $5;

                unless (defined($note))
                {
                    my $goal_parts = join(' ', map("kaj " . $_->{name} . "n",
                                                   @goal_keepers));
                    $note = ("Ludanto venkas, kiu havas $goal_parts "
                             . "sur la tablo.");
                }

                $images = [ map($_->{inverted}
                                ? make_disallowed_sign($_->{image})
                                : $_->{image},
                                @goal_keepers) ];
            }

            add_card($cr,
                     type => 'Celo',
                     title => $name,
                     icon => $icon,
                     color => $GOAL_COLOR,
                     top_paragraph => ('Kiam vi ludas ĉi tiun karton, metu '
                                       . 'ĝin en la mezo de la tablo, '
                                       . 'montrante la facon. Forĵetu iun '
                                       . 'ajn antaŭan Celon.'),
                     bottom_paragraph => $note,
                     bottom_images => $images);
        }
    }
    close($fin);
}

my $surface = Cairo::PdfSurface->create("esperantofluxx.pdf",
                                        $PAGE_WIDTH * $POINTS_PER_MM,
                                        $PAGE_HEIGHT * $POINTS_PER_MM);

my $cr = Cairo::Context->create($surface);

# Use mm for the units from now on
$cr->scale($POINTS_PER_MM, $POINTS_PER_MM);

# Use ½mm line width
$cr->set_line_width(0.5);

add_basic_rules($cr);
add_actions($cr);
add_keepers($cr);
add_goals($cr);
add_rules($cr);
