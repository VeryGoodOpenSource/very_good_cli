const js = require('@eslint/js');
const globals = require('globals');
const jest = require('eslint-plugin-jest');

module.exports = [
  {
    files: ['*.js'],
    ignores: ['eslint.config.js'],
    rules: {
      ...globals.rules,
      ...js.configs.recommended.rules,
    },
    languageOptions: {
      globals: { ...globals.node, ...jest.environments.globals.globals },
    },
  },
];
