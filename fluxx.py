#!/usr/bin/env python3
#
# Esperanto-fluxx - A script for generating an Esperanto version of Fluxx
# Copyright (C) 2010, 2016  Neil Roberts
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

from gi.repository import Rsvg
from gi.repository import Pango
from gi.repository import PangoCairo
import cairo
import math
import re
import collections

POINTS_PER_MM = 2.8346457

PAGE_WIDTH = 210
PAGE_HEIGHT = 297

CARD_WIDTH = 56
CARD_HEIGHT = 86
CARD_GAP = 6

PAGE_BORDER = 8

CORNER_RADIUS = 4

INSET = 3

SIDE_TITLE_WIDTH = 8
HIGHLIGHT_WIDTH = 0.5

NEW_RULE_COLOR = [ 244 / 255.0, 217 / 255.0, 0 / 255.0 ]
BASIC_RULES_COLOR = [ 255 / 255.0, 97 / 255.0, 27 / 255.0 ]
ACTION_COLOR = [ 35 / 255.0, 184 / 255.0, 220 / 255.0 ]
KEEPER_COLOR = [ 0 / 255.0, 246 / 255.0, 64 / 255.0 ]
GOAL_COLOR = [ 251 / 255.0, 48 / 255.0, 110 / 255.0 ]

SIDE_GAP = 2

TOP_TITLE_FONT_SIZE = 9
SIDE_TITLE_FONT_SIZE = 5.8
CENTER_TITLE_FONT_SIZE = 5

SIDE_TITLE_OFFSET_FROM_TOP = 9

TOP_TITLE_HEIGHT = 9
TOP_TITLE_GAP = 1

RULE_POS = INSET + 37 + 5 + 2
RULE_HEIGHT = 1
RULE_GAP = 2

BOTTOM_PARAGRAPH_GAP = 2

BOTTOM_IMAGE_GAP = 2

IMAGE_WIDTH = 4096
IMAGE_HEIGHT = 4096
IMAGE_CARDS_X = 10
IMAGE_CARDS_Y = 7

keepers = {}
cards = []

def render_paragraph(cr, unit_scale, y, text, font = "Serif 6.5",
                     align_top = False):
    x = INSET + SIDE_TITLE_WIDTH + SIDE_GAP

    cr.save()

    cr.move_to(x, y)

    # Remove the mm scale
    cr.scale(1.0 / unit_scale, 1.0 / unit_scale)

    layout = PangoCairo.create_layout(cr)
    m = re.match(r'(.*?)([0-9]+(\.[0-9]*)?)$', font)
    font_size = float(m.group(2))
    font_size *= unit_scale / POINTS_PER_MM
    font = m.group(1) + str(font_size)
    fd = Pango.FontDescription.from_string(font)
    layout.set_font_description(fd)
    layout.set_width((CARD_WIDTH - x - INSET) * unit_scale
                     * Pango.SCALE)
    layout.set_text(text, -1)

    (ink_rect, logical_rect) = layout.get_pixel_extents()

    if align_top:
        cr.rel_move_to(0, -logical_rect.height)

    PangoCairo.show_layout(cr, layout)

    cr.restore()

    return logical_rect.height / unit_scale

def fit_image(cr, image, x, y, width, height):

    if isinstance(image, collections.Callable):
        image(cr, x, y, width, height)
        return

    scale = 1

    dim = image.get_dimensions()

    if (dim.width / dim.height > width / height):
        # scale to fit the width
        scale = width / dim.width
    else:
        # scale to fit the height
        scale = height / dim.height

    cr.save()

    cr.translate(x + width / 2 - dim.width * scale / 2,
                 y + height / 2 - dim.height * scale / 2)
    cr.scale(scale, scale)
    image.render_cairo(cr)

    cr.restore()

def add_card(**args):
    global cards

    cards.append(args)

def render_outline(cr):
    cr.new_path()

    # Draw the card outline as a curved rectangle
    cr.arc(CORNER_RADIUS,
           CORNER_RADIUS,
           CORNER_RADIUS,
           math.pi, math.pi * 3 / 2)
    cr.line_to(CARD_WIDTH - CORNER_RADIUS, 0)
    cr.arc(CARD_WIDTH - CORNER_RADIUS,
           CORNER_RADIUS,
           CORNER_RADIUS,
           math.pi * 3 / 2, math.pi * 2)
    cr.line_to(CARD_WIDTH, CARD_HEIGHT - CORNER_RADIUS)
    cr.arc(CARD_WIDTH - CORNER_RADIUS,
           CARD_HEIGHT - CORNER_RADIUS,
           CORNER_RADIUS,
           0, math.pi / 2)
    cr.line_to(CORNER_RADIUS, CARD_HEIGHT)
    cr.arc(CORNER_RADIUS,
           CARD_HEIGHT - CORNER_RADIUS,
           CORNER_RADIUS,
           math.pi / 2, math.pi)
    cr.close_path()
    cr.stroke()

def render_card(cr, unit_scale, args):
    cr.save()

    # Draw the background of side title
    if "color" in args:
        cr.save()
        cr.set_source_rgb(*args["color"])
        cr.rectangle(INSET, INSET,
                       SIDE_TITLE_WIDTH,
                       CARD_HEIGHT - INSET * 2)
        cr.fill()
        cr.restore()

    # Draw the side title
    if "title" in args:
        cr.set_font_size(SIDE_TITLE_FONT_SIZE)
        fascent, fdescent, fheight, fxadvance, fyadvance = cr.font_extents()
        width = cr.text_extents(args['title'].upper())[2]

        cr.move_to(INSET + SIDE_TITLE_WIDTH / 2 -
                   (fascent + fdescent) / 2 +
                   fascent,
                   INSET + SIDE_TITLE_OFFSET_FROM_TOP +
                   width)
        cr.save()
        cr.rotate(math.pi / -2)
        cr.show_text(args["title"].upper())
        cr.restore()

    # Draw the side title highlight
    if "side_highlight" in args:
        cr.save()
        cr.set_source_rgb(*args["side_highlight"])
        cr.rectangle(INSET, INSET, HIGHLIGHT_WIDTH,
                     CARD_HEIGHT - INSET * 2)
        cr.rectangle(INSET + SIDE_TITLE_WIDTH - HIGHLIGHT_WIDTH,
                     INSET, HIGHLIGHT_WIDTH,
                     CARD_HEIGHT - INSET * 2)
        cr.fill()
        cr.restore()

    # Render the top icon
    if "icon" in args:
        # Fit into the side bar
        fit_image(cr, args["icon"],
                  INSET, INSET,
                  SIDE_TITLE_WIDTH, SIDE_TITLE_WIDTH)

    y = INSET

    # Draw the top title
    if "type" in args:
        x = INSET + SIDE_TITLE_WIDTH + SIDE_GAP
        max_width = CARD_WIDTH - x - INSET
        scale = 1.0
        title_string = args["type"].upper()

        cr.set_font_size(TOP_TITLE_FONT_SIZE)

        width = cr.text_extents(title_string)[2]

        # If the title is too wide then scale it to fit
        if width > max_width:
            scale = max_width / width

        cr.move_to(x, y)

        cr.save()
        cr.scale(scale, scale)

        fascent, fdescent, fheight, fxadvance, fyadvance = cr.font_extents()
        cr.rel_move_to(0, TOP_TITLE_HEIGHT / 2
                       - (fascent
                          + fdescent) / 2
                       + fascent)
        cr.show_text(title_string)

        cr.restore()

        y += TOP_TITLE_HEIGHT * scale + TOP_TITLE_GAP

    # Draw the top image
    if "top_image" in args:
        image = args["top_image"]
        dim = image.get_dimensions()
        x = INSET + SIDE_TITLE_WIDTH + SIDE_GAP
        max_width = CARD_WIDTH - x - INSET
        scale = max_width / dim.width
        fit_image(cr, image, x, y,
                  max_width, scale * dim.height)
        y += dim.height * scale + TOP_TITLE_GAP

    # Draw the top paragraph
    if "top_paragraph" in args:
        render_paragraph(cr, unit_scale, y, args["top_paragraph"])

    # Draw the center title
    if "title" in args:
        render_paragraph(cr, unit_scale, RULE_POS,
                         args["title"], "Arial Black 11.2", 1)

    y = RULE_POS

    # Draw the horizontal rule
    cr.rectangle(INSET + SIDE_TITLE_WIDTH + SIDE_GAP, y,
                 CARD_WIDTH - INSET * 2 - SIDE_TITLE_WIDTH - SIDE_GAP,
                 RULE_HEIGHT)
    cr.fill()
    y += RULE_HEIGHT + RULE_GAP

    # Draw the bottom paragraph
    if "bottom_paragraph" in args:
        y += render_paragraph(cr, unit_scale, y, args["bottom_paragraph"])
        y += BOTTOM_PARAGRAPH_GAP

    # Draw the bottom images
    if "bottom_images" in args:
        images = args["bottom_images"]
        x = INSET + SIDE_TITLE_WIDTH + SIDE_GAP
        total_gaps = (len(images) - 1) * BOTTOM_IMAGE_GAP
        x_size = (CARD_WIDTH - INSET - x - total_gaps) / len(images)
        y_size = CARD_HEIGHT - INSET - y

        for image in images:
            fit_image(cr, image,
                      x, y,
                      x_size, y_size)

            x += x_size + BOTTOM_IMAGE_GAP

    cr.restore()

def load_image(filename):
    return Rsvg.Handle.new_from_file('images/' + filename)

def make_disallowed_sign(image):
    def func(cr, x, y, width, height):
        # Thickness of the line in the sign
        SIGN_WIDTH = 1.3

        # Draw the image underneath
        fit_image(cr, image, x, y, width, height)

        sign_size = min(width, height)
        radius = sign_size / 2
        angle_offset = math.atan(SIGN_WIDTH / 2.0 / radius)

        cr.save()

        cr.translate(width / 2 + x, height / 2 + y)

        cr.set_source_rgba(0.0, 0.0, 0.0, 0.7)

        cr.arc(0, 0,
                 radius - SIGN_WIDTH,
                 math.pi * 5.0 / 4.0 + angle_offset,
                 math.pi / 4.0 - angle_offset)
        cr.close_path()

        cr.new_sub_path()
        cr.arc(0, 0,
                 radius - SIGN_WIDTH,
                 math.pi / 4.0 + angle_offset,
                 math.pi * 5.0 / 4.0 - angle_offset)
        cr.close_path()

        cr.new_sub_path()
        cr.arc_negative(0, 0,
                          radius,
                          2 * math.pi, 0)

        cr.fill()

        cr.restore()

    return func

def add_basic_rules():
    icon = load_image('basic-rules.svg')
    image = load_image('scary-hand.svg')

    add_card(color = NEW_RULE_COLOR,
             title = 'Prenu 1, Ludu 1',
             type = 'Bazaj Reguloj',
             top_image = image,
             top_paragraph =
             'Por komenci, miksi la kartaron kaj disdoni po 3 kartojn '
             'al ĉiu ludanto. Metu ĉi tiun karton en la mezo de la tablo.',
             bottom_paragraph =
             "Je via vico:\nPrenu 1 karton.\nLudu 1 karton.\n\n"
             "Ĉi tiu karto restu sur la tablo eĉ se novaj reguloj "
             "anstataŭigas la bazajn regulojn.",
             side_highlight = BASIC_RULES_COLOR,
             icon = icon)

def add_action_card(title, description, icon):

    add_card(color = ACTION_COLOR,
             title = title,
             type = "Ago",
             top_paragraph = ('Kiam vi ludus tiun ĉi karton, faru tion, '
                              'kio estas skribita, kaj poste metu ĝin '
                              'sur la forĵetstaplon.'),
             bottom_paragraph = description,
             icon = icon)

def add_actions():

    icon = load_image("action.svg")

    title = None
    description = ""
    fin = open("actions.txt", mode='r', encoding='utf-8')

    for line in fin:
        line = line.rstrip()

        title_match = re.match(r':(.*)', line)
        if title_match:
            if title:
                add_action_card(title, description, icon)
                description = ""
            title = title_match.group(1)
        elif title and re.search(r'.', line):
            if len(description) > 0:
                description += " "
            description += line
    fin.close()

    if title:
        add_action_card(title, description, icon)

def add_keepers():
    icon = load_image("keeper.svg")

    fin = open("keepers.txt", mode='r', encoding='utf-8')
    for line in fin:
        line = line.rstrip()

        m = re.match(r'(.+):(.+)$', line)
        if m:
            keeper = { 'image': load_image(m.group(1)),
                       'name': m.group(2) }
            # Generate a shortname using the last word of the name
            name_match = re.search(r'(\w+)$', line)
            # Store the keeper data in a hash indexed by the short
            # name so we can letter to refer to it for the goals
            keepers[name_match.group(1).lower()] = keeper

            add_card(type = "Tenaĵo",
                     title = keeper['name'],
                     icon = icon,
                     color = KEEPER_COLOR,
                     top_paragraph = ('Kiam vi ludas tiun ĉi karton, '
                                      'metu ĝin sur la tablon, antaŭ vi, '
                                      'montrante la facon.'),
                     bottom_images = [ keeper['image'] ])

    fin.close()

def add_rules():
    icon = load_image('basic-rules.svg')

    fin = open("rules.txt", mode='r', encoding='utf-8')

    for line in fin:
        line = line.rstrip()

        m = re.match(r'(.+):(.+):(.+)$', line)

        if m:
            image = load_image(m.group(1))
            name = m.group(2)
            desc = m.group(3)

            add_card(type = 'Regulo',
                     title = name,
                     icon = icon,
                     color = NEW_RULE_COLOR,
                     top_paragraph = ('Kiam vi ludus tiun ĉi karton, '
                                      'metu ĝin en la mezo de la tablo. '
                                      'Forigu regulojn, kiujn '
                                      'ĉi tiu karto kontraŭas. La regulo '
                                      'tuj validas.'),
                     bottom_images = [image],
                     bottom_paragraph = desc)

def parse_keeper(keeper_name):

    keeper_match = re.match(r'(!?)(.*)$', keeper_name)
    inverted = len(keeper_match.group(1)) > 0
    keeper_name = keeper_match.group(2)

    if keeper_name not in keepers:
        raise Exception('Unknown keeper \"{}\"'.format(keeper_name))
    keeper = keepers[keeper_name]

    # Copy the keeper hash
    keeper = keeper.copy()
    keeper["inverted"] = inverted

    return keeper

def add_goals():
    icon = load_image("goal.svg")

    fin = open("goals.txt", mode='r', encoding='utf-8')

    for line in fin:
        line = line.rstrip()

        m = re.match(r'(@)?(.+?):(.+?):(.+?)(?::(.+))?$', line)
        if m:
            special_goal = m.group(1)
            name = m.group(2)

            if special_goal:
                images = [ load_image(m.group(3)) ]
                note = m.group(4)
            else:
                goal_keepers = list(map(parse_keeper,
                                        [ m.group(3), m.group(4) ]))
                note = m.group(5)

                if not note:
                    goal_parts = ' '.join(map(lambda x: "kaj " +
                                              x["name"] + "n",
                                              goal_keepers))
                    note = ("Ludanto venkas, kiu havas " + goal_parts + " "
                            "sur la tablo.")

                images = list(map(lambda x:
                                  make_disallowed_sign(x["image"]) if
                                  x["inverted"] else x["image"],
                                  goal_keepers))

            add_card(type = 'Celo',
                     title = name,
                     icon = icon,
                     color = GOAL_COLOR,
                     top_paragraph = ('Kiam vi ludas ĉi tiun karton, metu '
                                      'ĝin en la mezo de la tablo, '
                                      'montrante la facon. Forĵetu iun '
                                      'ajn antaŭan Celon.'),
                     bottom_paragraph = note,
                     bottom_images = images)

    fin.close()

add_basic_rules()
add_actions()
add_keepers()
add_goals()
add_rules()

# Make a PDF version of the cards

surface = cairo.PDFSurface("esperantofluxx.pdf",
                           PAGE_WIDTH * POINTS_PER_MM,
                           PAGE_HEIGHT * POINTS_PER_MM)

cr = cairo.Context(surface)

# Use mm for the units from now on
cr.scale(POINTS_PER_MM, POINTS_PER_MM)

# Use ½mm line width
cr.set_line_width(0.5)

card_x = PAGE_BORDER
card_y = PAGE_BORDER

for card in cards:
    cr.save()
    cr.translate(card_x, card_y)

    render_outline(cr)
    render_card(cr, POINTS_PER_MM, card)

    # Move to the next horizontal card space
    card_x += CARD_WIDTH + CARD_GAP
    # If this card won't fit then move to the next line
    if card_x + CARD_WIDTH > PAGE_WIDTH - PAGE_BORDER * 2:
        card_x = PAGE_BORDER
        card_y += CARD_HEIGHT + CARD_GAP
        # If this card would go off the end of the page then start a
        # new page
        if card_y + CARD_HEIGHT > PAGE_HEIGHT - PAGE_BORDER * 2:
            cr.show_page()
            card_y = PAGE_BORDER

    cr.restore()

# Make a PNG version of the cards suitable for Tabletop Simulator
card_num = 0
cr = None
surfaces = []

card_pixel_width = IMAGE_WIDTH / IMAGE_CARDS_X
card_pixel_height = IMAGE_HEIGHT / IMAGE_CARDS_Y

if CARD_WIDTH / CARD_HEIGHT > card_pixel_width / card_pixel_height:
    units_scale = card_pixel_width / CARD_WIDTH
else:
    units_scale = card_pixel_height / CARD_HEIGHT

pixel_off_x = card_pixel_width / 2 - CARD_WIDTH * units_scale / 2
pixel_off_y = card_pixel_height / 2 - CARD_HEIGHT * units_scale / 2

for card_num in range(0, len(cards)):
    card = cards[card_num]

    card_num_in_image = card_num % (IMAGE_CARDS_X * IMAGE_CARDS_Y)

    if card_num_in_image == 0:
        surface = cairo.ImageSurface(cairo.FORMAT_RGB24,
                                     IMAGE_WIDTH, IMAGE_HEIGHT)
        surfaces.append(surface)
        cr = cairo.Context(surface)
        cr.save()
        cr.set_source_rgb(1, 1, 1)
        cr.paint()
        cr.restore()

    cr.save()
    cr.translate(card_num_in_image % IMAGE_CARDS_X * card_pixel_width +
                 pixel_off_x,
                 card_num_in_image // IMAGE_CARDS_X * card_pixel_height +
                 pixel_off_y)
    cr.scale(units_scale, units_scale)
    render_card(cr, units_scale, card)
    cr.restore()

for surface_num in range(0, len(surfaces)):
    surface = surfaces[surface_num]
    surface.write_to_png("esperantofluxx-{:02d}.png".format(surface_num))
