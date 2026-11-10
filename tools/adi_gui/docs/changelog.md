# Changelog

All notable changes to Adi_GUI are documented in this file,
following [Keep a Changelog](https://keepachangelog.com/) conventions.
Update the Unreleased section during Finalize; do not bump the version
until Release.

## [Unreleased]

## [Unreleased]

- [Fixed] the window extent: the height is 85% of the display's usable
  bounds, and the canvas style no longer resizes the window when the
  grid renders (the image claims 100% of its parent and the drawing
  never writes an explicit size back to the layout)
- [Added] the Select mode: click selects the most recently created vertex
  at the point, exact-equality snap, selection ring in `Selection_Svg`.
  The move half is deferred to the kernel (DD-006, open question 4)
- [Added] loop and face construction (v0 increment 3): the figure is
  submitted atomically on the closing click, kernel classifications
  verbatim, the accepted face fills its polygon
- [Changed] the visual direction to the light Material look, the views
  consume the rule sets through the `Adi_Gui.Theme` contract; the
  neumorphic direction is archived as built in `Adi_Gui.Theme.Neumorphic`
- [Fixed] the canvas layout: `Overflow_Hidden` breaks the image-size
  feedback loop that inflated the canvas and buried the menus
- [Fixed] the context menus: styled (white cards, shaded item rows) and
  their item selection fires
- [Changed] the executable of the development build lands in the project
  directory instead of the repository `bin/`

## [0.1.0-dev] - 2026-10-26

- [Added] the application shell on Adi2: menu bar (File, Sketch), the
  canvas as the hero, and the status line displaying every kernel
  rejection verbatim; the visual direction is the neumorphic slate
  sketchbook, tokens in `src/adi_gui-theme.ads` (development plan, v0
  increment 1)
- [Added] point and edge drawing with exact grid snapping: the session
  is a replayable TopoScript, every gesture is arbitrated by the
  kernel through `topocli run_code`, and the canvas renders the
  accepted session as an SVG at exact grid coordinates (development
  plan, v0 increment 2; the drawing model is `docs/dev/drawing-model.md`)
