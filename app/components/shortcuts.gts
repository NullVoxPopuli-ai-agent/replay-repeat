import type { TOC } from "@ember/component/template-only";

export const Shortcuts: TOC<object> = <template>
  <section class="shortcuts" aria-labelledby="shortcuts-title">
    <h2 id="shortcuts-title">Keys</h2>
    <dl>
      <div>
        <dt><kbd>1</kbd> to <kbd>9</kbd></dt>
        <dd>Go back that many seconds</dd>
      </div>
      <div>
        <dt><kbd>0</kbd></dt>
        <dd>Go back 10 seconds</dd>
      </div>
      <div>
        <dt><kbd>[</kbd> and <kbd>]</kbd></dt>
        <dd>Set the loop start or end to now</dd>
      </div>
      <div>
        <dt><kbd>L</kbd></dt>
        <dd>Loop on or off</dd>
      </div>
      <div>
        <dt><kbd>K</kbd></dt>
        <dd>Play or pause</dd>
      </div>
    </dl>
    <p>When the loop is on, going back stops at the loop start.</p>
  </section>
</template>;
