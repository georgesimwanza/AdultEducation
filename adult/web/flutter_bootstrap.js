{{flutter_js}}
{{flutter_build_config}}

// Load the rendering engine from this site instead of Google's CDN, so the
// app starts without internet access (e.g. a school's local network) and
// doesn't depend on gstatic.com being reachable.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
