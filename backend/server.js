/**
 * Song Sakhi – OAuth backend
 *
 * Holds the Google / Spotify CLIENT SECRETS as environment variables and
 * performs the authorization-code -> token exchange server-side.
 * The Flutter web app never sees the secrets.
 */
const express = require('express');
const cookieParser = require('cookie-parser');
const crypto = require('crypto');

const app = express();
app.use(cookieParser());

// ---------------------------------------------------------------------------
// Configuration from environment variables (set these in the Render dashboard)
// ---------------------------------------------------------------------------
const PORT = process.env.PORT || 10000;

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '';
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || '';
const SPOTIFY_CLIENT_ID = process.env.SPOTIFY_CLIENT_ID || '';
const SPOTIFY_CLIENT_SECRET = process.env.SPOTIFY_CLIENT_SECRET || '';

// Public URLs
const BACKEND_URL = process.env.BACKEND_URL || `https://song-sakhi-auth1.onrender.com`;
const FRONTEND_URL = process.env.FRONTEND_URL || 'https://song-sakhi.onrender.com';

const GOOGLE_AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SPOTIFY_AUTH_URL = 'https://accounts.spotify.com/authorize';
const SPOTIFY_TOKEN_URL = 'https://accounts.spotify.com/api/token';

const GOOGLE_SCOPE = 'https://www.googleapis.com/auth/youtube.force-ssl';
const SPOTIFY_SCOPE = 'playlist-modify-public playlist-modify-private user-read-email';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}
function makeVerifier() {
  return crypto.randomBytes(48).toString('base64url');
}
function challengeFor(verifier) {
  return b64url(crypto.createHash('sha256').update(verifier).digest());
}
function setPkceCookies(res, verifier, state, kind) {
  const opts = { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 10 * 60 * 1000, path: '/' };
  res.cookie('pkce_verifier', verifier, opts);
  res.cookie('oauth_state', state, opts);
  res.cookie('oauth_kind', kind, opts);
}
function clearPkceCookies(res) {
  const opts = { path: '/', httpOnly: true, secure: true, sameSite: 'lax' };
  res.clearCookie('pkce_verifier', opts);
  res.clearCookie('oauth_state', opts);
  res.clearCookie('oauth_kind', opts);
}

// Redirect back to the Flutter app with tokens in the URL fragment.
function redirectToApp(req, res, provider, accessToken, refreshToken) {
  const params = new URLSearchParams({
    provider,
    access_token: accessToken || '',
    refresh_token: refreshToken || '',
  });
  // Mobile app uses a custom-scheme deep link; web app uses the hash route.
  if (req.cookies.oauth_platform === 'mobile') {
    return res.redirect(303, `songsakhi://auth?${params.toString()}`);
  }
  res.redirect(303, `${FRONTEND_URL}/#/auth-done?${params.toString()}`);
}

function redirectWithError(req, res, message) {
  if (req.cookies.oauth_platform === 'mobile') {
    return res.redirect(303, `songsakhi://auth-error?message=${encodeURIComponent(message)}`);
  }
  res.redirect(303, `${FRONTEND_URL}/#/auth-error?message=${encodeURIComponent(message)}`);
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------
app.get('/health', (req, res) => res.json({ ok: true, service: 'song-sakhi-auth' }));

// ---- Google ---------------------------------------------------------------
app.get('/auth/google', (req, res) => {
  const verifier = makeVerifier();
  const state = crypto.randomBytes(16).toString('hex');
  setPkceCookies(res, verifier, state, 'google');
  if (req.query.platform === 'mobile') {
    res.cookie('oauth_platform', 'mobile', { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 10 * 60 * 1000, path: '/' });
  }

  const params = new URLSearchParams({
    client_id: GOOGLE_CLIENT_ID,
    redirect_uri: `${BACKEND_URL}/auth/google/callback`,
    response_type: 'code',
    scope: GOOGLE_SCOPE,
    state,
    code_challenge_method: 'S256',
    code_challenge: challengeFor(verifier),
    access_type: 'offline',
    prompt: 'consent',
  });
  res.redirect(302, `${GOOGLE_AUTH_URL}?${params.toString()}`);
});

app.get('/auth/google/callback', async (req, res) => {
  try {
    if (req.query.error) throw new Error(`Google error: ${req.query.error}`);
    const code = req.query.code;
    if (!code) throw new Error('Missing authorization code');

    const verifier = req.cookies.pkce_verifier;
    const state = req.cookies.oauth_state;
    if (req.query.state !== state) throw new Error('State mismatch (possible CSRF)');

    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: `${BACKEND_URL}/auth/google/callback`,
      client_id: GOOGLE_CLIENT_ID,
      client_secret: GOOGLE_CLIENT_SECRET,
      code_verifier: verifier,
    });

    const tokenRes = await fetch(GOOGLE_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    });
    const data = await tokenRes.json().catch(() => ({}));
    if (!tokenRes.ok) {
      throw new Error(`Token exchange failed (${tokenRes.status}): ${data.error_description || data.error || JSON.stringify(data)}`);
    }
    clearPkceCookies(res);
    redirectToApp(req, res, 'google', data.access_token, data.refresh_token);
  } catch (err) {
    clearPkceCookies(res);
    console.error('[google]', err.message);
    redirectWithError(req, res, err.message);
  }
});

// ---- Spotify --------------------------------------------------------------
app.get('/auth/spotify', (req, res) => {
  const verifier = makeVerifier();
  const state = crypto.randomBytes(16).toString('hex');
  setPkceCookies(res, verifier, state, 'spotify');
  if (req.query.platform === 'mobile') {
    res.cookie('oauth_platform', 'mobile', { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 10 * 60 * 1000, path: '/' });
  }

  const params = new URLSearchParams({
    client_id: SPOTIFY_CLIENT_ID,
    redirect_uri: `${BACKEND_URL}/auth/spotify/callback`,
    response_type: 'code',
    scope: SPOTIFY_SCOPE,
    state,
    code_challenge_method: 'S256',
    code_challenge: challengeFor(verifier),
  });
  res.redirect(302, `${SPOTIFY_AUTH_URL}?${params.toString()}`);
});

app.get('/auth/spotify/callback', async (req, res) => {
  try {
    if (req.query.error) throw new Error(`Spotify error: ${req.query.error}`);
    const code = req.query.code;
    if (!code) throw new Error('Missing authorization code');

    const verifier = req.cookies.pkce_verifier;
    const state = req.cookies.oauth_state;
    if (req.query.state !== state) throw new Error('State mismatch (possible CSRF)');

    const body = new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: `${BACKEND_URL}/auth/spotify/callback`,
      client_id: SPOTIFY_CLIENT_ID,
      code_verifier: verifier,
    });

    const tokenRes = await fetch(SPOTIFY_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    });
    const data = await tokenRes.json().catch(() => ({}));
    if (!tokenRes.ok) {
      throw new Error(`Token exchange failed (${tokenRes.status}): ${data.error_description || data.error || JSON.stringify(data)}`);
    }
    clearPkceCookies(res);
    redirectToApp(req, res, 'spotify', data.access_token, data.refresh_token);
  } catch (err) {
    clearPkceCookies(res);
    console.error('[spotify]', err.message);
    redirectWithError(req, res, err.message);
  }
});

app.listen(PORT, () => {
  console.log(`song-sakhi-auth listening on ${PORT}`);
  console.log(`BACKEND_URL=${BACKEND_URL}`);
  console.log(`FRONTEND_URL=${FRONTEND_URL}`);
  console.log(`Google client id configured: ${!!GOOGLE_CLIENT_ID}`);
  console.log(`Google secret configured: ${!!GOOGLE_CLIENT_SECRET}`);
  console.log(`Spotify client id configured: ${!!SPOTIFY_CLIENT_ID}`);
  console.log(`Spotify secret configured: ${!!SPOTIFY_CLIENT_SECRET}`);
});
