# nvp.ui PR 122

A copy of `RangeSlider` from [NullVoxPopuli/nvp.ui#122](https://github.com/NullVoxPopuli/nvp.ui/pull/122).

When a nvp.ui release has it:

1. Change imports of `#pr-nvp.ui-122/range-slider.gts` to `nvp.ui`.
2. Delete this folder and its `#pr-nvp.ui-122/*` entry in `package.json`.
3. Remove `ember-primitives` from `package.json`, if nothing else imports it.

The copy imports `Slider` from `ember-primitives` 0.63, which nvp.ui 0.11 does not have.
