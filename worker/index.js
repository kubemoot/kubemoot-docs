// Front of the static site. Every request passes through here so that the www host can
// redirect to the apex; everything else is served from the built site (the ASSETS
// binding), including the 404 page and its 404 status for unknown paths.
const APEX = "kubemoot.org";
const WWW = "www.kubemoot.org";

export function redirectTarget(requestUrl) {
  const url = new URL(requestUrl);
  if (url.hostname !== WWW) {
    return null;
  }
  url.hostname = APEX;
  return url.toString();
}

export default {
  async fetch(request, env) {
    const target = redirectTarget(request.url);
    if (target) {
      return Response.redirect(target, 301);
    }
    return env.ASSETS.fetch(request);
  },
};
