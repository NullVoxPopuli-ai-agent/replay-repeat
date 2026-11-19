/**
 * The controls of a video, the same for a file on disk and for YouTube.
 */
export interface Player {
  readonly currentTime: number;
  readonly duration: number;
  readonly paused: boolean;
  readonly ended: boolean;

  /**
   * The playback speed: 1 is normal, 0.5 is half speed.
   */
  readonly rate: number;
  setRate(rate: number): void;

  /**
   * TikTok has no speed setting, so its videos play at normal speed only.
   */
  readonly canSetRate: boolean;

  /**
   * From 0 to 1. Muting keeps the volume for when the sound comes back.
   */
  readonly volume: number;
  readonly muted: boolean;
  setVolume(volume: number): void;
  setMuted(muted: boolean): void;

  /**
   * `final` is false for the steps of a drag on the timeline.
   */
  seek(seconds: number, final?: boolean): void;
  play(): void;
  pause(): void;
}

export class FilePlayer implements Player {
  readonly canSetRate = true;
  #video: HTMLVideoElement;

  constructor(video: HTMLVideoElement) {
    this.#video = video;
  }

  get currentTime() {
    return this.#video.currentTime;
  }

  get duration() {
    const { duration } = this.#video;

    return Number.isFinite(duration) ? duration : 0;
  }

  get paused() {
    return this.#video.paused;
  }

  get ended() {
    return this.#video.ended;
  }

  get rate() {
    return this.#video.playbackRate;
  }

  setRate(rate: number) {
    this.#video.playbackRate = rate;
  }

  get volume() {
    return this.#video.volume;
  }

  get muted() {
    return this.#video.muted;
  }

  setVolume(volume: number) {
    this.#video.volume = volume;
  }

  setMuted(muted: boolean) {
    this.#video.muted = muted;
  }

  seek(seconds: number) {
    this.#video.currentTime = seconds;
  }

  play() {
    /**
     * A browser can refuse to play, for example before any user input.
     * The play button stays available, so there is nothing else to do.
     */
    this.#video.play().catch(() => {});
  }

  pause() {
    this.#video.pause();
  }
}

export class YouTubePlayer implements Player {
  readonly canSetRate = true;
  #player: YT.Player;

  constructor(player: YT.Player) {
    this.#player = player;
  }

  get currentTime() {
    return this.#player.getCurrentTime();
  }

  get duration() {
    return this.#player.getDuration();
  }

  get paused() {
    const state = this.#player.getPlayerState();

    return state !== YT.PlayerState.PLAYING && state !== YT.PlayerState.BUFFERING;
  }

  get ended() {
    return this.#player.getPlayerState() === YT.PlayerState.ENDED;
  }

  get rate() {
    return this.#player.getPlaybackRate();
  }

  setRate(rate: number) {
    this.#player.setPlaybackRate(rate);
  }

  /**
   * YouTube counts the volume from 0 to 100.
   */
  get volume() {
    return this.#player.getVolume() / 100;
  }

  get muted() {
    return this.#player.isMuted();
  }

  setVolume(volume: number) {
    this.#player.setVolume(Math.round(volume * 100));
  }

  setMuted(muted: boolean) {
    if (muted) {
      this.#player.mute();
    } else {
      this.#player.unMute();
    }
  }

  /**
   * YouTube asks for no requests to its server during a drag, only on the last step.
   */
  seek(seconds: number, final = true) {
    this.#player.seekTo(seconds, final);
  }

  play() {
    this.#player.playVideo();
  }

  pause() {
    this.#player.pauseVideo();
  }
}

/**
 * The page that the TikTok player iframe loads.
 * Messages go only to it, and only messages from it count.
 */
export const TIKTOK_ORIGIN = "https://www.tiktok.com";

/**
 * The states of `onStateChange`:
 * https://developers.tiktok.com/doc/embed-player
 */
const TIKTOK_ENDED = 0;
const TIKTOK_PLAYING = 1;
const TIKTOK_PAUSED = 2;
const TIKTOK_BUFFERING = 3;

/**
 * TikTok sends the time twice a second, a little late.
 * A time from before a seek can come after the seek, so these are not used.
 */
const TIKTOK_SEEK_IGNORE_MS = 1000;

export interface TikTokMessage {
  "x-tiktok-player": true;
  type: string;
  value?: unknown;
}

export function isTikTokMessage(data: unknown): data is TikTokMessage {
  return typeof data === "object" && data !== null && "x-tiktok-player" in data;
}

interface TikTokTime {
  currentTime: number;
  duration: number;
}

function isTikTokTime(value: unknown): value is TikTokTime {
  return (
    typeof value === "object" &&
    value !== null &&
    typeof (value as TikTokTime).currentTime === "number" &&
    typeof (value as TikTokTime).duration === "number"
  );
}

/**
 * The TikTok player has no functions to call. It takes and sends messages,
 * so this class keeps the last state that the player sent.
 */
export class TikTokPlayer implements Player {
  readonly canSetRate = false;
  readonly rate = 1;

  #frame: Window;
  #state = -1;
  #duration = 0;
  #volume = 1;

  /**
   * The player URL asks for the sound off, so that autoplay works.
   */
  #muted = true;

  /**
   * Between two time messages, the time goes on with the clock,
   * so the playhead moves smoothly and the loop ends on time.
   */
  #time = 0;
  #timeAt = 0;
  #seekedAt = -Infinity;

  /**
   * Autoplay makes the player ready without a click in it.
   * The app starts paused at the start, so the first playback stops,
   * unless the app asked to play first.
   */
  #autoplaying = true;

  constructor(frame: Window) {
    this.#frame = frame;
  }

  /**
   * Keeps the state from a message of the player.
   */
  receive(message: TikTokMessage) {
    const { value } = message;

    switch (message.type) {
      case "onCurrentTime":
        if (!isTikTokTime(value)) return;

        this.#duration = value.duration;

        if (performance.now() - this.#seekedAt < TIKTOK_SEEK_IGNORE_MS) return;

        this.#setTime(value.currentTime);

        return;
      case "onStateChange":
        if (typeof value === "number") this.#setState(value);

        return;
      case "onMute":
        if (typeof value === "boolean") this.#muted = value;

        return;
      case "onVolumeChange":
        if (typeof value === "number") this.#volume = value / 100;

        return;
    }
  }

  #setTime(seconds: number) {
    this.#time = seconds;
    this.#timeAt = performance.now();
  }

  /**
   * The time stops where it is when the player stops playing.
   */
  #setState(state: number) {
    this.#setTime(this.currentTime);
    this.#state = state;

    if (state === TIKTOK_PLAYING && this.#autoplaying) {
      this.pause();
      this.seek(0);
    }
  }

  #send(type: string, value?: unknown) {
    this.#frame.postMessage({ type, value, "x-tiktok-player": true }, TIKTOK_ORIGIN);
  }

  get currentTime() {
    if (this.#state !== TIKTOK_PLAYING) return this.#time;

    const time = this.#time + (performance.now() - this.#timeAt) / 1000;

    return this.#duration > 0 ? Math.min(time, this.#duration) : time;
  }

  get duration() {
    return this.#duration;
  }

  get paused() {
    return this.#state !== TIKTOK_PLAYING && this.#state !== TIKTOK_BUFFERING;
  }

  get ended() {
    return this.#state === TIKTOK_ENDED;
  }

  setRate() {}

  get volume() {
    return this.#volume;
  }

  get muted() {
    return this.#muted;
  }

  /**
   * `setVolume` is not in TikTok's docs, but its player handles it, from 0 to 100.
   */
  setVolume(volume: number) {
    this.#volume = volume;
    this.#send("setVolume", Math.round(volume * 100));
  }

  setMuted(muted: boolean) {
    this.#muted = muted;
    this.#send(muted ? "mute" : "unMute");
  }

  seek(seconds: number) {
    this.#seekedAt = performance.now();
    this.#setTime(seconds);
    this.#send("seekTo", seconds);
  }

  /**
   * The state changes now, not when the player answers,
   * so the loop does not play an ended video twice.
   */
  play() {
    this.#autoplaying = false;
    this.#setState(TIKTOK_BUFFERING);
    this.#send("play");
  }

  pause() {
    this.#autoplaying = false;
    this.#setState(TIKTOK_PAUSED);
    this.#send("pause");
  }
}
