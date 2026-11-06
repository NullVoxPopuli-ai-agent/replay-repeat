import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";

import { Button } from "nvp.ui";
import { Tabs } from "nvp.ui/tabs";

import { FileDrop } from "#pr-nvp.ui-123/file-drop.gts";
import { youTubeIdOf } from "#utils/youtube.ts";

import type { Source } from "#utils/source.ts";

interface Signature {
  Args: {
    onSource: (source: Source) => void;
  };
}

export class SourcePicker extends Component<Signature> {
  @tracked linkError: string | undefined;

  loadLink = (event: SubmitEvent) => {
    event.preventDefault();

    const form = event.currentTarget as HTMLFormElement;
    const link = new FormData(form).get("link");
    const id = typeof link === "string" ? youTubeIdOf(link) : undefined;

    if (!id) {
      this.linkError = "That is not a link to a YouTube video.";

      return;
    }

    this.linkError = undefined;
    this.args.onSource({ kind: "youtube", id });
  };

  loadFiles = (files: File[]) => {
    const file = files[0];

    if (file) this.args.onSource({ kind: "file", file });
  };

  <template>
    {{! `@content` is required by the Tabs types of nvp.ui 0.11.
          https://github.com/NullVoxPopuli/nvp.ui/pull/124 makes it optional. }}
    <Tabs as |Tab|>
      <Tab @label="YouTube link" @content={{undefined}}>
        <form class="source__form" {{on "submit" this.loadLink}}>
          <label class="source__field">
            <span>YouTube link</span>
            <input
              name="link"
              type="text"
              inputmode="url"
              autocomplete="off"
              placeholder="https://www.youtube.com/watch?v=…"
              required
              aria-invalid={{if this.linkError "true"}}
              aria-describedby="link-error"
            />
          </label>
          <Button @variant="primary" type="submit">Load</Button>
        </form>
        <p id="link-error" class="replay__error" role="alert">{{this.linkError}}</p>
      </Tab>

      <Tab @label="File on disk" @content={{undefined}}>
        <FileDrop @accept="video/*,audio/*" @onFiles={{this.loadFiles}} as |zone|>
          {{#if zone.isDragging}}
            Let go to load the video
          {{else}}
            Drop a video here, or click to choose one
          {{/if}}
        </FileDrop>
      </Tab>
    </Tabs>
  </template>
}
