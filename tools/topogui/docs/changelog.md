# Changelog

All notable changes to TopoGUI are documented in this file,
following [Keep a Changelog](https://keepachangelog.com/) conventions.
Update the Unreleased section during Finalize; do not bump the version
until Release.

## [Unreleased]

- [Added] loop and face construction (development plan, v0 increment
  3): the loop gesture accumulates the clicked points and submits the
  whole figure atomically on the closing click through
  `Make_Loop_From_Edges`; the face is one menu action over the
  accumulated chain (`Make_Face`); every kernel classification or
  rejection is displayed verbatim, and the accepted face fills its
  polygon on the canvas
- [Changed] the visual direction: the light, flat, Material-like look
  replaces the soft-extruded slate sketchbook, archived in
  `Topogui.Theme.Neumorphic`; the views consume the rule sets through
  the `Topogui.Theme` contract, one accessor per role, so switching
  direction is a body change
- [Fixed] the canvas layout: a flex item whose child carries an
  explicit size grows to it — the canvas box now clips
  (`Overflow_Hidden`), which breaks the image-size feedback loop that
  inflated the canvas to millions of pixels, buried the menus and kept
  the main loop spinning
- [Fixed] the context menus are styled (white cards, shaded item rows)
  and their item selection fires: open, select, and the callback runs
- [Changed] the executable of the development build lands in the
  project directory instead of the repository `bin/`

## [0.1.0-dev] - 2026-10-26

- [Added] the application shell on Adi2: menu bar (File, Sketch), the
  canvas as the hero, and the status line displaying every kernel
  rejection verbatim; the visual direction is the neumorphic slate
  sketchbook, tokens in `src/topogui-theme.ads` (development plan, v0
  increment 1)
- [Added] point and edge drawing with exact grid snapping: the session
  is a replayable TopoScript, every gesture is arbitrated by the
  kernel through `topocli run_code`, and the canvas renders the
  accepted session as an SVG at exact grid coordinates (development
  plan, v0 increment 2; the drawing model is `docs/dev/drawing-model.md`)
