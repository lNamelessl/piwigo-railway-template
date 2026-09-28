const fs = require('fs');
const path = require('path');
const TOKEN = fs.readFileSync(path.join(process.env.TEMP, 'rwy_token.txt'), 'utf8').trim();
async function gql(query, variables) {
  const r = await fetch('https://backboard.railway.com/graphql/v2', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + TOKEN, 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables }),
  });
  const j = await r.json();
  if (j.errors) { console.error('ERRORS:', JSON.stringify(j.errors).slice(0, 600)); process.exitCode = 1; }
  return j.data;
}
module.exports = { gql };
if (require.main === module) {
  const q = process.argv[2], v = process.argv[3] ? JSON.parse(process.argv[3]) : {};
  gql(q, v).then(d => console.log(JSON.stringify(d, null, 1).slice(0, 3000)));
}
