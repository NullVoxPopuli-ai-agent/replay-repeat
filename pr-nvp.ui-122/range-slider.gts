import "nvp.ui/variables.css";
import "nvp.ui/focus.css";
import "./range-slider.css";

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";

import { modifier } from "ember-modifier";

/**
 * Which part of the slider a pointer or key moves.
 *
 * - `start` and `end` are the two thumbs
 * - `range` is the filled part between them, and moves both thumbs
 */
type Part = "start" | "end" | "range";

export interface Signature {
  /**
   * The outer element, with `role="group"`.
   */
  Element: HTMLDivElement;
  Args: {
    /**
     * Accessible name for the group of two thumbs.
     */
    label: string;

    /**
     * The lowest value. Default: `0`.
     */
    min?: number;

    /**
     * The highest value.
     */
    max: number;

    /**
     * The value of the first thumb.
     */
    start: number;

    /**
     * The value of the second thumb.
     */
    end: number;

    /**
     * Values snap to multiples of `@step`, counted from `@min`. Default: `1`.
     *
     * Arrow keys move a thumb by one step, and Page Up / Page Down by ten steps.
     */
    step?: number;

    /**
     * The smallest distance between the two thumbs. Default: `@step`.
     */
    minGap?: number;

    /**
     * Called with the new values when a thumb or the range moves.
     *
     * The slider is controlled: it shows `@start` and `@end`,
     * so pass the new values back in.
     */
    onChange: (start: number, end: number) => void;

    /**
     * Turns a value into text for assistive technology (`aria-valuetext`)
     * and for the visible thumb labels.
     *
     * Default: the number as is.
     */
    formatValue?: (value: number) => string;

    /**
     * Accessible name of the first thumb. Default: `"Start"`.
     */
    startLabel?: string;

    /**
     * Accessible name of the second thumb. Default: `"End"`.
     */
    endLabel?: string;
  };
  Blocks: {
    /**
     * Extra content inside the track, under the thumbs,
     * for example a playhead.
     *
     * `position` turns a value into a percentage of the track width.
     */
    default: [{ position: (value: number) => number }];
  };
}

function clamp(value: number, low: number, high: number) {
  if (value < low) return low;
  if (value > high) return high;

  return value;
}

/**
 * Counts the decimals of the step, so that snapped values
 * do not carry float noise such as 0.30000000000000004.
 */
function decimalsOf(step: number) {
  const text = String(step);
  const dot = text.indexOf(".");

  return dot === -1 ? 0 : text.length - dot - 1;
}

export class RangeSlider extends Component<Signature> {
  /**
   * The part that a pointer drags, for styling with `[data-dragging]`.
   */
  @tracked dragging: Part | undefined;

  get min() {
    return this.args.min ?? 0;
  }

  get step() {
    return this.args.step ?? 1;
  }

  get minGap() {
    return this.args.minGap ?? this.step;
  }

  get span() {
    return Math.max(this.args.max - this.min, 0);
  }

  get startLabel() {
    return this.args.startLabel ?? "Start";
  }

  get endLabel() {
    return this.args.endLabel ?? "End";
  }

  get style() {
    return htmlSafe(
      `--range-slider-start: ${this.position(this.args.start)}%; ` +
        `--range-slider-end: ${this.position(this.args.end)}%;`,
    );
  }

  get blockArgs() {
    return { position: this.position };
  }

  position = (value: number) => {
    if (this.span === 0) return 0;

    return ((clamp(value, this.min, this.args.max) - this.min) / this.span) * 100;
  };

  format = (value: number) => {
    return this.args.formatValue ? this.args.formatValue(value) : String(value);
  };

  snap(value: number) {
    const steps = Math.round((value - this.min) / this.step);

    return Number((this.min + steps * this.step).toFixed(decimalsOf(this.step)));
  }

  /**
   * Moves one part, keeps the thumbs in order and `@minGap` apart,
   * and reports the result.
   */
  move(part: Part, value: number) {
    const { start, end, max } = this.args;
    const gap = Math.min(this.minGap, this.span);

    if (part === "start") {
      this.args.onChange(clamp(this.snap(value), this.min, end - gap), end);

      return;
    }

    if (part === "end") {
      this.args.onChange(start, clamp(this.snap(value), start + gap, max));

      return;
    }

    const width = end - start;
    const nextStart = clamp(this.snap(value), this.min, max - width);

    this.args.onChange(nextStart, nextStart + width);
  }

  handleKey = (part: "start" | "end", event: KeyboardEvent) => {
    const current = part === "start" ? this.args.start : this.args.end;
    const page = this.step * 10;
    let next: number;

    switch (event.key) {
      case "ArrowLeft":
      case "ArrowDown":
        next = current - this.step;

        break;
      case "ArrowRight":
      case "ArrowUp":
        next = current + this.step;

        break;
      case "PageDown":
        next = current - page;

        break;
      case "PageUp":
        next = current + page;

        break;
      case "Home":
        next = this.min;

        break;
      case "End":
        next = this.args.max;

        break;
      default:
        return;
    }

    event.preventDefault();
    this.move(part, next);
  };

  /**
   * One pointer handler on the track covers every part:
   *
   * - a thumb drags that thumb
   * - the filled range drags both thumbs and keeps the distance
   * - anywhere else on the track, the nearest thumb jumps there, then drags
   */
  drag = modifier((track: HTMLElement) => {
    let pointerId: number | undefined;
    let part: Part = "start";
    let offset = 0;

    const valueAt = (clientX: number) => {
      const rect = track.getBoundingClientRect();

      if (rect.width === 0) return this.min;

      return this.min + clamp((clientX - rect.left) / rect.width, 0, 1) * this.span;
    };

    const onPointerDown = (event: PointerEvent) => {
      if (event.button !== 0) return;

      const target = event.target as HTMLElement;
      const hit = target.closest<HTMLElement>("[data-part]");
      const value = valueAt(event.clientX);

      offset = 0;

      if (hit?.dataset["part"] === "range") {
        part = "range";
        offset = value - this.args.start;
      } else if (hit?.dataset["part"] === "start" || hit?.dataset["part"] === "end") {
        part = hit.dataset["part"];
      } else {
        const toStart = Math.abs(value - this.args.start);
        const toEnd = Math.abs(value - this.args.end);

        part = toStart <= toEnd ? "start" : "end";
        this.move(part, value);
      }

      pointerId = event.pointerId;
      this.dragging = part;
      track.setPointerCapture(event.pointerId);
      track
        .querySelector<HTMLElement>(`[data-part="${part === "end" ? "end" : "start"}"]`)
        ?.focus();
      event.preventDefault();
    };

    const onPointerMove = (event: PointerEvent) => {
      if (event.pointerId !== pointerId) return;

      this.move(part, valueAt(event.clientX) - offset);
    };

    const onPointerUp = (event: PointerEvent) => {
      if (event.pointerId !== pointerId) return;

      if (track.hasPointerCapture(event.pointerId)) {
        track.releasePointerCapture(event.pointerId);
      }

      pointerId = undefined;
      this.dragging = undefined;
    };

    track.addEventListener("pointerdown", onPointerDown);
    track.addEventListener("pointermove", onPointerMove);
    track.addEventListener("pointerup", onPointerUp);
    track.addEventListener("pointercancel", onPointerUp);

    return () => {
      track.removeEventListener("pointerdown", onPointerDown);
      track.removeEventListener("pointermove", onPointerMove);
      track.removeEventListener("pointerup", onPointerUp);
      track.removeEventListener("pointercancel", onPointerUp);
    };
  });

  <template>
    <div
      class="nvp__range-slider"
      role="group"
      aria-label={{@label}}
      data-dragging={{this.dragging}}
      style={{this.style}}
      ...attributes
    >
      <div class="nvp__range-slider__track" {{this.drag}}>
        <div class="nvp__range-slider__range" data-part="range"></div>

        {{yield this.blockArgs}}

        <div
          class="nvp__range-slider__thumb"
          role="slider"
          tabindex="0"
          data-part="start"
          aria-label={{this.startLabel}}
          aria-orientation="horizontal"
          aria-valuemin={{this.min}}
          aria-valuemax={{@end}}
          aria-valuenow={{@start}}
          aria-valuetext={{this.format @start}}
          {{on "keydown" (fn this.handleKey "start")}}
        >
          <span class="nvp__range-slider__value">{{this.format @start}}</span>
        </div>

        <div
          class="nvp__range-slider__thumb"
          role="slider"
          tabindex="0"
          data-part="end"
          aria-label={{this.endLabel}}
          aria-orientation="horizontal"
          aria-valuemin={{@start}}
          aria-valuemax={{@max}}
          aria-valuenow={{@end}}
          aria-valuetext={{this.format @end}}
          {{on "keydown" (fn this.handleKey "end")}}
        >
          <span class="nvp__range-slider__value">{{this.format @end}}</span>
        </div>
      </div>
    </div>
  </template>
}
