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
app.set('trust proxy', 1);
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

// Latency strategy (free-tier friendly):
//  * every model attempt gets a short timeout (default 20s, not 90s)
//  * a model that fails hands over to the next one immediately
//  * a model that is merely slow is "hedged": after GEMINI_STAGGER_MS the next
//    model starts in parallel and whichever answers first wins
const GEMINI_TIMEOUT_MS = Number(process.env.GEMINI_TIMEOUT_MS) || 20000;
const GEMINI_STAGGER_MS = Number(process.env.GEMINI_STAGGER_MS) || 4000;

async function callOneGemini(model, parts, signal) {
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
    signal,
  });
  const data = await res.json().catch(() => ({}));

  if (res.ok) {
    const text = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
    if (!text.trim()) {
      throw new GeminiError('Gemini returned an empty answer.', {
        status: 502,
        code: 'GEMINI_EMPTY',
        model,
      });
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
  // Free-tier quotas are per model, so another model may still have room.
  if (res.status === 429) {
    throw new GeminiError(`Gemini rate limit hit on ${model}: ${msg}`, {
      status: 429,
      code: 'GEMINI_QUOTA',
      model,
    });
  }
  // 400/404 usually means this model is retired or unsupported; 503 = busy.
  throw new GeminiError(`${model}: ${msg}`, {
    status: res.status === 404 ? 404 : 502,
    code: res.status === 404 ? 'GEMINI_MODEL_UNAVAILABLE' : 'GEMINI_ERROR',
    model,
  });
}

function toGeminiError(err, model) {
  if (err instanceof GeminiError) return err;
  if (err && err.name === 'AbortError') {
    return new GeminiError(`${model}: timed out.`, { status: 504, code: 'GEMINI_TIMEOUT', model });
  }
  return new GeminiError(`Gemini request failed: ${err && err.message}`, {
    status: 502,
    code: 'GEMINI_NETWORK',
    model,
  });
}

function callGemini(parts) {
  if (!GEMINI_API_KEY) {
    return Promise.reject(new GeminiError(
      'Song identification is not configured on the server yet. Add GEMINI_API_KEY in Render.',
      { status: 503, code: 'GEMINI_KEY_MISSING' },
    ));
  }

  return new Promise((resolve, reject) => {
    const controllers = [];
    let next = 0;
    let active = 0;
    let done = false;
    let lastError = null;
    let quotaError = null;
    let hedgeTimer = null;

    const finish = (fn, value) => {
      if (done) return;
      done = true;
      clearTimeout(hedgeTimer);
      controllers.forEach((c) => c.abort());
      fn(value);
    };

    const launch = () => {
      if (done || next >= GEMINI_MODELS.length) return;
      const model = GEMINI_MODELS[next++];
      active++;
      const controller = new AbortController();
      controllers.push(controller);
      const timer = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

      callOneGemini(model, parts, controller.signal)
        .then((result) => finish(resolve, result))
        .catch((raw) => {
          const err = toGeminiError(raw, model);
          active--;
          if (done) return;
          if (err.code === 'GEMINI_KEY_INVALID') return finish(reject, err);
          lastError = err;
          if (err.code === 'GEMINI_QUOTA' && !quotaError) quotaError = err;
          if (next < GEMINI_MODELS.length) {
            launch(); // fail over immediately
          } else if (active === 0) {
            finish(reject, quotaError || lastError);
          }
        })
        .finally(() => clearTimeout(timer));

      // Hedge: if this attempt is slow, start the next model in parallel.
      clearTimeout(hedgeTimer);
      if (next < GEMINI_MODELS.length) hedgeTimer = setTimeout(launch, GEMINI_STAGGER_MS);
    };

    launch();
  });
}

// "Tum Hi Ho (From "Aashiqui 2")" -> "Tum Hi Ho". Soundtrack/feature tags and
// stray double quotes only hurt streaming-service search.
function cleanTitle(title) {
  return String(title || '')
    .replace(/\s*[(\[]\s*(from|feat\.?|ft\.?|with)\b[^)\]]*[)\]]/gi, '')
    .replace(/["\u201c\u201d]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function parseSongs(text, limit = 5) {
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
      title: cleanTitle(s.title ?? s.song ?? s.track ?? ''),
      artist: String(s.artist ?? s.artistName ?? '').trim(),
    }))
    .filter((s) => s.title)
    .slice(0, limit);
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
    groqConfigured: !!GROQ_API_KEY,
    audioModelEnabled: ENABLE_AUDIO_MODEL,
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

// ---------------------------------------------------------------------------
// Live listening: /api/identify-chunk
//
// The app records continuously and posts short overlapping WAV chunks here.
// Each chunk is analysed by TWO independent pipelines in parallel and the
// results are merged, so a song only one of them recognises is still found:
//   lyrics : Groq Whisper (speech-to-text)  ->  Gemini (text only)
//   audio  : Gemini listening to the raw audio
// Songs found by both pipelines are ranked first.
// ---------------------------------------------------------------------------
const GROQ_API_KEY = process.env.GROQ_API_KEY || '';
const GROQ_STT_URL = 'https://api.groq.com/openai/v1/audio/transcriptions';
const GROQ_STT_MODEL = process.env.GROQ_STT_MODEL || 'whisper-large-v3-turbo';
// Set ENABLE_AUDIO_MODEL=false to save Gemini quota (lyrics pipeline only).
const ENABLE_AUDIO_MODEL = String(process.env.ENABLE_AUDIO_MODEL || 'true').toLowerCase() !== 'false';

const SONG_PROMPT_LYRICS =
  'You identify songs from transcribed lyrics. The text below was auto-transcribed by a ' +
  'speech-to-text model from a few seconds of audio of an Instagram reel. It may contain ' +
  'recognition errors, mixed languages (for example Hindi written in English letters) ' +
  'or spoken words that are not lyrics. ' +
  'Only include a song if the lyrics clearly match a specific real song you know; ' +
  'never pad the list with guesses. ' +
  'Return ONLY a JSON array (no prose, no markdown) of up to 3 objects shaped like ' +
  '[{"title":"Song name","artist":"Artist name"}], most likely first. ' +
  'If you cannot identify any song, return [].';

const HALLUCINATION_RE =
  /^(thank(s| you)( so much)?( for watching)?|please subscribe|subscribe|like and subscribe|you|bye|\.+)[.!\s]*$/i;

function usableTranscript(text) {
  const t = String(text || '').trim();
  if (!t) return false;
  if (HALLUCINATION_RE.test(t)) return false;
  return t.split(/\s+/).filter(Boolean).length >= 4;
}

async function transcribeWithGroq(wavBuffer) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15000);
  try {
    const form = new FormData();
    form.append('file', new Blob([wavBuffer], { type: 'audio/wav' }), 'chunk.wav');
    form.append('model', GROQ_STT_MODEL);
    form.append('response_format', 'verbose_json');
    form.append('temperature', '0');
    const res = await fetch(GROQ_STT_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${GROQ_API_KEY}` },
      body: form,
      signal: controller.signal,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const msg = data?.error?.message || `HTTP ${res.status}`;
      const code =
        res.status === 429 ? 'GROQ_RATE_LIMIT'
        : res.status === 401 || res.status === 403 ? 'GROQ_KEY_INVALID'
        : 'GROQ_ERROR';
      return { text: '', error: { code, message: `Groq: ${msg}`, status: res.status === 429 ? 429 : 502 } };
    }
    // Drop segments Whisper itself flags as non-speech (music-only hallucinations).
    let text = '';
    if (Array.isArray(data.segments) && data.segments.length) {
      text = data.segments
        .filter((s) => !(s.no_speech_prob > 0.6) && !(s.avg_logprob < -1.3))
        .map((s) => s.text || '')
        .join(' ')
        .trim();
    } else {
      text = String(data.text || '').trim();
    }
    return { text };
  } catch (err) {
    const timedOut = err && err.name === 'AbortError';
    return {
      text: '',
      error: {
        code: timedOut ? 'GROQ_TIMEOUT' : 'GROQ_NETWORK',
        message: timedOut ? 'Groq transcription timed out.' : `Groq request failed: ${err && err.message}`,
        status: timedOut ? 504 : 502,
      },
    };
  } finally {
    clearTimeout(timer);
  }
}

function errInfo(err) {
  return { code: err.code || 'GEMINI_ERROR', message: err.message, status: err.status || 502 };
}

async function runLyricsPipeline(wavBuffer) {
  if (!GROQ_API_KEY) return { songs: [], transcript: '', skipped: 'GROQ_KEY_MISSING' };
  const stt = await transcribeWithGroq(wavBuffer);
  if (stt.error) return { songs: [], transcript: '', error: stt.error };
  if (!usableTranscript(stt.text)) return { songs: [], transcript: stt.text, skipped: 'NO_SPEECH' };
  try {
    const { text } = await callGemini([{ text: `${SONG_PROMPT_LYRICS}\n\nTranscript: "${stt.text}"` }]);
    return { songs: parseSongs(text), transcript: stt.text };
  } catch (err) {
    return { songs: [], transcript: stt.text, error: errInfo(err) };
  }
}

async function runAudioPipeline(base64Audio, mimeType) {
  if (!ENABLE_AUDIO_MODEL) return { songs: [], skipped: 'DISABLED' };
  try {
    const { text } = await callGemini([
      { inline_data: { mime_type: mimeType || 'audio/wav', data: base64Audio } },
      { text: SONG_PROMPT },
    ]);
    return { songs: parseSongs(text) };
  } catch (err) {
    return { songs: [], error: errInfo(err) };
  }
}

function songKey(title) {
  return String(title || '')
    .toLowerCase()
    .replace(/[(\[].*?[)\]]/g, ' ')
    .replace(/\b(feat|ft)\.?\b.*$/i, ' ')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

// Union of both pipelines. Songs both pipelines agree on come first.
function mergeSongs(lyricsSongs, audioSongs) {
  const byKey = new Map();
  const add = (list, via) => {
    list.forEach((s, i) => {
      const key = songKey(s.title);
      if (!key) return;
      const existing = byKey.get(key);
      if (existing) {
        if (!existing.via.includes(via)) existing.via.push(via);
        if ((!existing.artist || /^unknown/i.test(existing.artist)) && s.artist) existing.artist = s.artist;
      } else {
        byKey.set(key, { title: s.title, artist: s.artist || '', via: [via], rank: i });
      }
    });
  };
  add(lyricsSongs, 'lyrics');
  add(audioSongs, 'audio');
  return [...byKey.values()]
    .sort((a, b) => b.via.length - a.via.length || a.rank - b.rank)
    .map(({ title, artist, via }) => ({ title, artist, via }));
}

// Tiny in-memory per-IP limiter so the open endpoint cannot burn the free quota.
const rateBuckets = new Map();
function rateLimit(max, windowMs) {
  return (req, res, next) => {
    const now = Date.now();
    const key = `${req.path}|${req.ip || 'unknown'}`;
    const b = rateBuckets.get(key);
    if (!b || now - b.start > windowMs) {
      rateBuckets.set(key, { start: now, count: 1 });
      return next();
    }
    b.count++;
    if (b.count > max) {
      return res.status(429).json({ error: 'Too many requests, slow down.', code: 'RATE_LIMITED' });
    }
    next();
  };
}
setInterval(() => {
  const now = Date.now();
  for (const [k, b] of rateBuckets) if (now - b.start > 5 * 60 * 1000) rateBuckets.delete(k);
}, 60 * 1000).unref();

app.post('/api/identify-chunk', rateLimit(40, 60 * 1000), async (req, res) => {
  try {
    const { audioBase64, mimeType } = req.body || {};
    if (!audioBase64) {
      return res.status(400).json({ error: 'Provide audioBase64.', code: 'BAD_REQUEST' });
    }
    const wav = Buffer.from(audioBase64, 'base64');
    const [lyrics, audio] = await Promise.all([
      runLyricsPipeline(wav),
      runAudioPipeline(audioBase64, mimeType),
    ]);

    const songs = mergeSongs(lyrics.songs, audio.songs);
    const describe = (p) => (p.error ? `error:${p.error.code}` : p.skipped ? `skipped:${p.skipped}` : 'ok');
    const pipelines = { lyrics: describe(lyrics), audio: describe(audio) };

    // A pipeline "completed" if it ran without error and wasn't skipped by config.
    const completed = (p) => !p.error && p.skipped !== 'GROQ_KEY_MISSING' && p.skipped !== 'DISABLED';
    if (songs.length === 0 && !completed(lyrics) && !completed(audio)) {
      const e = lyrics.error || audio.error;
      if (e) {
        return res.status(e.status || 502).json({ error: e.message, code: e.code, pipelines });
      }
      return res.status(503).json({
        error: 'No identification pipeline is configured on the server. Add GEMINI_API_KEY and/or GROQ_API_KEY in Render.',
        code: 'NOT_CONFIGURED',
        pipelines,
      });
    }

    res.json({ songs, transcript: lyrics.transcript || '', pipelines });
  } catch (err) {
    console.error('[identify-chunk]', err.code || '', err.message);
    res.status(err.status || 502).json({ error: err.message, code: err.code || 'CHUNK_ERROR' });
  }
});

// ---------------------------------------------------------------------------
// Reading the screen: /api/identify-text
//
// Many "songs you need to hear" reels print each song's title on screen. The
// app grabs frames while listening, reads the text on-device (ML Kit OCR) and
// sends only the new text lines here. Text is the strongest evidence we have
// (it is what the creator typed), so these songs outrank audio guesses.
// ---------------------------------------------------------------------------
const SONG_PROMPT_SCREEN =
  'You read text captured from a phone screen (OCR output, may be noisy) while someone ' +
  'watches an Instagram reel. Reels that recommend music usually show each song title, ' +
  'often with the artist, as on-screen text, numbered or one after another. The label at ' +
  'the bottom of a reel may read like "Artist - Song name" or "Song name - Artist". ' +
  'Extract ONLY songs that are actually written in the text. ' +
  'Ignore usernames, captions, hashtags, comments, buttons (Follow, Like, Comment, Share, ' +
  'Reply), counts, timestamps, ads and any other app UI. ' +
  'Do not invent songs that are not in the text. Fix obvious OCR typos in titles. ' +
  'If the artist is not shown, give the artist only when you are certain, otherwise use "". ' +
  'Return ONLY a JSON array (no prose, no markdown) of up to 12 objects shaped like ' +
  '[{"title":"Song name","artist":"Artist name"}] in the order they appear. ' +
  'If the text names no songs, return [].';

app.post('/api/identify-text', rateLimit(30, 60 * 1000), async (req, res) => {
  try {
    const raw = Array.isArray(req.body?.lines) ? req.body.lines : [];
    const lines = raw
      .map((l) => String(l ?? '').trim())
      .filter((l) => l.length >= 2 && l.length <= 160)
      .slice(0, 150);
    if (lines.length === 0) {
      return res.status(400).json({ error: 'Provide a non-empty lines array.', code: 'BAD_REQUEST' });
    }
    let text = lines.join('\n');
    if (text.length > 6000) text = text.slice(0, 6000);

    const { text: answer } = await callGemini([
      { text: `${SONG_PROMPT_SCREEN}\n\nScreen text:\n${text}` },
    ]);
    const songs = parseSongs(answer, 12).map((s) => ({ ...s, via: ['screen'] }));
    res.json({ songs });
  } catch (err) {
    console.error('[identify-text]', err.code || '', err.message);
    res.status(err.status || 502).json({ error: err.message, code: err.code || 'TEXT_ERROR' });
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
  console.log(`Groq key configured: ${!!GROQ_API_KEY}`);
  console.log(`Audio model enabled: ${ENABLE_AUDIO_MODEL}`);
});
