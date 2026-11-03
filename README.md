# Tuck

Tuck's website: a static site (plain HTML, CSS and JavaScript) hosted on Netlify,
with accounts and profiles stored in [Supabase](https://supabase.com).

| File | What it is |
| --- | --- |
| `index.html` | Home page |
| `login.html` | Log in / sign up: **Continue with Google** or email and password |
| `profile.html` | The signed-in user's profile, which they can edit and save |
| `app.js` | Shared Supabase setup used by every page |
| `config.js` | Your Supabase Project URL and publishable (anon) key |
| `supabase/profiles.sql` | Creates the `profiles` table and its security rules |

## How it works

1. A visitor clicks **Continue with Google** on `login.html`.
2. Supabase sends them to Google, then back to `profile.html`, signed in.
   The first time, Supabase creates their account automatically.
3. A database trigger creates their `profiles` row, starting with their Google name and photo.
4. On `profile.html` they edit their name, username, savings goal, bio and photo, then click **Save profile**.
   Row Level Security means each person can only read and change their own profile.

Email-and-password sign-up still works, and those users get a profile the same way.

## Setup (one time, about 15 minutes)

You need three things connected: the database table, a Google OAuth client, and the Google provider in Supabase.

### 1. Create the profiles table

1. Open your project at [supabase.com/dashboard](https://supabase.com/dashboard).
2. Go to **SQL Editor > New query**.
3. Paste the contents of `supabase/profiles.sql` and click **Run**.

It's safe to run if you already have a `profiles` table: it only adds what's missing.

### 2. Create Google sign-in credentials

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and create a project (or pick one).
2. **APIs & Services > OAuth consent screen** (called **Google Auth Platform** in newer consoles):
   - User type: **External**. App name: `Tuck`. Add your support email.
   - Under **Authorized domains**, add `supabase.co` (and your own domain later, if you get one).
   - Scopes: `email`, `profile`, `openid` are enough.
   - While the app is in **Testing**, only the test users you list can sign in. Click **Publish app** when you're ready for everyone.
3. **APIs & Services > Credentials > Create credentials > OAuth client ID**:
   - Application type: **Web application**.
   - **Authorized JavaScript origins**: `https://calm-kleicha-8f3c80.netlify.app`
   - **Authorized redirect URIs**: `https://fvyvsrvaaoaxrbutlubw.supabase.co/auth/v1/callback`
     (this is your Supabase URL followed by `/auth/v1/callback`; Supabase shows it on the Google provider page too).
4. Copy the **Client ID** and **Client secret**.

### 3. Turn on Google in Supabase

1. In Supabase: **Authentication > Sign In / Providers > Google**. Turn it on.
2. Paste the Client ID and Client secret. Save.
3. **Authentication > URL Configuration**:
   - **Site URL**: `https://calm-kleicha-8f3c80.netlify.app`
   - **Redirect URLs**: add `https://calm-kleicha-8f3c80.netlify.app/**`
     (and `http://localhost:8888/**` if you test locally).

Without the Redirect URL, Google sign-in sends people to the Site URL instead of their profile.

### 4. Deploy

Upload this folder to Netlify (drag and drop it on the site's **Deploys** page), or connect this
GitHub repo in Netlify with no build command and publish directory `.`.

Then open the site, click **Log in > Continue with Google**, and you should land on your profile.

## Running locally

Any static server works, for example:

```bash
npx serve -l 8888 .
```

Then open http://localhost:8888 (remember the localhost Redirect URL from step 3).

## Troubleshooting

- **"Unsupported provider: provider is not enabled"**: step 3 isn't saved.
- **Google says `redirect_uri_mismatch`**: the redirect URI in step 2.3 must exactly match your Supabase callback URL.
- **"Could not load your profile" / column does not exist**: run `supabase/profiles.sql` (step 1).
- **Signed in but landed on the home page**: add the Redirect URL in step 3.
- **"Access blocked: app has not completed verification"**: add yourself as a test user, or publish the consent screen.
