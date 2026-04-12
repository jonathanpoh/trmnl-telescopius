const TELESCOPIUS_URL =
  'https://api.telescopius.com/v2.0/targets/highlights' +
  '?types=DEEP_SKY_OBJECT,COMET' +
  '&lat=38.563&lon=-8.881' +
  '&timezone=Europe/Lisbon' +
  '&min_alt=20' +
  '&time_format=24hr' +
  '&compute_current=1';

export default {
  async fetch(request, env) {
    const response = await fetch(TELESCOPIUS_URL, {
      headers: {
        'Authorization': `Key ${env.TELESCOPIUS_API_KEY}`,
      },
    });

    const body = await response.text();

    return new Response(body, {
      status: response.status,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
