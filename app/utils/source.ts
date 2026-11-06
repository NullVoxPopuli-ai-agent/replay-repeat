export type Source = { kind: "file"; file: File } | { kind: "youtube"; id: string };

/**
 * The files that the browser can play, as an `accept` list.
 */
export const MEDIA_FILES = "video/*,audio/*";

export function fileSource(files: File[]): Source | undefined {
  const file = files[0];

  return file ? { kind: "file", file } : undefined;
}
