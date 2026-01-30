1. Color System

The palette is high-contrast, relying on a deep, authoritative blue against clean whites and light greys.

Usage	Color Name	Approximate Hex	Flutter Code
Primary Brand	ZUS Royal Blue	#1A2B56 or #2B3A7E	Color(0xFF2B3A7E)
Accent/Action	Bright Blue	#4169E1	Color(0xFF4169E1)
Background	Off-White / Catskill	#F4F6F8	Color(0xFFF4F6F8)
Surface (Cards)	Pure White	#FFFFFF	Colors.white
Text (Primary)	Dark Navy / Black	#0D152D	Color(0xFF0D152D)
Text (Secondary)	Cool Grey	#9EA5B5	Color(0xFF9EA5B5)
Dev Note: Do not use Colors.black. ZUS uses a very dark navy (#0D152D) for text, which is softer on the eyes than pure black (#000000).


2. Typography

ZUS balances a "Premium" feel (Serif) with a "Tech" feel (Sans-Serif).

Headlines (The "Coffee" Feel):

Font: Spectral (or a similar Serif like Playfair Display).

Usage: Used sparingly for major campaign titles or the "ZUS Coffee" logo text.

Style: FontWeight.w700, usually in the Primary Brand Blue.

UI Elements (The "App" Feel):

Font: Helvetica Neue (iOS) / Roboto or Inter (Android).

Usage: Menus, prices, buttons, and descriptions.

Style: Clean, geometric sans-serif.

Body Text: typically 14sp (scaled pixels).

Price Tags: typically FontWeight.bold to make them pop.


3. Icongraphy

The icons are designed to feel "lightweight" to match the white background.

Style: Outline (Stroke) icons.

Stroke Width: 1.5px to 2.0px.

Corner Style: Rounded caps/joins (soft edges, not sharp).

Active State: When you tap an icon in the bottom bar, it often switches from Outline to Solid (Filled) to indicate selection.


4. Component Specification

A. The Product Card (Menu Item)

Container Shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))

Elevation/Shadow: Very subtle.

BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))

Padding: EdgeInsets.all(12) internal padding.

Image Ratio: 1:1 (Square) images for products.

B. The "Add" Button (Mini FAB)

Shape: CircleBorder()

Size: 32x32 logical pixels.

Color: Primary Blue background, White icon.

Icon: Icons.add (Material) or CupertinoIcons.add (iOS style).

C. Navigation Bar (Bottom)

Height: kBottomNavigationBarHeight + 10 (slightly taller than default).

Shape: Often has a rounded top-left and top-right corner (Radius.circular(20)), lifting it slightly off the bottom edge visually.

5. Interaction & Animation

Scroll Physics:

Android: ClampingScrollPhysics (stops hard at the end).

iOS: BouncingScrollPhysics (elastic rubber band effect).

Loading State:

Shimmer Effect: They do not use circular progress indicators for loading menu items. They use a "Shimmer" (a grey gradient wave moving left to right over grey boxes) that mimics the shape of the text and image.

Flutter Package: shimmer.