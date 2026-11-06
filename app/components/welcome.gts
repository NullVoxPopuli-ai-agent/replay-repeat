import type { TOC } from "@ember/component/template-only";

/**
 * The mascot: a very happy TV.
 *
 * It bobs, blinks, and sparkles. Under `prefers-reduced-motion`, it holds still.
 */
const HappyTv: TOC<{ Element: SVGSVGElement }> = <template>
  <svg viewBox="0 0 200 175" aria-hidden="true" ...attributes>
    <g fill="#ffd84d">
      <path class="welcome__sparkle" d="M24 33Q24 42 33 42Q24 42 24 51Q24 42 15 42Q24 42 24 33Z" />
      <path
        class="welcome__sparkle welcome__sparkle--late"
        d="M182 27Q182 34 189 34Q182 34 182 41Q182 34 175 34Q182 34 182 27Z"
      />
      <path
        class="welcome__sparkle welcome__sparkle--later"
        d="M178 116Q178 126 188 126Q178 126 178 136Q178 126 168 126Q178 126 178 116Z"
      />
      <path
        class="welcome__sparkle welcome__sparkle--late"
        d="M18 126Q18 132 24 132Q18 132 18 138Q18 132 12 132Q18 132 18 126Z"
      />
    </g>

    <g fill="#ff7eb6">
      <path
        class="welcome__heart"
        d="M178 87.4C169.6 82.6 174.4 76 178 80.2C181.6 76 186.4 82.6 178 87.4Z"
      />
      <path
        class="welcome__heart welcome__heart--late"
        d="M22 100.5C15 96.5 19 91 22 94.5C25 91 29 96.5 22 100.5Z"
      />
    </g>

    <g class="welcome__bob">
      <rect x="56" y="140" width="18" height="22" rx="9" fill="#ff8fbf" />
      <rect x="126" y="140" width="18" height="22" rx="9" fill="#ff8fbf" />

      <path
        d="M86 52 72 26M114 52 128 26"
        stroke="#ff8fbf"
        stroke-width="4"
        stroke-linecap="round"
      />
      <path d="M70 28.1C57.4 20.9 64.6 11 70 17.3C75.4 11 82.6 20.9 70 28.1Z" fill="#ff5fa2" />
      <path
        d="M130 28.1C117.4 20.9 124.6 11 130 17.3C135.4 11 142.6 20.9 130 28.1Z"
        fill="#ff5fa2"
      />

      <rect x="30" y="48" width="140" height="104" rx="30" fill="#ffb6d5" />
      <rect x="36" y="52" width="128" height="40" rx="22" fill="#ffd0e4" />
      <rect x="44" y="60" width="112" height="74" rx="22" fill="#fff5fa" />
      <path d="M54 76q5-8 16-9" stroke="#fff" stroke-width="5" stroke-linecap="round" fill="none" />

      <g class="welcome__eyes">
        <ellipse cx="78" cy="96" rx="12" ry="14" fill="#3b2a4d" />
        <ellipse cx="122" cy="96" rx="12" ry="14" fill="#3b2a4d" />
        <circle cx="82" cy="90" r="5" fill="#fff" />
        <circle cx="126" cy="90" r="5" fill="#fff" />
        <path
          d="M74 99.5Q74 102 76.5 102Q74 102 74 104.5Q74 102 71.5 102Q74 102 74 99.5Z"
          fill="#fff"
        />
        <path
          d="M118 99.5Q118 102 120.5 102Q118 102 118 104.5Q118 102 115.5 102Q118 102 118 99.5Z"
          fill="#fff"
        />
        <path
          d="M67 88 61 83M66 95 59 94M133 88 139 83M134 95 141 94"
          stroke="#3b2a4d"
          stroke-width="2.5"
          stroke-linecap="round"
        />
      </g>

      <ellipse cx="60" cy="114" rx="10" ry="6" fill="#ff7eb6" opacity="0.7" />
      <ellipse cx="140" cy="114" rx="10" ry="6" fill="#ff7eb6" opacity="0.7" />
      <path
        d="M55 117l2-5M60 117l2-5M65 117l2-5M135 117l2-5M140 117l2-5M145 117l2-5"
        stroke="#fff"
        stroke-width="1.5"
        stroke-linecap="round"
      />

      <ellipse cx="100" cy="116" rx="4" ry="3.5" fill="#ff6b9a" />
      <path
        d="M91 110q4.5 6 9 0q4.5 6 9 0"
        stroke="#3b2a4d"
        stroke-width="3"
        stroke-linecap="round"
        stroke-linejoin="round"
        fill="none"
      />

      <circle cx="56" cy="143" r="4" fill="#c9b6ff" />
      <circle cx="68" cy="143" r="4" fill="#c9b6ff" />
      <path
        d="M141 146.5C134 142.5 138 137 141 140.5C144 137 148 142.5 141 146.5Z"
        fill="#ff5fa2"
      />

      <path d="M152 50 136 40q-4 10 0 20Z" fill="#ff8cc0" />
      <path d="M152 50 168 40q4 10 0 20Z" fill="#ff8cc0" />
      <circle cx="152" cy="50" r="5.5" fill="#ff5fa2" />
    </g>
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
