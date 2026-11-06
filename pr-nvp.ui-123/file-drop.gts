import "nvp.ui/variables.css";
import "nvp.ui/focus.css";
import "./file-drop.css";

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { guidFor } from "@ember/object/internals";

export interface Signature {
  /**
   * The drop zone, a `<label>` around a file `<input>`,
   * so a click anywhere in it opens the file picker.
   */
  Element: HTMLLabelElement;
  Args: {
    /**
     * Called with the files that the user dropped or picked.
     *
     * Only files that match `@accept` are passed.
     * If no file matches, `@onFiles` is not called.
     */
    onFiles: (files: File[]) => void;

    /**
     * Which files to take, with the syntax of the `accept` attribute
     * of a file input, for example `"video/*"` or `".json,application/json"`.
     *
     * The file picker shows only these files.
     * A drop with other files is ignored.
     */
    accept?: string;

    /**
     * Take more than one file. Default: `false`.
     */
    multiple?: boolean;
  };
  Blocks: {
    /**
     * The content of the drop zone.
     * Default: "Drop a file here, or click to choose one".
     *
     * `isDragging` is `true` while files are over the drop zone.
     */
    default: [{ isDragging: boolean }];
  };
}

/**
 * Matches a file against one `accept` entry:
 *
 * - `.ext`, the end of the file name
 * - `type/*`, any subtype
 * - `type/subtype`, exactly
 */
function matchesOne(file: File, entry: string) {
  if (entry.startsWith(".")) {
    return file.name.toLowerCase().endsWith(entry.toLowerCase());
  }

  if (entry.endsWith("/*")) {
    return file.type.startsWith(entry.slice(0, -1));
  }

  return file.type === entry;
}

function matches(file: File, accept: string | undefined) {
  if (!accept) return true;

  const entries = accept.split(",");

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i]?.trim();

    if (entry && matchesOne(file, entry)) return true;
  }

  return false;
}

function hasFiles(event: DragEvent) {
  const types = event.dataTransfer?.types;

  if (!types) return false;

  for (let i = 0; i < types.length; i++) {
    if (types[i] === "Files") return true;
  }

  return false;
}

export class FileDrop extends Component<Signature> {
  @tracked isDragging = false;

  inputId = `${guidFor(this)}-input`;

  /**
   * `dragenter` and `dragleave` fire for each child element on the way.
   *
   * The count tells when the drag leaves the zone.
   */
  #depth = 0;

  get blockArgs() {
    return { isDragging: this.isDragging };
  }

  take(list: FileList | null | undefined) {
    if (!list) return;

    const files: File[] = [];

    for (let i = 0; i < list.length; i++) {
      const file = list[i];

      if (file && matches(file, this.args.accept)) files.push(file);
      if (!this.args.multiple && files.length === 1) break;
    }

    if (files.length > 0) this.args.onFiles(files);
  }

  onDragEnter = (event: DragEvent) => {
    if (!hasFiles(event)) return;

    this.#depth++;
    this.isDragging = true;
  };

  onDragOver = (event: DragEvent) => {
    if (!hasFiles(event)) return;

    /**
     * Without this, the browser does not allow the drop,
     * and opens the file in the tab.
     */
    event.preventDefault();
  };

  onDragLeave = (event: DragEvent) => {
    if (!hasFiles(event)) return;

    this.#depth = Math.max(0, this.#depth - 1);

    if (this.#depth === 0) this.isDragging = false;
  };

  onDrop = (event: DragEvent) => {
    this.#depth = 0;
    this.isDragging = false;

    if (!hasFiles(event)) return;

    event.preventDefault();
    this.take(event.dataTransfer?.files);
  };

  onPick = (event: Event) => {
    const input = event.target as HTMLInputElement;

    this.take(input.files);

    /**
     * Picking the same file again must fire `change` again.
     */
    input.value = "";
  };

  <template>
    <label
      class="nvp__file-drop"
      for={{this.inputId}}
      data-dragging={{this.isDragging}}
      {{on "dragenter" this.onDragEnter}}
      {{on "dragover" this.onDragOver}}
      {{on "dragleave" this.onDragLeave}}
      {{on "drop" this.onDrop}}
      ...attributes
    >
      {{#if (has-block)}}
        {{yield this.blockArgs}}
      {{else}}
        <span class="nvp__file-drop__text">Drop a file here, or click to choose one</span>
      {{/if}}

      <input
        id={{this.inputId}}
        class="nvp__file-drop__input"
        type="file"
        accept={{@accept}}
        multiple={{@multiple}}
        {{on "change" this.onPick}}
      />
    </label>
  </template>
}
