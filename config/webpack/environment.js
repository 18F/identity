const { environment } = require('@rails/webpacker');

environment.loaders.delete('file');
environment.loaders.delete('nodeModules');
environment.loaders.delete('moduleSass');
environment.loaders.delete('moduleCss');
environment.loaders.delete('css');

// Note: Because chunk splitting is enabled by default as of Webpacker 6+, this line can be removed
// when upgrading.
environment.splitChunks();

// Some files under `node_modules` should be compiled by Babel:
// 1. Yarn workspace package symlinks, by package name starting with `@18f/identity-`.
// 2. Specific dependencies that don't compile their own code to run safely in legacy browsers.
const babelLoader = environment.loaders.get('babel');
babelLoader.include.push(
  /node_modules\/(@18f\/identity-|identity-style-guide|uswds|receptor|elem-dataset)/,
);
babelLoader.exclude = /node_modules\/(?!@18f\/identity-|identity-style-guide|uswds|receptor|elem-dataset)/;

const sassLoader = environment.loaders.get('sass');
// Prepend minimum required design system variables, mixins, and functions to make available to all
// Webpack-imported SCSS files. Notably, this should _not_ include any actual CSS output on its own.
// Note: This option is renamed `additionalData` in newer versions of `sass-loader`.
sassLoader.use.find(({ loader }) => loader === 'sass-loader').options.prependData = `
$font-path: '~identity-style-guide/dist/assets/fonts';
$image-path: '~identity-style-guide/dist/assets/img';
@import '~identity-style-guide/dist/assets/scss/functions/asset-path';
@import '~identity-style-guide/dist/assets/scss/functions/focus';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/custom-styles';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/general';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/typography';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/spacing';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/color';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/utilities';
@import '~identity-style-guide/dist/assets/scss/uswds-theme/components';
@import '~identity-style-guide/dist/assets/scss/uswds/packages/required';
@import '~identity-style-guide/dist/assets/scss/uswds/utilities/palettes/all';
@import '~identity-style-guide/dist/assets/scss/uswds/utilities/rules/all';
@import '~identity-style-guide/dist/assets/scss/uswds/utilities/rules/package';`;

sassLoader.use.map((loader) => {
  if (loader.loader === "css-loader") {
    loader.options.sourceMap = false;
  }
});

const sourceMapLoader = {
  test: /\.js$/,
  include: /node_modules/,
  enforce: 'pre',
  use: ['source-map-loader'],
};
environment.loaders.append('sourceMap', sourceMapLoader);

module.exports = environment;
