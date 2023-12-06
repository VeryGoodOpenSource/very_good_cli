// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer').themes.vsLight;
const darkCodeTheme = require('prism-react-renderer').themes.vsDark;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Very Good CLI',
  tagline:
    'A Command-Line Interface to generate scalable templates and use helpful commands.',
  url: 'https://cli.vgv.dev',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'verygoodopensource',
  projectName: 'very_good_cli',
  trailingSlash: false,

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl:
            'https://github.com/verygoodopensource/very_good_cli/tree/main/site/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: '/img/meta/open-graph.png',
      navbar: {
        title: 'Very Good CLI',
        logo: {
          alt: 'Very Good CLI Logo',
          src: 'img/cli_icon.svg',
        },
        items: [
          {
            to: '/docs/overview',
            label: 'Get Started',
            position: 'right',
            className: 'button nav-button',
          },
          {
            label: 'VGV.DEV',
            to: 'https://vgv.dev',
            position: 'right',
          },
          {
            href: 'https://verygood.ventures',
            position: 'right',
            className: 'navbar-vgv-icon',
            'aria-label': 'VGV website',
          },
          {
            href: 'https://github.com/verygoodopensource/very_good_cli',
            position: 'right',
            className: 'navbar-github-icon',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      footer: {
        copyright: `Built with 💙 by <a target="_blank" rel="noopener" aria-label="Very Good Ventures" href="https://verygood.ventures"><b>Very Good Ventures</b></a>.<br/>Copyright © ${new Date().getFullYear()} Very Good Ventures.`,
      },
      prism: {
        additionalLanguages: ['bash', 'dart', 'yaml'],
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
      },
    }),
};

module.exports = config;
