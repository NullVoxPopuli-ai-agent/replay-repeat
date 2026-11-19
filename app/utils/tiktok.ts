/**
 * TikTok post ids are 19 digits now. Older ones are shorter.
 */
const ID = /^\d{15,21}$/;

function urlOf(input: string): URL | undefined {
  try {
    return new URL(input.includes("://") ? input : `https://${input}`);
  } catch {
    return undefined;
  }
}

/**
 * Finds the video id in what a user pastes:
 *
 * - a bare id, `7106594312292453675`
 * - `tiktok.com/@user/video/<id>`
 * - `tiktok.com/player/v1/<id>`, `/embed/v2/<id>`, `/embed/<id>`
 */
export function tikTokIdOf(text: string): string | undefined {
  const input = text.trim();

  if (ID.test(input)) return input;

  const url = urlOf(input);

  if (!url) return undefined;

  const host = url.hostname.replace(/^(www|m)\./, "");

  if (host !== "tiktok.com") return undefined;

  const parts = url.pathname.split("/").filter(Boolean);
  let id: string | undefined;

  if (parts[0]?.startsWith("@") && parts[1] === "video") {
    id = parts[2];
  } else if (parts[0] === "player" || (parts[0] === "embed" && parts[1] === "v2")) {
    id = parts[2];
  } else if (parts[0] === "embed") {
    id = parts[1];
  }

  return id && ID.test(id) ? id : undefined;
}

/**
 * The share button in the TikTok app gives a short link with no video id in it,
 * such as `vm.tiktok.com/ZM...` or `tiktok.com/t/ZT...`.
 */
export function isTikTokShortLink(text: string): boolean {
  const url = urlOf(text.trim());

  if (!url) return false;

  const host = url.hostname.replace(/^www\./, "");

  return (
    host === "vm.tiktok.com" ||
    host === "vt.tiktok.com" ||
    (host === "tiktok.com" && url.pathname.startsWith("/t/"))
  );
}

/**
 * The embed player starts only after a click in it, or with autoplay.
 * Autoplay needs the sound off, so the video starts muted.
 * The app hides TikTok's own controls and uses its own.
 */
export function tikTokPlayerUrl(id: string): string {
  const params = new URLSearchParams({
    autoplay: "1",
    muted: "1",
    controls: "0",
    timestamp: "0",
    closed_caption: "0",
    rel: "0",
    native_context_menu: "0",
  });

  return `https://www.tiktok.com/player/v1/${id}?${params}`;
}
