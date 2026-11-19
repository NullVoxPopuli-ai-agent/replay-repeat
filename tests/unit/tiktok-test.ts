import { module, test } from "qunit";

import { isTikTokShortLink, tikTokIdOf } from "#utils/tiktok.ts";

module("Unit | tikTokIdOf", function () {
  const valid: [string, string][] = [
    ["7106594312292453675", "a bare id"],
    ["https://www.tiktok.com/@scout2015/video/7106594312292453675", "a video link"],
    [
      "https://www.tiktok.com/@scout2015/video/7106594312292453675?is_from_webapp=1",
      "a link with params",
    ],
    ["tiktok.com/@scout2015/video/7106594312292453675", "a link without the protocol"],
    ["https://m.tiktok.com/@scout2015/video/7106594312292453675", "a mobile link"],
    ["https://www.tiktok.com/player/v1/7106594312292453675", "a player link"],
    ["https://www.tiktok.com/embed/v2/7106594312292453675", "an embed link"],
    ["https://www.tiktok.com/embed/7106594312292453675", "an old embed link"],
    ["  https://www.tiktok.com/@scout2015/video/7106594312292453675  ", "a link with spaces"],
  ];

  for (const [input, name] of valid) {
    test(`finds the id in ${name}`, function (assert) {
      assert.strictEqual(tikTokIdOf(input), "7106594312292453675");
    });
  }

  const invalid: [string, string][] = [
    ["", "an empty string"],
    ["https://example.com/@scout2015/video/7106594312292453675", "another site"],
    ["https://www.tiktok.com/@scout2015", "a profile link"],
    ["https://www.tiktok.com/@scout2015/video/abc", "a link with a wrong id"],
    ["https://vm.tiktok.com/ZMabcdef/", "a short link"],
    ["dQw4w9WgXcQ", "a YouTube id"],
  ];

  for (const [input, name] of invalid) {
    test(`finds no id in ${name}`, function (assert) {
      assert.strictEqual(tikTokIdOf(input), undefined);
    });
  }
});

module("Unit | isTikTokShortLink", function () {
  test("knows the short links of the share button", function (assert) {
    assert.true(isTikTokShortLink("https://vm.tiktok.com/ZMabcdef/"));
    assert.true(isTikTokShortLink("vt.tiktok.com/ZSabcdef"));
    assert.true(isTikTokShortLink("https://www.tiktok.com/t/ZTabcdef/"));
    assert.false(isTikTokShortLink("https://www.tiktok.com/@scout2015/video/7106594312292453675"));
    assert.false(isTikTokShortLink("https://youtu.be/dQw4w9WgXcQ"));
  });
});
