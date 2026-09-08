// Harvest every TPL fixture from WhoScored.
//
// This is a browser snippet, not a script: whoscored.com answers plain HTTP
// with a Cloudflare 403, so the requests have to come from a page that has
// already loaded normally. Open
// https://www.whoscored.com/regions/217/tournaments/382 and run this in the
// console (or through browser automation), then collect window.__rows.
//
// The fixture feed is same-origin JSON. `d` accepts YYYYMM and returns that
// whole month, so a season costs ~14 requests instead of one per match.
//
//     /tournaments/{stageId}/data/?d=YYYYMM&isAggregate=false
//
// Each season has its own stageId, read from that season's own page. Known
// ids are in whoscored_stages.json; re-derive them if WhoScored renumbers.

window.__stages = [...document.querySelectorAll('#seasons option')].map(o => ({
  season: o.textContent.trim(),
  seasonId: o.value.match(/Seasons\/(\d+)/)?.[1],
  href: o.value,
}));

// stageId is not in the dropdown, only in each season page's inline script.
for (const s of window.__stages) {
  const html = await (await fetch(s.href, {headers: {'X-Requested-With': 'XMLHttpRequest'}})).text();
  s.stageId = html.match(/stageId['"\s:=]+(\d+)/)?.[1];
  await new Promise(r => setTimeout(r, 600));
}

window.__fx = {};
for (const st of window.__stages) {
  const y0 = parseInt(st.season.slice(0, 4));
  const months = [];
  for (let m = 7; m <= 12; m++) months.push(`${y0}${String(m).padStart(2, '0')}`);
  for (let m = 1; m <= 8; m++) months.push(`${y0 + 1}${String(m).padStart(2, '0')}`);

  const seen = new Map();   // by match id: months overlap at season boundaries
  for (const d of months) {
    const r = await fetch(`/tournaments/${st.stageId}/data/?d=${d}&isAggregate=false`,
                          {headers: {'X-Requested-With': 'XMLHttpRequest'}});
    if (r.status === 200) {
      const j = await r.json();
      for (const m of (j.tournaments?.[0]?.matches || [])) {
        seen.set(m.id, {
          id: m.id, st: m.startTimeUtc || m.startTime, status: m.status,
          hid: m.homeTeamId, h: m.homeTeamName, aid: m.awayTeamId, a: m.awayTeamName,
          hs: m.homeScore, as: m.awayScore,
        });
      }
    }
    await new Promise(r => setTimeout(r, 300));
  }
  window.__fx[st.season] = [...seen.values()];
  console.log(st.season, seen.size);
}

// Written in the compact form normalize_whoscored.py reads: a season list, a
// separator, then one match per line.
const seasons = Object.keys(window.__fx).sort();
window.__teams = {};
window.__rows = [];
for (const s of seasons) for (const m of window.__fx[s]) {
  window.__teams[m.hid] = m.h;
  window.__teams[m.aid] = m.a;
  const t = (m.st || '').replace(/[-:TZ]/g, '').slice(0, 12);
  window.__rows.push([seasons.indexOf(s), m.id, t, m.hid, m.aid, m.hs ?? '', m.as ?? '', m.status].join(','));
}
// Save teams.json and fixtures.txt (seasons, '=====', rows).
