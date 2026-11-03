// Shared setup used by every page.
(function () {
  var cfg = window.TUCK_CONFIG || {};
  var configured = cfg.SUPABASE_URL && cfg.SUPABASE_URL.indexOf('YOUR-PROJECT-ID') === -1;

  window.sb = configured ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY) : null;
  window.tuckConfigured = configured;

  // Returns the logged-in user, or null.
  window.getUser = async function () {
    if (!window.sb) return null;
    var res = await window.sb.auth.getSession();
    return res.data.session ? res.data.session.user : null;
  };

  // Swap the nav button between "Log in" and "My profile".
  document.addEventListener('DOMContentLoaded', async function () {
    var btn = document.getElementById('nav-account');
    if (!btn) return;
    var user = await window.getUser();
    if (user) {
      btn.textContent = 'My profile';
      btn.href = 'profile.html';
    }
  });

  // Small helper for status messages.
  window.showMsg = function (el, text, kind) {
    el.textContent = text;
    el.className = 'msg ' + (kind || '');
    el.hidden = !text;
  };
})();
