import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";

import { modifier } from "ember-modifier";
import { Button, ToggleButton } from "nvp.ui";

import { RangeSlider } from "#pr-nvp.ui-122/range-slider.gts";
import { formatTime } from "#utils/time.ts";

import { Shortcuts } from "./shortcuts.gts";
import { VideoFile } from "./video-file.gts";
import { YouTubeVideo } from "./video-youtube.gts";

import type { Player } from "#utils/player.ts";
import type { Source } from "#utils/source.ts";

interface Signature {
  Args: {
    source: Source;
  };
}

/**
 * Markers move in tenths of a second.
 */
const STEP = 0.1;

/**
 * After a seek, a player can report the old time for a few frames.
 * The loop waits this long before it checks the time again.
 */
const SEEK_SETTLE_MS = 250;

function toStep(seconds: number) {
  return Math.round(seconds / STEP) * STEP;
}

function isTyping(target: EventTarget | null) {
  if (!(target instanceof HTMLElement)) return false;

  return target.isContentEditable || target.closest("input, textarea, select") !== null;
}

const playheadStyle = (percent: number) => htmlSafe(`left: ${percent}%`);

export class Replay extends Component<Signature> {
  @tracked player: Player | undefined;
  @tracked now = 0;
  @tracked duration = 0;
  @tracked paused = true;
  @tracked looping = false;
  @tracked chosenStart = 0;

  /**
   * `undefined` means the end of the video,
   * which is unknown for YouTube until the video loads.
   */
  @tracked chosenEnd: number | undefined;

  #seekedAt = 0;

  get file() {
    return this.args.source.kind === "file" ? this.args.source.file : undefined;
  }

  get youTubeId() {
    return this.args.source.kind === "youtube" ? this.args.source.id : undefined;
  }

  get loopStart() {
    return Math.min(this.chosenStart, this.duration);
  }

  get loopEnd() {
    return Math.min(this.chosenEnd ?? this.duration, this.duration);
  }

  ready = (player: Player) => {
    this.player = player;
    this.duration = player.duration;
  };

  seek(seconds: number) {
    if (!this.player) return;

    this.#seekedAt = performance.now();
    this.player.seek(seconds);
    this.now = seconds;
  }

  back = (seconds: number) => {
    const floor = this.looping ? this.loopStart : 0;

    this.seek(Math.max(this.now - seconds, floor));
  };

  togglePlay = () => {
    if (!this.player) return;

    if (this.player.paused) {
      this.player.play();
    } else {
      this.player.pause();
    }
  };

  toggleLoop = () => {
    this.looping = !this.looping;
  };

  setMarkers = (start: number, end: number) => {
    this.chosenStart = start;
    this.chosenEnd = end;
  };

  markStart = () => {
    this.chosenStart = Math.max(0, Math.min(toStep(this.now), this.loopEnd - STEP));
  };

  markEnd = () => {
    this.chosenEnd = Math.min(this.duration, Math.max(toStep(this.now), this.loopStart + STEP));
  };

  resetMarkers = () => {
    this.chosenStart = 0;
    this.chosenEnd = undefined;
  };

  tick = () => {
    const { player } = this;

    if (!player) return;

    const time = player.currentTime;

    if (time !== this.now) this.now = time;
    if (player.duration !== this.duration) this.duration = player.duration;
    if (player.paused !== this.paused) this.paused = player.paused;

    if (!this.looping || performance.now() - this.#seekedAt < SEEK_SETTLE_MS) return;

    /**
     * A video that the user paused stays where it is.
     * A video at its end is paused too, but it must loop.
     */
    if (player.paused && !player.ended) return;

    if (time >= this.loopEnd || player.ended) {
      this.seek(this.loopStart);
      player.play();
    }
  };

  onKey = (event: KeyboardEvent) => {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    if (isTyping(event.target)) return;

    if (event.key >= "0" && event.key <= "9" && event.key.length === 1) {
      event.preventDefault();
      this.back(event.key === "0" ? 10 : Number(event.key));

      return;
    }

    switch (event.key) {
      case "[":
        this.markStart();

        break;
      case "]":
        this.markEnd();

        break;
      case "l":
      case "L":
        this.toggleLoop();

        break;
      case "k":
      case "K":
        this.togglePlay();

        break;
      default:
        return;
    }

    event.preventDefault();
  };

  /**
   * Runs for as long as the replay is on the page:
   *
   * - reads the time of the player on each frame, for the playhead and the loop
   * - listens for shortcut keys on the whole page
   * - takes the focus back from the YouTube iframe, which keeps key presses for itself
   */
  connect = modifier((element: HTMLElement) => {
    const loop = () => {
      this.tick();
      frame = requestAnimationFrame(loop);
    };
    let frame = requestAnimationFrame(loop);

    const onBlur = () => {
      setTimeout(() => {
        if (
          document.activeElement instanceof HTMLIFrameElement &&
          element.contains(document.activeElement)
        ) {
          element.focus();
        }
      });
    };

    document.addEventListener("keydown", this.onKey);
    window.addEventListener("blur", onBlur);

    return () => {
      cancelAnimationFrame(frame);
      document.removeEventListener("keydown", this.onKey);
      window.removeEventListener("blur", onBlur);
    };
  });

  <template>
    <section class="replay" tabindex="-1" aria-label="Player" data-test-replay {{this.connect}}>
      <div class="replay__stage">
        {{#if this.file}}
          <VideoFile @file={{this.file}} @onReady={{this.ready}} />
        {{else if this.youTubeId}}
          <YouTubeVideo @id={{this.youTubeId}} @onReady={{this.ready}} />
        {{/if}}
      </div>

      {{#if this.player}}
        <div class="replay__controls surface">
          <div class="replay__time" data-test-time>
            <span data-test-now>{{formatTime this.now}}</span>
            /
            <span data-test-duration>{{formatTime this.duration}}</span>
          </div>

          <RangeSlider
            class="replay__markers"
            @label="Loop markers"
            @startLabel="Loop start"
            @endLabel="Loop end"
            @max={{this.duration}}
            @step={{STEP}}
            @start={{this.loopStart}}
            @end={{this.loopEnd}}
            @onChange={{this.setMarkers}}
            @formatValue={{formatTime}}
            as |track|
          >
            <span class="replay__playhead" style={{playheadStyle (track.position this.now)}}></span>
          </RangeSlider>

          <div class="replay__buttons">
            <Button @variant="primary" @onClick={{this.togglePlay}} data-test-play>
              {{if this.paused "Play" "Pause"}}
            </Button>
            <ToggleButton @pressed={{this.looping}} @onClick={{this.toggleLoop}} data-test-loop>
              Loop
            </ToggleButton>
            <Button @onClick={{this.markStart}}>Set start here</Button>
            <Button @onClick={{this.markEnd}}>Set end here</Button>
            <Button @variant="bare" @onClick={{this.resetMarkers}} data-test-reset>Reset markers</Button>
          </div>
        </div>

        <Shortcuts />
      {{/if}}
    </section>
  </template>
}
