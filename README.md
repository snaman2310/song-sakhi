# Song Sakhi – Music Nudge

Identify the song playing in an Instagram reel and save it to Spotify or
YouTube Music.

**Flow:** sign in → connect Spotify / YouTube Music → system setup → home →
capture a reel clip → review detected songs → pick a playlist → saved.

## Where the API keys live

| Key | Where it belongs | Why |
|-----|------------------|-----|
| `GEMINI_API_KEY` | **Render env var** on `song-sakhi-auth` (preferred) **or** entered in the app's Settings screen | Never commit it. The backend proxies the call so the key is not shipped in the APK. |
| `GOOGLE_CLIENT_SECRET` | Render env var | OAuth token exchange |
| `SPOTIFY_CLIENT_SECRET` | Render env var | OAuth token exchange |

### Getting a Gemini key

1. Open <https://aistudio.google.com/apikey>
2. **Create API key** → copy it (it starts with `AIza`)
3. Either:
   - Render dashboard → `song-sakhi-auth` → **Environment** → add
     `GEMINI_API_KEY` → save (service redeploys), **or**
   - In the app: **Settings → AI Settings** → paste → *Save key* → *Test key*

Verify the server side any time:

```bash
curl https://song-sakhi-auth1.onrender.com/api/gemini/health
# {"configured":true,"ok":true,"model":"gemini-flash-latest", ...}
```

The backend tries `gemini-flash-latest` first — a stable Google alias that always
points at the newest Flash model — so model retirements don't break the app.

## Backend endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Liveness |
| `GET /auth/google`, `GET /auth/spotify` | Start OAuth (`?platform=mobile` for the APK) |
| `POST /api/refresh` | Refresh an expired access token (server holds the secret) |
| `POST /api/identify` | Gemini song identification (`{audioBase64, mimeType}` or `{transcript}`) |
| `GET /api/gemini/health` | Check that the server has a working Gemini key |

## Builds

- **Android APK:** `.github/workflows/build-apk.yml` → artifact `song-sakhi-apk`
- **Web:** `.github/workflows/flutter-web.yml` → publishes to the `gh-pages`
  branch, which the Render static site serves

## Notes

- Audio is captured as 16 kHz mono WAV (Gemini's supported inline format) and is
  never stored after identification.
- Gemini identifies music from lyrics / vocals / recognisable melody. It is not
  an audio-fingerprinting service, so fully instrumental reels may not resolve.
- The floating Instagram overlay is **not implemented yet**; capture is manual
  from the app for now.
