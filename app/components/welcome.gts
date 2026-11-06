import type { TOC } from "@ember/component/template-only";

/**
 * A small TV with a happy face, in the colors of the theme.
 */
const HappyTv: TOC<{ Element: SVGSVGElement }> = <template>
  <svg viewBox="0 0 120 110" aria-hidden="true" ...attributes>
    <path d="M44 22 32 6M76 22 88 6" class="welcome__line" />
    <circle cx="32" cy="6" r="4" class="welcome__fill" />
    <circle cx="88" cy="6" r="4" class="welcome__fill" />
    <rect x="6" y="22" width="108" height="76" rx="16" class="welcome__tv" />
    <rect x="16" y="32" width="88" height="56" rx="10" class="welcome__screen" />
    <circle cx="44" cy="54" r="5" class="welcome__face" />
    <circle cx="76" cy="54" r="5" class="welcome__face" />
    <circle cx="34" cy="66" r="5" class="welcome__cheek" />
    <circle cx="86" cy="66" r="5" class="welcome__cheek" />
    <path d="M50 68q10 9 20 0" class="welcome__smile" />
    <path d="M30 98v8M90 98v8" class="welcome__line" />
  </svg>
</template>;

export const Welcome: TOC<object> = <template>
  <section class="welcome" aria-labelledby="welcome-title" data-test-welcome>
    <HappyTv class="welcome__art" />

    <div class="welcome__text">
      <h2 id="welcome-title">Pick a video to start</h2>
      <p>Paste a YouTube link, or drop a video file anywhere on this page.</p>
      <p class="welcome__why">
        Why only these two? So the app needs no server and no permissions. A file plays from your
        disk and is never uploaded. A YouTube link plays in YouTube's own player.
      </p>
    </div>
  </section>
</template>;
