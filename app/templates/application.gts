import "#app/styles.css";

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

import { Shell } from "nvp.ui";
import { ThemeToggle } from "nvp.ui/theme-toggle";

import { Replay } from "#components/replay.gts";
import { SourcePicker } from "#components/source-picker.gts";
import { Welcome } from "#components/welcome.gts";

import type { Source } from "#utils/source.ts";

export default class Application extends Component {
  @tracked source: Source | undefined;

  /**
   * A new source starts a new replay, with fresh markers.
   * `#each` with `@identity` makes a new component for each source.
   */
  get sources() {
    return this.source ? [this.source] : [];
  }

  load = (source: Source) => {
    this.source = source;
  };

  <template>
    <Shell>
      <div class="layout">
        <header class="layout__header">
          <h1>Replay, repeat</h1>
          <ThemeToggle />
        </header>

        <main>
          <SourcePicker @onSource={{this.load}} />

          {{#each this.sources key="@identity" as |source|}}
            <Replay @source={{source}} />
          {{else}}
            <Welcome />
          {{/each}}
        </main>
      </div>
    </Shell>
  </template>
}
