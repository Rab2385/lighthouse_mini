{{flutter_js}}
{{flutter_build_config}}

// Keep the web app fully local (issue #12): the renderer comes from our own
// server instead of www.gstatic.com, and missing-glyph font lookups go to our
// own origin instead of fonts.gstatic.com — the app bundles every font it
// needs, so nothing is ever requested from Google.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
    fontFallbackBaseUrl: "assets/fonts/fallback/",
  },
});
