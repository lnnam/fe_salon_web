# DEPLOYMENT INSTRUCTIONS

## Status Check
- ✓ Local build: `build/web/main.dart.js` contains production URL (apiclient.greatyarmouthnails.com)
- ✗ Deployed server: Still has localhost:8080 (OLD BUILD)
- **Action Required**: Re-deploy the new build files

## Deploy the Correct Build

### Option 1: SSH/SCP (Recommended)
```bash
# Copy all build files to server
scp -r /Users/solsol/Dev/fe_salon_web/build/web/* user@booking.greatyarmouthnails.com:/var/www/html/

# Or if deployed to a subdirectory:
scp -r /Users/solsol/Dev/fe_salon_web/build/web/* user@booking.greatyarmouthnails.com:/var/www/html/booking/
```

### Option 2: Using compressed archive (faster)
```bash
# The archive is ready at: /Users/solsol/Dev/fe_salon_web/build_web.tar.gz (8.4 MB)
scp /Users/solsol/Dev/fe_salon_web/build_web.tar.gz user@booking.greatyarmouthnails.com:/tmp/
ssh user@booking.greatyarmouthnails.com
cd /var/www/html
tar -xzf /tmp/build_web.tar.gz
mv build/web/* .
rm -rf build/
```

### Option 3: FTP
- Upload all files from `/Users/solsol/Dev/fe_salon_web/build/web/` to your web root
- Replace existing files when prompted

## Verify Deployment

After uploading:

1. **Hard refresh the browser:**
   - `Cmd+Shift+R` on Mac
   - `Ctrl+Shift+R` on Windows/Linux

2. **Check in DevTools Console:**
   - Open: https://booking.greatyarmouthnails.com/#/home
   - Press F12 → Console tab
   - Should show: `API base url: https://apiclient.greatyarmouthnails.com`

3. **Check Network tab:**
   - Should see API calls going to `apiclient.greatyarmouthnails.com`
   - NOT to `localhost:8080`

4. **Automated verification:**
```bash
curl -s https://booking.greatyarmouthnails.com/main.dart.js | grep -c "apiclient.greatyarmouthnails.com"
# Should show: 13
```

## Files to Deploy
- `index.html` - Main entry point
- `main.dart.js` - Compiled app (✓ contains production URL)
- `main.dart.js.map` - Source map (optional)
- `flutter.js` - Flutter runtime
- `assets/` - All assets
- `canvaskit/` - WebAssembly engine

## Summary
Your local build is correct. You just deployed the OLD version to the server. 
Re-deploy the files from `/Users/solsol/Dev/fe_salon_web/build/web/` and it will work!
