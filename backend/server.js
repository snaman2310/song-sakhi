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
app.use(express.json({ limit: '25mb' }));

// The web build (song-sakhi.onrender.com) calls /api/* from the browser, so it
// needs CORS. No cookies are used on these routes, hence no credentials.
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

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
// Gemini (song identification) – the key lives ONLY here, never in the app.
// Set GEMINI_API_KEY in the Render dashboard at
// https://aistudio.google.com/apikey. The key is treated as an opaque string
// — we validate it by making actual API requests, not by checking its prefix.
// ---------------------------------------------------------------------------
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

// "gemini-flash-latest" is a stable alias Google keeps pointed at the newest
// Flash model, so this list does not go stale when a version is retired.
// Order matters: we try the stable alias first, then other Flash models.
// New model names (3.x-series) replaced the retired 2.x-series models.
const GEMINI_MODELS = [
  'gemini-flash-latest',
  'gemini-3.5-flash',
  'gemini-3.0-flash',
  'gemini-3.5-flash-lite',
  'gemini-3.0-flash-lite',
  process.env.GEMINI_MODEL,
].filter(Boolean);

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

// ---------------------------------------------------------------------------
// Song identification (Gemini proxy)
// ---------------------------------------------------------------------------
class GeminiError extends Error {
  constructor(message, { status = 502, code = 'GEMINI_ERROR', model = '' } = {}) {
    super(message);
    this.status = status;
    this.code = code;
    this.model = model;
  }
}

async function callGemini(parts) {
  if (!GEMINI_API_KEY) {
    throw new GeminiError(
      'Song identification is not configured on the server yet. Add GEMINI_API_KEY in Render.',
      { status: 503, code: 'GEMINI_KEY_MISSING' },
    );
  }

  let lastError = null;
  for (const model of GEMINI_MODELS) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 90000);
    try {
      const res = await fetch(`${GEMINI_BASE}/${model}:generateContent`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': GEMINI_API_KEY,
        },
        body: JSON.stringify({
          contents: [{ role: 'user', parts }],
          generationConfig: { temperature: 0.2 },
        }),
        signal: controller.signal,
      });
      const data = await res.json().catch(() => ({}));

      if (res.ok) {
        const text = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
        if (!text.trim()) {
          lastError = new GeminiError('Gemini returned an empty answer.', {
            status: 502,
            code: 'GEMINI_EMPTY',
            model,
          });
          continue;
        }
        return { text, model };
      }

      const msg = data?.error?.message || `HTTP ${res.status}`;

      // A dead / leaked key will never work on another model – fail fast.
      if (res.status === 401 || res.status === 403 || /API key not valid/i.test(msg)) {
        throw new GeminiError(`Gemini rejected the API key: ${msg}`, {
          status: 401,
          code: 'GEMINI_KEY_INVALID',
          model,
        });
      }
      if (res.status === 429) {
        throw new GeminiError(`Gemini rate limit hit: ${msg}`, {
          status: 429,
          code: 'GEMINI_QUOTA',
          model,
        });
      }

      // 400/404 usually means this model is retired or unsupported here.
      lastError = new GeminiError(`${model}: ${msg}`, {
        status: res.status === 404 ? 404 : 502,
        code: res.status === 404 ? 'GEMINI_MODEL_UNAVAILABLE' : 'GEMINI_ERROR',
        model,
      });
    } catch (err) {
      if (err instanceof GeminiError) {
        // Invalid key / quota: trying older models is pointless.
        if (err.code === 'GEMINI_KEY_INVALID' || err.code === 'GEMINI_QUOTA') throw err;
        lastError = err;
      } else if (err.name === 'AbortError') {
        lastError = new GeminiError('Gemini request timed out.', {
          status: 504,
          code: 'GEMINI_TIMEOUT',
          model,
        });
      } else {
        lastError = new GeminiError(`Gemini request failed: ${err.message}`, {
          status: 502,
          code: 'GEMINI_NETWORK',
          model,
        });
      }
    } finally {
      clearTimeout(timer);
    }
  }
  throw lastError || new GeminiError('No Gemini model could handle the request.', {
    status: 502,
    code: 'GEMINI_UNAVAILABLE',
  });
}

function parseSongs(text) {
  const cleaned = String(text).replace(/```(?:json)?/gi, '').trim();
  const start = cleaned.indexOf('[');
  const end = cleaned.lastIndexOf(']');
  if (start === -1 || end === -1 || end <= start) return [];
  let list;
  try {
    list = JSON.parse(cleaned.slice(start, end + 1));
  } catch {
    return [];
  }
  if (!Array.isArray(list)) return [];
  return list
    .filter((s) => s && typeof s === 'object')
    .map((s) => ({
      title: String(s.title ?? s.song ?? s.track ?? '').trim(),
      artist: String(s.artist ?? s.artistName ?? '').trim(),
    }))
    .filter((s) => s.title)
    .slice(0, 5);
}

const SONG_PROMPT =
  'You identify music from audio clips. Listen to the clip from an Instagram reel. ' +
  'Use any lyrics, vocals, spoken titles, artist mentions or recognisable melody. ' +
  'Only include a song if you are reasonably confident it is actually the one playing; ' +
  'never pad the list with guesses or similar-sounding tracks. ' +
  'Return ONLY a JSON array (no prose, no markdown) of up to 5 objects shaped like ' +
  '[{"title":"Song name","artist":"Artist name"}], most likely first. ' +
  'If you genuinely cannot identify any song, return [].';

// ---------------------------------------------------------------------------
// Token refresh – Google/Spotify access tokens expire after ~1 hour.
// ---------------------------------------------------------------------------
app.post('/api/refresh', async (req, res) => {
  const { provider, refreshToken } = req.body || {};
  if (!refreshToken) {
    return res.status(400).json({ error: 'Missing refreshToken', code: 'BAD_REQUEST' });
  }
  try {
    const isSpotify = provider === 'spotify';
    const clientId = isSpotify ? SPOTIFY_CLIENT_ID : GOOGLE_CLIENT_ID;
    const clientSecret = isSpotify ? SPOTIFY_CLIENT_SECRET : GOOGLE_CLIENT_SECRET;
    if (!clientId || !clientSecret) {
      throw new Error(`${isSpotify ? 'Spotify' : 'Google'} is not configured on the server.`);
    }
    const body = new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: clientId,
      client_secret: clientSecret,
    });
    const tokenRes = await fetch(isSpotify ? SPOTIFY_TOKEN_URL : GOOGLE_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    });
    const data = await tokenRes.json().catch(() => ({}));
    if (!tokenRes.ok) {
      throw new Error(data.error_description || data.error || `HTTP ${tokenRes.status}`);
    }
    res.json({
      access_token: data.access_token,
      // Spotify does not rotate refresh tokens; Google usually omits it.
      refresh_token: data.refresh_token || refreshToken,
      expires_in: data.expires_in || 3600,
    });
  } catch (err) {
    console.error('[refresh]', err.message);
    res.status(400).json({ error: err.message, code: 'REFRESH_FAILED' });
  }
});

app.get('/api/gemini/health', async (req, res) => {
  const payload = {
    configured: !!GEMINI_API_KEY,
    models: GEMINI_MODELS,
  };
  if (!GEMINI_API_KEY) {
    return res.status(503).json({
      ...payload,
      ok: false,
      code: 'GEMINI_KEY_MISSING',
      error: 'GEMINI_API_KEY is not set on the server.',
    });
  }
  try {
    const { model } = await callGemini([{ text: 'Reply with exactly: OK' }]);
    res.json({ ...payload, ok: true, model });
  } catch (err) {
    res.status(err.status || 502).json({
      ...payload,
      ok: false,
      code: err.code || 'GEMINI_ERROR',
      error: err.message,
    });
  }
});

app.post('/api/identify', async (req, res) => {
  try {
    const { audioBase64, mimeType, transcript } = req.body || {};
    if (!audioBase64 && !transcript) {
      return res.status(400).json({
        error: 'Provide audioBase64 or transcript.',
        code: 'BAD_REQUEST',
      });
    }

    const parts = [];
    if (audioBase64) {
      parts.push({
        inline_data: {
          mime_type: mimeType || 'audio/m4a',
          data: audioBase64,
        },
      });
    }
    parts.push({
      text: transcript
        ? `${SONG_PROMPT}\n\nThe clip transcript was: "${transcript}"`
        : SONG_PROMPT,
    });

    const { text, model } = await callGemini(parts);
    res.json({ songs: parseSongs(text), model });
  } catch (err) {
    console.error('[identify]', err.code || '', err.message);
    res.status(err.status || 502).json({
      error: err.message,
      code: err.code || 'GEMINI_ERROR',
    });
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
  console.log(`Gemini key configured: ${!!GEMINI_API_KEY}`);
});
