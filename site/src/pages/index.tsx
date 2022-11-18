import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import { useColorMode } from '@docusaurus/theme-common';

import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  const { colorMode } = useColorMode();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <img
          className={clsx(styles.heroLogo)}
          src={colorMode == 'dark' ? 'img/logo_dark.svg' : 'img/logo.svg'}
          alt="CLI Logo"
        />
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <HomepageHeroImage />
        <HomepageCTA />
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      description={`The official documentation site for Very Good CLI Docs. ${siteConfig.tagline}.`}
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <HomepageBlogs />
      </main>
    </Layout>
  );
}

function HomepageCTA() {
  return (
    <div className={styles.width}>
      <Link className="button button--primary button--lg" to="/docs/overview">
        Get Started &gt;
      </Link>
    </div>
  );
}

function HomepageHeroImage() {
  return (
    <img
      className={clsx(styles.heroImage)}
      src="img/home_hero.svg"
      alt="CLI Hero"
    />
  );
}

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Scalable Starter Templates',
    Svg: require('@site/static/img/icon_templates.svg').default,
    description: (
      <>
        Generate a <a href="/docs/templates/core">Flutter app</a>,{' '}
        <a href="/docs/templates/flame_game">Flame game</a>,{' '}
        <a href="/docs/templates/flutter_pkg">Flutter package</a>,{' '}
        <a href="/docs/templates/dart_pkg">Dart package</a>,{' '}
        <a href="/docs/templates/federated_plugin">federated plugin</a>, or{' '}
        <a href="/docs/templates/dart_cli">Dart CLI</a> with one command.
      </>
    ),
  },
  {
    title: 'Built-In Best Practices',
    Svg: require('@site/static/img/icon_best.svg').default,
    description: (
      <>
        All templates come with VGV-opinionated architecture and best practices,
        including 100% test coverage.
      </>
    ),
  },
  {
    title: 'Utility Commands',
    Svg: require('@site/static/img/icon_commands.svg').default,
    description: (
      <>
        Optimize your tests and recursively fetch packages with additional CLI{' '}
        <a href="/docs/category/commands"> commands</a>.
      </>
    ),
  },
];

function Feature({ title, Svg, description }: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function HomepageBlogs() {
  return (
    <div className={`${styles.section}`}>
      <div className={styles.width}>
        <div className={styles.column}>
          <img
            style={{ height: 'auto' }}
            src="https://uploads-ssl.webflow.com/5ee12d8e99cde2e20255c16c/6362d66f871bd8faaedd560a_Very%20Good%20Game%20templatesmall.png"
            alt="Generate a game foundation with our new template"
            width="452"
            height="254"
          />
        </div>
        <div className={styles.column}>
          <div className={styles.content}>
            <h2>Generate a game foundation with our new template</h2>
            <p>
              Learn more about the Flame game template, which comes with all the
              basics you'll need for game development.
            </p>
            <Link
              style={{ fontWeight: 'bold' }}
              to="https://verygood.ventures/blog/generate-a-game-with-our-new-template"
            >
              Read the Blog &gt;
            </Link>
          </div>
        </div>
      </div>
      <div style={{ padding: '1rem' }}></div>
      <div className={styles.width}>
        <div className={styles.column}>
          <img
            style={{ height: 'auto' }}
            src="https://uploads-ssl.webflow.com/5ee12d8e99cde2e20255c16c/630640412306dabe23c2db4f_CLI%20generates%20CLI.png"
            alt="Generate a Dart CLI with Very Good CLI"
            width="452"
            height="254"
          />
        </div>
        <div className={styles.column}>
          <div className={styles.content}>
            <h2>Generate a Dart CLI with Very Good CLI</h2>
            <p>
              Generate a Dart Command-Line Interface with Very Good CLI. Then,
              take your CLI to the next level with thoughtful command syntax and
              design elements.
            </p>
            <Link
              style={{ fontWeight: 'bold' }}
              to="https://verygood.ventures/blog/generate-command-line-application-cli"
            >
              Read the Blog &gt;
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

function ExternalLinkIcon() {
  return (
    <svg
      width="13.5"
      height="13.5"
      aria-hidden="true"
      viewBox="0 0 24 24"
      className="iconExternalLink_node_modules-@docusaurus-theme-classic-lib-theme-IconExternalLink-styles-module"
    >
      <path
        fill="currentColor"
        d="M21 13v10h-21v-19h12v2h-10v15h17v-8h2zm3-12h-10.988l4.035 4-6.977 7.07 2.828 2.828 6.977-7.07 4.125 4.172v-11z"
      ></path>
    </svg>
  );
}
