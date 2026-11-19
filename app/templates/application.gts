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
import { fileSource, isMedia } from "#utils/source.ts";
import { tikTokIdOf } from "#utils/tiktok.ts";
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
   * Why the last drop did not load, so that a drop never fails without a word.
   */
  @tracked dropError: string | undefined;

  /**
   * A video in the URL wins over a file.
   */
  get sources() {
    const youTube = this.urlState.param(PARAMS.youtube);
    const youTubeId = youTube ? youTubeIdOf(youTube) : undefined;

    if (youTubeId) {
      const source: Source = { kind: "youtube", id: youTubeId };

      return [{ key: `youtube:${youTubeId}`, source }];
    }

    const tikTok = this.urlState.param(PARAMS.tiktok);
    const tikTokId = tikTok ? tikTokIdOf(tikTok) : undefined;

    if (tikTokId) {
      const source: Source = { kind: "tiktok", id: tikTokId };

      return [{ key: `tiktok:${tikTokId}`, source }];
    }

    if (this.file) return [this.file];

    return [];
  }

  /**
   * One video at a time: a new source clears the params of the others.
   */
  load = (source: Source) => {
    this.dropError = undefined;

    const videos = { [PARAMS.youtube]: null, [PARAMS.tiktok]: null };

    if (source.kind === "file") {
      this.file = { key: crypto.randomUUID(), source };
      this.urlState.update({ ...NEW_VIDEO, ...videos });

      return;
    }

    this.file = undefined;
    this.urlState.update({ ...NEW_VIDEO, ...videos, [PARAMS[source.kind]]: source.id });
  };

  /**
   * The page takes any file, so a file that is not media gets a message.
   */
  loadFiles = (files: File[]) => {
    const file = files[0];

    if (file && !isMedia(file)) {
      this.dropError = `${file.name} is not a video or audio file.`;

      return;
    }

    const source = fileSource(files);

    if (source) this.load(source);
  };

  <template>
    <Shell>
      <DocumentFileDrop @onFiles={{this.loadFiles}} as |page|>
        {{#if page.isDragging}}
          <div class="page-drop" data-test-page-drop>Drop to load the video</div>
        {{/if}}
      </DocumentFileDrop>

      <div class="layout">
        <header class="layout__header">
          <h1>replay, repeat</h1>
          <div class="layout__header-end">
            <ExternalLink href="https://github.com/NullVoxPopuli/replay-repeat" data-test-github>
              GitHub
            </ExternalLink>
            <ThemeToggle />
          </div>
        </header>

        <main>
          <SourcePicker @onSource={{this.load}} />

          {{#if this.dropError}}
            <p class="replay__error" role="alert" data-test-drop-error>{{this.dropError}}</p>
          {{/if}}

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
