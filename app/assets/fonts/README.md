# Font icon

The font icon has been generated using Icomoon App.

To add icons to the set:

1. navigate to https://icomoon.io/app
2. import the `icomoon.svg` file
3. import the SVG icons you want to add as another set
4. move the icomoon set above the new SVG icons
5. generate a new icon font

The codepoints musn't have changed (new icons must be added _after_ the current
codepoints. For example `alert` must be `e900`. If another icon has token that
codepoint, you must try again, or fix all the individual names so that they
match the codepoints in `_sprites.scss` or fix all the codepoints in
`_sprites.scss` to match the new codepoints.
