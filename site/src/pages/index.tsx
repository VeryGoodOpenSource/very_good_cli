import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import { useColorMode } from '@docusaurus/theme-common';

import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <HomepageCTA />
        <HomepageHeroImage />
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
      </main>
    </Layout>
  );
}

function HomepageCTA() {
  return (
    <div className={styles.width}>
      <Link className="button button--primary button--lg" to="/docs/overview">
        Get Started
      </Link>
    </div>
  );
}

function HomepageHeroImage() {
  const { colorMode } = useColorMode();
  return (
    <img
      className={clsx(styles.heroImage)}
      src={colorMode == 'dark' ? 'img/hero_dark.svg' : 'img/hero.svg'}
      alt="Hero"
      width="720"
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
    Svg: require('@site/static/img/pillar1.svg').default,
    description: (
      <>
        Generate a <a href="/docs/templates/core">Flutter app</a>,{' '}
        <a href="/docs/templates/flutter_pkg">Flutter package</a>,{' '}
        <a href="/docs/templates/dart_pkg">Dart package</a>,{' '}
        <a href="/docs/templates/federated_plugin">federated plugin</a>, or{' '}
        <a href="/docs/templates/dart_cli">Dart CLI</a> with one command.
      </>
    ),
  },
  {
    title: 'Built-In Best Practices',
    Svg: require('@site/static/img/pillar2.svg').default,
    description: (
      <>
        All templates come with VGV-opinionated architecture and best practices,
        including 100% test coverage.
      </>
    ),
  },
  {
    title: 'Utility Commands',
    Svg: require('@site/static/img/pillar3.svg').default,
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
