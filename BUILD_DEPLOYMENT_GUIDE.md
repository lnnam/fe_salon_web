# Web Build & Deployment Guide

## Current Build Status ✓
- **API URL**: `https://apiclient.greatyarmouthnails.com`
- **Build Location**: `build/web/`
- **Build Status**: ✓ Complete and verified
- **URL Embedded**: ✓ Confirmed in JavaScript (13 occurrences)

## Steps Completed
1. ✓ Flutter clean (removed all caches)
2. ✓ Pub cache cleared (`~/.pub-cache`)
3. ✓ Dependencies fresh installed (`flutter pub get`)
4. ✓ Web app rebuilt with `flutter build web --release`
5. ✓ Production URL verified in build output
6. ✓ Cache control headers configured in index.html

## How to Deploy

### Option 1: Local Testing
```bash
# Serve the build locally
cd build/web
python3 -m http.server 8000
# Visit: http://localhost:8000
```

### Option 2: Production Server
Copy the entire `build/web/` folder to your web server root.

## Important: Cache Busting

The build includes automatic cache control headers:
```html
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
```

**If users still see old version:**

1. **Browser level:**
   - Chrome/Firefox: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
   - Safari: `Cmd+Option+E` then reload

2. **Server level (nginx example):**
```nginx
location / {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
    add_header Expires "0";
    try_files $uri $uri/ /index.html;
}
```

3. **Server level (Apache example):**
```apache
<FilesMatch "\.html$">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
    Header set Pragma "no-cache"
    Header set Expires "0"
</FilesMatch>
```

## Verification

Build is verified to contain:
- Production API URL: ✓ https://apiclient.greatyarmouthnails.com (13 occurrences)
- All endpoints configured: ✓
- Optimized assets: ✓ (fonts tree-shaken 99.4%)
- Cache headers: ✓

## CRITICAL: Deploy to Server

**The console showing `http://localhost:8080` means the built files haven't been deployed yet!**

### To Fix:

1. **Copy the build folder to your server:**
```bash
# From your development machine
scp -r build/web/ user@booking.greatyarmouthnails.com:/var/www/html/
```

2. **Or if you have direct access:**
```bash
# Copy all files from build/web/ to your web root
cp -r build/web/* /path/to/web/root/
```

3. **Verify deployment:**
- Visit https://booking.greatyarmouthnails.com
- Open DevTools (F12)
- Check Console - should now show: `API base url: https://apiclient.greatyarmouthnails.com`
- Check Network tab - API calls should go to `apiclient.greatyarmouthnails.com`

4. **If still showing localhost:**
   - Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)
   - Clear browser cache completely
   - Ensure web server has no-cache headers configured (see above)

## Build Contents

Files to deploy from `build/web/`:
- `index.html` - Main entry point
- `main.dart.js` - Compiled Flutter app (contains production URL)
- `assets/` - Fonts, images, translations
- `canvaskit/` - WebAssembly rendering engine
- All other generated files

**Total build size:** ~45-50 MB (includes CanvasKit)
