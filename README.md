# Song Sakhi – Music Nudge

A Flutter app that lets you:

1. Log in with Spotify or YouTube Music.
2. Tap a “Nudge” button while scrolling Instagram reels.
3. The app listens to a short audio clip, transcribes it (Whisper on mobile / placeholder on web), sends the transcript to Gemini Flash, and shows a list of suggested songs.
4. You check the songs you want, pick a playlist, and the app adds them to Spotify / YouTube Music.

## Project structure

```
lib/
  main.dart
  auth_service.dart
  gemini_service.dart
  playlist_service.dart
  whisper_service.dart
  screens/
    login_screen.dart
    home_screen.dart
    listening_screen.dart
    suggestions_screen.dart
    playlist_selector_screen.dart
    confirmation_screen.dart
web/
  index.html
  manifest.json
.github/workflows/flutter-web.yml
pubspec.yaml
```

## Quick start – build the web bundle with GitHub Actions

1. Push your changes to the `main` branch.
2. Go to the **Actions** tab of this repository.
3. Wait for the **Build Flutter Web** workflow to finish (green check).
4. Click the workflow run, scroll to **Artifacts**, and download `flutter-web-bundle.zip`.
5. Unzip it – you now have a `build/web/` folder.

## Deploy to Render

1. Open your Render dashboard → your **Static Site**.
2. Click **Manual deploy** → **Upload folder**.
3. Select the unzipped `build/web` folder.
4. Wait for the deployment to finish, then open the Render URL.

## Adding real API keys (later)

Replace the placeholders in:

| File | Placeholder |
|------|-------------|
| `lib/auth_service.dart` | `YOUR_SPOTIFY_CLIENT_ID`, `YOUR_SPOTIFY_CLIENT_SECRET`, `YOUR_SPOTIFY_REDIRECT_URI`, `YOUR_YT_CLIENT_ID`, `YOUR_YT_CLIENT_SECRET`, `YOUR_YT_REDIRECT_URI` |
| `lib/gemini_service.dart` | `YOUR_GEMINI_API_KEY` |

After editing, push again – the GitHub Actions workflow will rebuild the web bundle, and you can re‑upload it to Render.

## Whisper note

The `flutter_whisper` native package has been removed from the web build so the app can compile for the browser. On Android/iOS you can re‑add it to `pubspec.yaml` and use the real on‑device Whisper model. For the web prototype the transcript is a placeholder (`"Boys a Lose"`).
