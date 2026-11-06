import {
  click,
  fillIn,
  find,
  findAll,
  triggerEvent,
  triggerKeyEvent,
  visit,
  waitFor,
  waitUntil,
} from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupApplicationTest } from "ember-qunit";

import videoUrl from "../fixtures/ten-seconds.webm?url";

async function clickTab(name: string) {
  const tab = findAll('[role="tab"]').find((element) => element.textContent?.trim() === name);

  if (!tab) throw new Error(`No tab named ${name}`);

  await click(tab);
}

function video() {
  const element = find("video");

  if (!(element instanceof HTMLVideoElement)) throw new Error("No video is rendered");

  return element;
}

/**
 * Seeks like the native video controls do,
 * then waits for the time display to show it.
 */
async function seekTo(seconds: number, shown: string) {
  video().currentTime = seconds;
  await waitUntil(() => find("[data-test-now]")?.textContent === shown);
}

async function loadTheTestVideo() {
  await visit("/");
  await clickTab("File on disk");

  const blob = await (await fetch(videoUrl)).blob();
  const file = new File([blob], "ten-seconds.webm", { type: "video/webm" });

  await triggerEvent(".nvp__file-drop input[type=file]", "change", { files: [file] });
  await waitFor("[data-test-duration]");
}

module("Application | replay", function (hooks) {
  setupApplicationTest(hooks);

  test("a file from disk plays here", async function (assert) {
    await loadTheTestVideo();

    assert.dom("video").hasAria("label", "ten-seconds.webm");
    assert.dom("[data-test-now]").hasText("0:00.0");
    assert.dom("[data-test-duration]").hasText("0:10.0");
    assert.dom('[role="slider"][aria-label="Loop start"]').hasAria("valuenow", "0");
    assert.dom('[role="slider"][aria-label="Loop end"]').hasAria("valuenow", "10");
    assert.dom("[data-test-loop]").hasAria("pressed", "false");
  });

  test("number keys go back that many seconds", async function (assert) {
    await loadTheTestVideo();
    await seekTo(7, "0:07.0");

    await triggerKeyEvent("[data-test-replay]", "keydown", "3");
    assert.dom("[data-test-now]").hasText("0:04.0");
    assert.strictEqual(video().currentTime, 4);

    await triggerKeyEvent("[data-test-replay]", "keydown", "0");
    assert
      .dom("[data-test-now]")
      .hasText("0:00.0", "0 goes back 10 seconds, and stops at the start");
  });

  test("keys in the link field do not seek", async function (assert) {
    await loadTheTestVideo();
    await seekTo(7, "0:07.0");
    await clickTab("YouTube link");

    await triggerKeyEvent('input[name="link"]', "keydown", "3");
    assert.dom("[data-test-now]").hasText("0:07.0");
  });

  test("the loop plays the part between the markers again and again", async function (assert) {
    await loadTheTestVideo();

    await seekTo(3, "0:03.0");
    await triggerKeyEvent("[data-test-replay]", "keydown", "[");
    await seekTo(4, "0:04.0");
    await triggerKeyEvent("[data-test-replay]", "keydown", "]");

    assert.dom('[role="slider"][aria-label="Loop start"]').hasAria("valuenow", "3");
    assert.dom('[role="slider"][aria-label="Loop end"]').hasAria("valuenow", "4");

    await click("[data-test-loop]");
    assert.dom("[data-test-loop]").hasAria("pressed", "true");

    await triggerKeyEvent("[data-test-replay]", "keydown", "9");
    assert.dom("[data-test-now]").hasText("0:03.0", "going back stops at the loop start");

    await click("[data-test-play]");
    await waitUntil(() => video().currentTime > 3.8, { timeout: 3000 });
    await waitUntil(() => video().currentTime < 3.5, { timeout: 3000 });

    assert.true(video().currentTime >= 3, "the video went back to the loop start");
    assert.false(video().paused, "the video still plays");

    await click("[data-test-play]");
    assert.true(video().paused);
  });

  test("a paused video stays paused at the loop end", async function (assert) {
    await loadTheTestVideo();

    await seekTo(4, "0:04.0");
    await triggerKeyEvent("[data-test-replay]", "keydown", "]");
    await triggerKeyEvent("[data-test-replay]", "keydown", "L");
    assert.dom("[data-test-loop]").hasAria("pressed", "true");

    await new Promise((resolve) => setTimeout(resolve, 500));

    assert.true(video().paused);
    assert.strictEqual(video().currentTime, 4);
    assert.dom("[data-test-play]").hasText("Play");

    await click("[data-test-play]");
    await waitUntil(() => video().currentTime < 1, { timeout: 2000 });
    assert.false(video().paused, "Play starts the loop from its start");

    await click("[data-test-play]");
  });

  test("the whole video loops when the markers are at its ends", async function (assert) {
    await loadTheTestVideo();
    await click("[data-test-loop]");
    await seekTo(9.5, "0:09.5");
    await click("[data-test-play]");

    await waitUntil(() => video().currentTime < 1 && !video().paused, { timeout: 3000 });
    assert.false(video().paused, "the video plays again from the start");

    await click("[data-test-play]");
  });

  test("the markers move with the keyboard", async function (assert) {
    await loadTheTestVideo();

    await triggerKeyEvent('[role="slider"][aria-label="Loop end"]', "keydown", "ArrowLeft");
    assert.dom('[role="slider"][aria-label="Loop end"]').hasAria("valuenow", "9.9");
    assert.dom('[role="slider"][aria-label="Loop end"]').hasText("0:09.9");

    await click("[data-test-reset]");
    assert.dom('[role="slider"][aria-label="Loop end"]').hasAria("valuenow", "10", "reset");
  });

  test("a link that is not from YouTube shows an error", async function (assert) {
    await visit("/");
    await fillIn('input[name="link"]', "https://example.com/watch?v=dQw4w9WgXcQ");
    await click('button[type="submit"]');

    assert.dom('[role="alert"]').hasText("That is not a link to a YouTube video.");
    assert.dom('input[name="link"]').hasAria("invalid", "true");
    assert.dom("[data-test-youtube]").doesNotExist();
  });
});
