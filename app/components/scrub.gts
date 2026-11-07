import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";

import { formatTime } from "#utils/time.ts";

interface Signature {
  Args: {
    duration: number;

    /**
     * `done` is false while the pointer is still down.
     */
    onSeek: (seconds: number, done: boolean) => void;
  };
}

const leftStyle = (percent: number) => htmlSafe(`left: ${percent}%`);

/**
 * Fills the track of the timeline, under the marker thumbs,
 * so a thumb still takes a drag that starts on it.
 *
 * It is for the pointer only: the number keys and R already seek from the keyboard.
 */
export class Scrub extends Component<Signature> {
  /**
   * The time under the pointer.
   */
  @tracked hoverAt: number | undefined;

  #dragging = false;

  get hoverLabel() {
    return this.hoverAt === undefined ? undefined : formatTime(this.hoverAt);
  }

  get hoverPercent() {
    const { duration } = this.args;

    return this.hoverAt === undefined || duration <= 0 ? 0 : (this.hoverAt / duration) * 100;
  }

  timeAt(event: PointerEvent) {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    const fraction = rect.width > 0 ? (event.clientX - rect.left) / rect.width : 0;

    return Math.min(Math.max(fraction, 0), 1) * this.args.duration;
  }

  down = (event: PointerEvent) => {
    if (event.button !== 0) return;

    (event.currentTarget as HTMLElement).setPointerCapture(event.pointerId);
    this.#dragging = true;
    this.hoverAt = this.timeAt(event);
    this.args.onSeek(this.hoverAt, false);
  };

  move = (event: PointerEvent) => {
    this.hoverAt = this.timeAt(event);

    if (this.#dragging) this.args.onSeek(this.hoverAt, false);
  };

  up = (event: PointerEvent) => {
    if (!this.#dragging) return;

    this.#dragging = false;
    this.args.onSeek(this.timeAt(event), true);

    /**
     * The capture kept the preview while the drag went off the track.
     */
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    const inside =
      event.clientX >= rect.left &&
      event.clientX <= rect.right &&
      event.clientY >= rect.top &&
      event.clientY <= rect.bottom;

    if (!inside) this.hoverAt = undefined;
  };

  cancel = () => {
    this.#dragging = false;
    this.hoverAt = undefined;
  };

  leave = () => {
    if (!this.#dragging) this.hoverAt = undefined;
  };

  <template>
    <div
      class="replay__scrub"
      aria-hidden="true"
      data-test-scrub
      {{on "pointerdown" this.down}}
      {{on "pointermove" this.move}}
      {{on "pointerup" this.up}}
      {{on "pointercancel" this.cancel}}
      {{on "pointerleave" this.leave}}
    >
      {{#if this.hoverLabel}}
        <span class="replay__scrub-line" style={{leftStyle this.hoverPercent}}></span>
        <span class="replay__scrub-time" style={{leftStyle this.hoverPercent}} data-test-scrub-time>
          {{this.hoverLabel}}
        </span>
      {{/if}}
    </div>
  </template>
}
