{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // Paksa HTML renderer agar gambar network tidak diblokir CORS di Chrome.
    // CanvasKit (default) menggunakan WebGL fetch() yang diblokir browser cross-origin.
    // HTML renderer menggunakan tag <img> native sehingga gambar langsung tampil.
    let appRunner = await engineInitializer.initializeEngine({
      renderer: "html",
    });
    await appRunner.runApp();
  }
});
