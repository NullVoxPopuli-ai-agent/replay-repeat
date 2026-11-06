import "#app/styles.css";

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";

import { DocumentFileDrop } from "ember-primitives/components/file-drop";
import { ExternalLink, Shell } from "nvp.ui";
import { ThemeToggle } from "nvp.ui/theme-toggle";

import { Replay } from "#components/replay.gts";
import { SourcePicker } from "#components/source-picker.gts";
import { Welcome } from "#components/welcome.gts";
import { NEW_VIDEO, PARAMS } from "#utils/params.ts";
import { fileSource, MEDIA_FILES } from "#utils/source.ts";
import { youTubeIdOf } from "#utils/youtube.ts";

import type UrlStateService from "#services/url-state.ts";
import type { Source } from "#utils/source.ts";

export default class Application extends Component {
  @service("url-state") declare urlState: UrlStateService;

  /**
   * A file cannot be in the URL, so it stays here.
   * The key makes each loaded file a new replay, also the same file twice.
   */
  @tracked file: { key: string; source: Source } | undefined;

  /**
   * A YouTube video in the URL wins over a file.
   */
  get sources() {
    const param = this.urlState.param(PARAMS.youtube);
    const id = param ? youTubeIdOf(param) : undefined;

    if (id) {
      const source: Source = { kind: "youtube", id };

      return [{ key: `youtube:${id}`, source }];
    }

    if (this.file) return [this.file];

    return [];
  }

  load = (source: Source) => {
    if (source.kind === "youtube") {
      this.file = undefined;
      this.urlState.update({ ...NEW_VIDEO, [PARAMS.youtube]: source.id });

      return;
    }

    this.file = { key: crypto.randomUUID(), source };
    this.urlState.update({ ...NEW_VIDEO, [PARAMS.youtube]: null });
  };

  loadFiles = (files: File[]) => {
    const source = fileSource(files);

    if (source) this.load(source);
  };

  <template>
    <Shell>
      <DocumentFileDrop @accept={{MEDIA_FILES}} @onFiles={{this.loadFiles}} as |page|>
        {{#if page.isDragging}}
          <div class="page-drop" data-test-page-drop>Drop to load the video</div>
        {{/if}}
      </DocumentFileDrop>

      <div class="layout">
        <header class="layout__header">
          <h1>Replay, repeat</h1>
          <div class="layout__header-end">
            <ExternalLink href="https://github.com/NullVoxPopuli/replay-repeat" data-test-github>
              GitHub
            </ExternalLink>
            <ThemeToggle />
          </div>
        </header>

        <main>
          <SourcePicker @onSource={{this.load}} />

          {{! A new key starts a new replay, with a fresh undo history. }}
          {{#each this.sources key="key" as |item|}}
            <Replay @source={{item.source}} />
          {{else}}
            <Welcome />
          {{/each}}
        </main>
      </div>
    </Shell>
  </template>
}
