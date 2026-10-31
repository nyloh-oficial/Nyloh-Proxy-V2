# Nyloh Browser

A browser-style web portal for GitHub Pages. It includes username/password accounts, personal shortcuts, search, an embedded browsing pane, direct external opening, private user-to-user messaging, message pop-up notifications, and owner moderation.

## Important limitations

- GitHub Pages is static hosting. Real accounts, bans, and cross-device messaging need a backend. This project uses Supabase.
- This is a browser-style web app, **not a full web proxy**. Websites such as Google, YouTube, and many others block iframe embedding. Search uses DuckDuckGo, and the ↗ button opens the current site in a normal browser tab.
- The AI shortcut opens ChatGPT. Free access and usage limits are controlled by that service; no third-party AI can honestly be promised to be unlimited and free.
- The owner can ban/unban accounts from the control room. Changing another user's password requires a trusted server-side admin function and is intentionally not exposed in this static client. Users can reset/change their own password through Supabase's supported auth flow; add a server-side Edge Function if owner-managed password resets are required.
- The requested starter password should be treated as exposed because it was shared in chat. Use a unique password and change it before real use.

## Setup

1. Create a project at [Supabase](https://supabase.com/).
2. In Supabase, open **SQL Editor**, paste `schema.sql`, and run it.
3. In Supabase **Authentication → Providers → Email**, disable email confirmations for this username-only demo. Supabase still uses an internal synthetic email address for each username.
4. Open `app.js` and replace `YOUR_SUPABASE_PROJECT_URL` and `YOUR_SUPABASE_ANON_KEY` with the project's URL and public anon key. Never use the `service_role` key in browser code.
5. Publish this folder to a GitHub repository. In repository **Settings → Pages**, choose deploy from the `main` branch and `/ (root)`.
6. Open the published GitHub Pages URL and create the owner account using username `nyloh51` and a new strong password.
7. In Supabase SQL Editor, promote the owner:
   ```sql
   update public.profiles set role='admin' where username='nyloh51';
   ```
8. Sign out and sign back in. The gear icon opens owner controls.

## Security notes

The database enforces message privacy and admin-only moderation through Row Level Security and database functions. Username lookup helpers expose only the minimum username/ID data needed for messaging. The public anon key is designed to be present in frontend code; the service-role key is secret and must never be published. Use HTTPS (GitHub Pages provides it). Consider adding rate limits, abuse reporting, and a proper email/password recovery flow before opening this to the public.

## What has been checked

- JavaScript parses successfully with Node.js syntax validation.
- The ZIP contains all five required project files: `index.html`, `styles.css`, `app.js`, `schema.sql`, and this README.
- The app cannot complete real sign-in, cross-device messaging, or moderation until you add your own Supabase URL/key and run the SQL setup. Those steps are required, not optional.
- Browsing is limited by browser iframe restrictions. Use the external-open control when a site refuses to display inside the app.

## Deploy with jsDelivr

GitHub Pages is the website host. jsDelivr is a CDN for static files, not a host for a complete interactive website. You can use jsDelivr to serve individual files after publishing, but users should visit the GitHub Pages URL to use the app.


## Serve the site through jsDelivr

jsDelivr can serve the files from a **public GitHub repository**. It is a CDN URL, not a separate website-hosting dashboard.

1. Create a public GitHub repository, for example `nyloh-browser`.
2. Upload all five project files (`index.html`, `styles.css`, `app.js`, `schema.sql`, `README.md`) to the repository root and commit them.
3. Make sure you completed the Supabase setup above and put your Supabase Project URL and anon/public key in `app.js`.
4. Open this URL, replacing `YOUR_GITHUB_USERNAME` with your GitHub username:
   `https://cdn.jsdelivr.net/gh/YOUR_GITHUB_USERNAME/nyloh-browser@main/index.html`
5. If jsDelivr has cached an older version after an update, use a version tag (recommended) such as `@v1.0.1` after creating that Git tag, or wait for the CDN cache to refresh.

**Example:** `https://cdn.jsdelivr.net/gh/octocat/nyloh-browser@main/index.html` (example only; it will work only if that exact public repository exists).

For a normal shareable website address with a homepage URL, GitHub Pages is generally the better choice: `https://YOUR_GITHUB_USERNAME.github.io/nyloh-browser/`. You can enable it in GitHub → repository Settings → Pages → Deploy from a branch → `main` → `/ (root)`. Both options serve the same static app; neither turns it into a full browser proxy.
