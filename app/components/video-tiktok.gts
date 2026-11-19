import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

import { modifier } from "ember-modifier";

import { isTikTokMessage, type Player, TIKTOK_ORIGIN, TikTokPlayer } from "#utils/player.ts";
import { tikTokPlayerUrl } from "#utils/tiktok.ts";

interface Signature {
  Args: {
    id: string;
    onReady: (player: Player) => void;
  };
}

/**
 * Error codes of the TikTok player, from its code:
 * https://developers.tiktok.com/doc/embed-player
 */
const ERRORS: Record<number, string> = {
  1001: "That TikTok video does not exist, or it is private.",
  1002: "The owner of that video does not allow it on other sites.",
  2005: "TikTok got too many requests from this site. Try again later.",
};

/**
 * Codes that do not stop the player.
 * Without autoplay, a click on TikTok's play button starts the player.
 */
const NOT_FATAL = new Set([3001, 3002]);

function errorCodeOf(value: unknown): number | undefined {
  if (typeof value !== "object" || value === null) return undefined;

  const code = (value as { errorCode?: unknown }).errorCode;

  return typeof code === "number" ? code : undefined;
}

export class TikTokVideo extends Component<Signature> {
  @tracked error: string | undefined;

  get src() {
    return tikTokPlayerUrl(this.args.id);
  }

  /**
   * The app gets the player when the duration is known,
   * because the loop end and the timeline need it.
   */
  connect = modifier((iframe: HTMLIFrameElement) => {
    let player: TikTokPlayer | undefined;
    let ready = false;

    const onMessage = (event: MessageEvent) => {
      if (event.origin !== TIKTOK_ORIGIN || event.source !== iframe.contentWindow) return;
      if (!isTikTokMessage(event.data)) return;

      const message = event.data;

      if (message.type === "onPlayerError") {
        const code = errorCodeOf(message.value) ?? 0;

        if (!NOT_FATAL.has(code)) {
          this.error = ERRORS[code] ?? `The TikTok player stopped (${code}).`;
        }

        return;
      }

      if (!player && iframe.contentWindow) player = new TikTokPlayer(iframe.contentWindow);
      if (!player) return;

      player.receive(message);

      if (!ready && player.duration > 0) {
        ready = true;
        this.args.onReady(player);
      }
    };

    window.addEventListener("message", onMessage);

    return () => {
      window.removeEventListener("message", onMessage);
    };
  });

  <template>
    {{#if this.error}}
      <p class="replay__error" role="alert">{{this.error}}</p>
    {{else}}
      <iframe
        class="replay__media"
        src={{this.src}}
        title="TikTok video"
        allow="autoplay; encrypted-media; fullscreen; picture-in-picture"
        data-test-tiktok
        {{this.connect}}
      ></iframe>
    {{/if}}
  </template>
}
