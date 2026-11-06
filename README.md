# replay-repeat

Replay part of a video until you know it.
Load a YouTube link or a video file from your disk.

| key                | action                           |
| :----------------- | :------------------------------- |
| `1` to `9`         | go back that many seconds        |
| `0`                | go back 10 seconds               |
| `[` and `]`        | set the loop start or end to now |
| `L`                | loop on or off                   |
| `R`                | go to the loop start             |
| `K`                | play or pause                    |
| `<` and `>`        | slower or faster                 |
| `Ctrl`+`Z`         | undo a marker move               |
| `Ctrl`+`Shift`+`Z` | redo a marker move               |

Drag the two loop markers under the video to pick the part that loops.
When the loop is on, going back stops at the loop start.

There is no server:

- A video file stays on your disk, and the browser plays it from there.
- For YouTube links, the app loads the YouTube IFrame Player API.

This is an Ember app, created with [ember.nvp](https://github.com/NullVoxPopuli/ember.nvp), with [nvp.ui](https://github.com/NullVoxPopuli/nvp.ui) for the UI.
Each `pr-nvp.ui-<number>/` folder holds a component from an open nvp.ui pull request.
Its README tells how to remove the folder after a release.

## Getting Started

### Prerequisites

- Node.js >= 24
- pnpm

### Installation

```sh
pnpm install
```

### Development

To start the local development server:

```sh
pnpm dev
```

### Production build

To build the app, then serve the build on `$PORT` (default 4200):

```sh
pnpm build
pnpm preview
```

## Features & Tooling

### GitHub Actions

Continuous Integration (CI) is configured under `.github/workflows/ci.yml` for automated testing and linting.

### Prettier

Code formatting is managed with [Prettier](https://prettier.io/).

- `pnpm format` - Format code
- `pnpm lint:prettier` - Check code formatting

### TypeScript

This project uses TypeScript 7 and [ember-content-mapper](https://github.com/NullVoxPopuli/ember-content-mapper) for static type checking.

- `pnpm lint:types` - Typecheck code with TypeScript
- Imports of `.gts` and `.gjs` modules must include the extension
- Editor setup: see [ember-content-mapper's editors section](https://github.com/NullVoxPopuli/ember-content-mapper#editors)
