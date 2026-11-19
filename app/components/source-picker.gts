import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";

import { Button, FileDrop } from "nvp.ui";
import { Tabs } from "nvp.ui/tabs";

import { isInstagramLink } from "#utils/instagram.ts";
import { fileSource, MEDIA_FILES } from "#utils/source.ts";
import { isTikTokShortLink, tikTokIdOf } from "#utils/tiktok.ts";
import { youTubeIdOf } from "#utils/youtube.ts";

import type { Source } from "#utils/source.ts";

interface Signature {
  Args: {
    onSource: (source: Source) => void;
  };
}

export class SourcePicker extends Component<Signature> {
  @tracked linkError: string | undefined;
  @tracked tikTokError: string | undefined;

  loadLink = (event: SubmitEvent) => {
    event.preventDefault();

    const form = event.currentTarget as HTMLFormElement;
    const link = new FormData(form).get("link");
    const id = typeof link === "string" ? youTubeIdOf(link) : undefined;

    if (!id) {
      this.linkError =
        typeof link === "string" && isInstagramLink(link)
          ? "Instagram does not let other sites control its videos. In the Instagram app, tap Share, then Download. Then drop the file here."
          : "That is not a link to a YouTube video.";

      return;
    }

    this.linkError = undefined;
    this.args.onSource({ kind: "youtube", id });
  };

  loadTikTok = (event: SubmitEvent) => {
    event.preventDefault();

    const form = event.currentTarget as HTMLFormElement;
    const link = new FormData(form).get("tiktok-link");
    const text = typeof link === "string" ? link : "";
    const id = tikTokIdOf(text);

    if (!id) {
      this.tikTokError = isTikTokShortLink(text)
        ? "A short link has no video id in it. Open the link, then copy the full link from the address bar."
        : "That is not a link to a TikTok video.";

      return;
    }

    this.tikTokError = undefined;
    this.args.onSource({ kind: "tiktok", id });
  };

  loadFiles = (files: File[]) => {
    const source = fileSource(files);

    if (source) this.args.onSource(source);
  };

  <template>
    <Tabs as |Tab|>
      <Tab @label="YouTube link">
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

      <Tab @label="TikTok link">
        <form class="source__form" {{on "submit" this.loadTikTok}}>
          <label class="source__field">
            <span>TikTok link</span>
            <input
              name="tiktok-link"
              type="text"
              inputmode="url"
              autocomplete="off"
              placeholder="https://www.tiktok.com/@…/video/…"
              required
              aria-invalid={{if this.tikTokError "true"}}
              aria-describedby="tiktok-link-error"
            />
          </label>
          <Button @variant="primary" type="submit">Load</Button>
        </form>
        <p id="tiktok-link-error" class="replay__error" role="alert">{{this.tikTokError}}</p>
        <p class="source__note">TikTok videos start muted and play at normal speed only.</p>
      </Tab>

      <Tab @label="File on disk">
        <FileDrop @accept={{MEDIA_FILES}} @onFiles={{this.loadFiles}} as |zone|>
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
