# Web font loading (Noto Sans Symbols)

If you see **"Failed to load font Noto Sans Symbols"** or **"TypeError: Failed to fetch"** when running on web (Edge/Chrome), try:

1. **Use the HTML renderer** (avoids CanvasKit font requests):
   ```bash
   flutter run -d edge --web-renderer html
   ```
   Or for Chrome:
   ```bash
   flutter run -d chrome --web-renderer html
   ```

2. **Allow external fonts**: Ensure your network/firewall allows `https://fonts.gstatic.com`. The preconnect tags in `index.html` help the browser load fonts when allowed.

3. **Build with HTML renderer** so the built app doesn’t rely on the symbol font:
   ```bash
   flutter build web --web-renderer html
   ```
