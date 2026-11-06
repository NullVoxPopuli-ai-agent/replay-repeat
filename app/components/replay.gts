import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";

import { modifier } from "ember-modifier";
import { Button, ToggleButton } from "nvp.ui";

import { RangeSlider } from "#pr-nvp.ui-122/range-slider.gts";
import { History } from "#utils/history.ts";
import { formatTime } from "#utils/time.ts";
import Minus from "~icons/mdi/minus";
import Plus from "~icons/mdi/plus";
import Redo from "~icons/mdi/redo";
import Repeat from "~icons/mdi/repeat";
import RepeatOff from "~icons/mdi/repeat-off";
import SkipPrevious from "~icons/mdi/skip-previous";
import Undo from "~icons/mdi/undo";

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
 * The speeds that YouTube supports, so files and YouTube have the same steps.
 */
const RATES = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

interface Markers {
  start: number;
  end: number | undefined;
}

const sameMarkers = (a: Markers, b: Markers) => a.start === b.start && a.end === b.end;

const formatRate = (rate: number) => `${rate}×`;

/**
 * After a seek, a player can report the old time for a few frames.
 * The loop waits this long before it checks the time again.
 */
const SEEK_SETTLE_MS = 250;

function toStep(seconds: number) {
  return Math.round(seconds / STEP) * STEP;
}

/**
 * Keys in these elements are text for the element, not shortcuts.
 * A range input, such as a marker thumb, takes no text.
 */
const TEXT_ENTRY =
  "textarea, select, input:not([type=range], [type=checkbox], [type=radio], [type=button], [type=submit], [type=file])";

function isTyping(target: EventTarget | null) {
  if (!(target instanceof HTMLElement)) return false;

  return target.isContentEditable || target.closest(TEXT_ENTRY) !== null;
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

  @tracked rate = 1;

  markers = new History<Markers>({ start: 0, end: undefined }, sameMarkers);

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

  toLoopStart = () => {
    this.seek(this.loopStart);
  };

  setRate(rate: number) {
    this.player?.setRate(rate);
    this.rate = rate;
  }

  get canSlowDown() {
    return RATES.some((rate) => rate < this.rate);
  }

  get canSpeedUp() {
    return RATES.some((rate) => rate > this.rate);
  }

  slower = () => {
    this.setRate(RATES.findLast((rate) => rate < this.rate) ?? this.rate);
  };

  faster = () => {
    this.setRate(RATES.find((rate) => rate > this.rate) ?? this.rate);
  };

  /**
   * Live while a marker moves. `recordMarkers` makes the undo step when the move ends.
   */
  setMarkers = (start: number, end: number) => {
    this.chosenStart = start;
    this.chosenEnd = end;
  };

  recordMarkers = () => {
    this.markers.record({ start: this.chosenStart, end: this.chosenEnd });
  };

  applyMarkers(markers: Markers | undefined) {
    if (!markers) return;

    this.chosenStart = markers.start;
    this.chosenEnd = markers.end;
  }

  undo = () => {
    this.applyMarkers(this.markers.undo());
  };

  redo = () => {
    this.applyMarkers(this.markers.redo());
  };

  markStart = () => {
    this.chosenStart = Math.max(0, Math.min(toStep(this.now), this.loopEnd - STEP));
    this.recordMarkers();
  };

  markEnd = () => {
    this.chosenEnd = Math.min(this.duration, Math.max(toStep(this.now), this.loopStart + STEP));
    this.recordMarkers();
  };

  resetMarkers = () => {
    this.chosenStart = 0;
    this.chosenEnd = undefined;
    this.recordMarkers();
  };

  tick = () => {
    const { player } = this;

    if (!player) return;

    const time = player.currentTime;

    if (time !== this.now) this.now = time;
    if (player.duration !== this.duration) this.duration = player.duration;
    if (player.paused !== this.paused) this.paused = player.paused;

    /**
     * YouTube's own settings menu can change the speed too.
     */
    if (player.rate !== this.rate) this.rate = player.rate;

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
    if (isTyping(event.target)) return;
    if (event.altKey) return;

    if (event.ctrlKey || event.metaKey) {
      this.onUndoKey(event);

      return;
    }

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
      case "r":
      case "R":
        this.toLoopStart();

        break;
      case "<":
        this.slower();

        break;
      case ">":
        this.faster();

        break;
      default:
        return;
    }

    event.preventDefault();
  };

  /**
   * Ctrl or Cmd with Z undoes, with Shift+Z or Y it redoes, as in other apps.
   */
  onUndoKey(event: KeyboardEvent) {
    const key = event.key.toLowerCase();

    if (key === "z" && !event.shiftKey) {
      this.undo();
    } else if ((key === "z" && event.shiftKey) || key === "y") {
      this.redo();
    } else {
      return;
    }

    event.preventDefault();
  }

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
          <div class="replay__status">
            <span class="replay__time" data-test-time>
              <span data-test-now>{{formatTime this.now}}</span>
              /
              <span data-test-duration>{{formatTime this.duration}}</span>
            </span>

            {{#if this.looping}}
              <span class="replay__looping" data-test-looping>
                <Repeat aria-hidden="true" />
                Looping
                {{formatTime this.loopStart}}
                to
                {{formatTime this.loopEnd}}
              </span>
            {{/if}}
          </div>

          <RangeSlider
            class="replay__markers"
            data-looping={{this.looping}}
            @label="Loop markers"
            @startLabel="Loop start"
            @endLabel="Loop end"
            @max={{this.duration}}
            @step={{STEP}}
            @start={{this.loopStart}}
            @end={{this.loopEnd}}
            @onChange={{this.setMarkers}}
            @onCommit={{this.recordMarkers}}
            @formatValue={{formatTime}}
            as |track|
          >
            <span class="replay__playhead" style={{playheadStyle (track.position this.now)}}></span>
          </RangeSlider>

          <div class="replay__buttons">
            <div class="replay__playback">
              <div role="group" aria-label="Playback">
                <Button @variant="primary" @onClick={{this.togglePlay}} data-test-play>
                  {{if this.paused "Play" "Pause"}}
                </Button>
                <ToggleButton
                  @pressed={{this.looping}}
                  @variant={{if this.looping "primary"}}
                  @onClick={{this.toggleLoop}}
                  data-test-loop
                >
                  {{#if this.looping}}
                    <Repeat aria-hidden="true" />
                  {{else}}
                    <RepeatOff aria-hidden="true" />
                  {{/if}}
                  Loop
                </ToggleButton>
              </div>

              <div role="group" aria-label="Speed" class="replay__speed">
                <Button
                  aria-label="Slower"
                  @disabled={{unless this.canSlowDown "Already the slowest speed"}}
                  @onClick={{this.slower}}
                  data-test-slower
                ><Minus aria-hidden="true" /></Button>
                <span class="replay__rate" data-test-rate>{{formatRate this.rate}}</span>
                <Button
                  aria-label="Faster"
                  @disabled={{unless this.canSpeedUp "Already the fastest speed"}}
                  @onClick={{this.faster}}
                  data-test-faster
                ><Plus aria-hidden="true" /></Button>
              </div>

              <Button @onClick={{this.toLoopStart}} data-test-to-loop-start>
                <:start><SkipPrevious aria-hidden="true" /></:start>
                <:default>Go to loop start</:default>
              </Button>
            </div>

            <div role="group" aria-label="Loop markers" class="replay__marker-buttons">
              <Button @onClick={{this.markStart}}>Set start here</Button>
              <Button @onClick={{this.markEnd}}>Set end here</Button>
              <Button
                aria-label="Undo"
                @disabled={{unless this.markers.canUndo "No marker move to undo"}}
                @onClick={{this.undo}}
                data-test-undo
              ><Undo aria-hidden="true" /></Button>
              <Button
                aria-label="Redo"
                @disabled={{unless this.markers.canRedo "No marker move to redo"}}
                @onClick={{this.redo}}
                data-test-redo
              ><Redo aria-hidden="true" /></Button>
              <Button @variant="bare" @onClick={{this.resetMarkers}} data-test-reset>Reset markers</Button>
            </div>
          </div>
        </div>

        <Shortcuts />
      {{/if}}
    </section>
  </template>
}
