import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { waitForPromise } from "@ember/test-waiters";

import type RouterService from "@ember/routing/router-service";

/**
 * `null` removes a param from the URL.
 */
export type QueryParams = Record<string, string | null>;

/**
 * Query params as app state, with no controllers.
 *
 * - Reads come from `router.currentRoute.queryParams`.
 * - Writes in the same frame go out as one `transitionTo`.
 *   Transitions in flight cancel each other, so one at a time keeps the URL right.
 * - The application route declares the params, so the URL gets them,
 *   and a transition keeps the params that it does not name.
 * - Until a write is in the URL, reads return the written value.
 */
export default class UrlStateService extends Service {
  @service declare router: RouterService;

  @tracked pending: QueryParams = {};

  #frame: number | undefined;
  #resolveFrame: (() => void) | undefined;

  param(name: string): string | undefined {
    if (name in this.pending) return this.pending[name] ?? undefined;

    const value: unknown = this.router.currentRoute?.queryParams[name];

    return typeof value === "string" ? value : undefined;
  }

  update(changes: QueryParams) {
    this.pending = { ...this.pending, ...changes };

    if (this.#frame !== undefined) return;

    void waitForPromise(
      new Promise<void>((resolve) => {
        this.#resolveFrame = resolve;
        this.#frame = requestAnimationFrame(() => {
          this.#frame = undefined;
          this.#resolveFrame = undefined;
          this.#flush(resolve);
        });
      }),
    );
  }

  #flush(resolve: () => void) {
    const sent = this.pending;

    /**
     * Writes after this one stay pending for the next transition.
     */
    const done = () => {
      const rest: QueryParams = {};

      for (const [name, value] of Object.entries(this.pending)) {
        if (sent[name] !== value) rest[name] = value;
      }

      this.pending = rest;
      resolve();
    };

    this.router.transitionTo({ queryParams: sent }).then(done, done);
  }

  willDestroy() {
    super.willDestroy();

    if (this.#frame !== undefined) cancelAnimationFrame(this.#frame);

    this.#resolveFrame?.();
  }
}
