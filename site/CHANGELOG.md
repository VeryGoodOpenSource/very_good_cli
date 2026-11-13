# Changelog

## [1.3.0](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.2.0...site-v1.3.0) (2026-11-13)


### Features

* add structured test results to MCP test failures ([#1799](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1799)) ([84e2fc5](https://github.com/VeryGoodOpenSource/very_good_cli/commit/84e2fc5b1488d0b4062a15dbe18cfa14cf94629d))
* **test:** add --workspace flag to test the packages of a Pub workspace ([#1807](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1807)) ([65250ad](https://github.com/VeryGoodOpenSource/very_good_cli/commit/65250ade1ea509422326a263565f7ec036210e86))


### Miscellaneous Chores

* **deps-dev:** bump eslint from 10.13.0 to 10.14.0 in /site ([#1804](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1804)) ([c9b724c](https://github.com/VeryGoodOpenSource/very_good_cli/commit/c9b724cbae9f6bd9de5580f7500ca1dc5ca00f38))
* **deps-dev:** bump globals from 17.13.0 to 17.14.0 in /site ([#1803](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1803)) ([64463cb](https://github.com/VeryGoodOpenSource/very_good_cli/commit/64463cb5482e33c38421dfd04d0cb6a8fe05602a))
* **site:** regenerate the lockfile to pick up newer transitive dependencies ([#1811](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1811)) ([f5e38dd](https://github.com/VeryGoodOpenSource/very_good_cli/commit/f5e38dd3afbaa1e5da4c646f720192708b70fbec))

## [1.2.0](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.1.1...site-v1.2.0) (2026-11-05)


### Features

* add --file-reporter support to test commands ([#1640](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1640)) ([20a3943](https://github.com/VeryGoodOpenSource/very_good_cli/commit/20a3943f892b8820f235ed6e24e491c41f92b53f))
* **create:** add create config to very_good.yaml ([#1665](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1665)) ([8e78a14](https://github.com/VeryGoodOpenSource/very_good_cli/commit/8e78a14f46b3fbaa6832979017f9be4caebb77ea))
* **dart:** add dart config to very_good.yaml ([#1664](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1664)) ([694478a](https://github.com/VeryGoodOpenSource/very_good_cli/commit/694478a4d68bfdcb65e1a026d6715b6b6541124d))
* **deps:** upgrade to Dart 3.13 ([#1691](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1691)) ([25a225f](https://github.com/VeryGoodOpenSource/very_good_cli/commit/25a225f59cfec3e7eee5bf6c271ae62ead191c79))
* **packages:** add packages config to very_good.yaml ([#1663](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1663)) ([a4505cf](https://github.com/VeryGoodOpenSource/very_good_cli/commit/a4505cfe2c3457e6d049e387aded8126caa29a0b))
* **test:** add timeout ([#1595](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1595)) ([3138466](https://github.com/VeryGoodOpenSource/very_good_cli/commit/31384665fe66b4db8c03ba6ac15940beaecb8ab4))
* **test:** add very_good.yaml for config ([#1636](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1636)) ([fed3074](https://github.com/VeryGoodOpenSource/very_good_cli/commit/fed3074f2ef1b629762b85d3b862bc45bd179ade))
* **test:** support sharding tests across CI runners ([#1707](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1707)) ([1c867db](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1c867dbf24efc21d7d5d8c1386fa0c9791a14113))


### Refactors

* **test:** reduce cognitive complexity of the test runners ([#1756](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1756)) ([f424dd4](https://github.com/VeryGoodOpenSource/very_good_cli/commit/f424dd48dc90fefeb4b4ca731f3d148bd6e19093))


### Miscellaneous Chores

* **deps-dev:** bump @docusaurus/eslint-plugin in /site ([#1574](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1574)) ([3a594a3](https://github.com/VeryGoodOpenSource/very_good_cli/commit/3a594a37e058c33ead1f8aedf5f1314e8f4e38d7))
* **deps-dev:** bump @docusaurus/eslint-plugin in /site ([#1583](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1583)) ([9f7c48e](https://github.com/VeryGoodOpenSource/very_good_cli/commit/9f7c48efaf3bed441a56ca13d01edfd25653af36))
* **deps-dev:** bump @docusaurus/eslint-plugin in /site ([#1644](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1644)) ([328bbd5](https://github.com/VeryGoodOpenSource/very_good_cli/commit/328bbd5a5d3865e7d453e0d6cbe5c1214dd935b1))
* **deps-dev:** bump @docusaurus/module-type-aliases in /site ([#1646](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1646)) ([5f13665](https://github.com/VeryGoodOpenSource/very_good_cli/commit/5f1366576a059c5c430a0adb22fd13727e4c5fad))
* **deps-dev:** bump @docusaurus/tsconfig from 3.9.2 to 3.10.0 in /site ([#1575](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1575)) ([2970fa7](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2970fa7b9ce11870b91e96b5ee4533802f0e48aa))
* **deps-dev:** bump @docusaurus/tsconfig in /site ([#1591](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1591)) ([28ad7c1](https://github.com/VeryGoodOpenSource/very_good_cli/commit/28ad7c158bcefe38006b839966f1aa29701fe2f4))
* **deps-dev:** bump @docusaurus/tsconfig in /site ([#1645](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1645)) ([36af657](https://github.com/VeryGoodOpenSource/very_good_cli/commit/36af657c82277d6b23b14bc587f2299b4baea04f))
* **deps-dev:** bump @types/react from 19.2.14 to 19.2.15 in /site ([#1598](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1598)) ([601ea2c](https://github.com/VeryGoodOpenSource/very_good_cli/commit/601ea2ce55510811a02aacb52798eea6a9310f19))
* **deps-dev:** bump @types/react from 19.2.15 to 19.2.17 in /site ([#1608](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1608)) ([1d297b4](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1d297b475e8e77aff03ff02d8c86bc0dd7d141b9))
* **deps-dev:** bump @types/react from 19.2.17 to 19.2.18 in /site ([#1672](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1672)) ([bb514bb](https://github.com/VeryGoodOpenSource/very_good_cli/commit/bb514bb5cfa9370b21389c6ebed47bbbe8d33803))
* **deps-dev:** bump eslint from 10.1.0 to 10.2.0 in /site ([#1558](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1558)) ([03134c4](https://github.com/VeryGoodOpenSource/very_good_cli/commit/03134c4242a6a1d52889962b72b31d7191b90a1b))
* **deps-dev:** bump eslint from 10.10.0 to 10.11.0 in /site ([#1751](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1751)) ([255af7c](https://github.com/VeryGoodOpenSource/very_good_cli/commit/255af7c3ed0809d323d8d3f6ed9496d0b6857840))
* **deps-dev:** bump eslint from 10.11.0 to 10.12.0 in /site ([#1764](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1764)) ([01d2360](https://github.com/VeryGoodOpenSource/very_good_cli/commit/01d2360f1620f277e30021cbf4cd65bc162c73ec))
* **deps-dev:** bump eslint from 10.12.0 to 10.13.0 in /site ([#1785](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1785)) ([7ef11ef](https://github.com/VeryGoodOpenSource/very_good_cli/commit/7ef11ef11834498ad24e52bbfc0532763ac7b7f9))
* **deps-dev:** bump eslint from 10.2.0 to 10.2.1 in /site ([#1581](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1581)) ([6a2e253](https://github.com/VeryGoodOpenSource/very_good_cli/commit/6a2e253a2fe03129ef4701cc7f5836600fd2b994))
* **deps-dev:** bump eslint from 10.2.1 to 10.3.0 in /site ([#1586](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1586)) ([f5dcf96](https://github.com/VeryGoodOpenSource/very_good_cli/commit/f5dcf96f1e4ecec3da14a25359d2c9599f614b03))
* **deps-dev:** bump eslint from 10.3.0 to 10.4.0 in /site ([#1596](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1596)) ([ed2b63d](https://github.com/VeryGoodOpenSource/very_good_cli/commit/ed2b63df4d35cf492c6eaf404dbe7ba0c83342a8))
* **deps-dev:** bump eslint from 10.4.0 to 10.4.1 in /site ([#1603](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1603)) ([d0ec4cf](https://github.com/VeryGoodOpenSource/very_good_cli/commit/d0ec4cf68fc5adc6b3c40f44694e40e704899977))
* **deps-dev:** bump eslint from 10.4.1 to 10.5.0 in /site ([#1614](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1614)) ([cbc4427](https://github.com/VeryGoodOpenSource/very_good_cli/commit/cbc44273d28ec51cf556a3d32fa29aba1e9b0abd))
* **deps-dev:** bump eslint from 10.5.0 to 10.6.0 in /site ([#1629](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1629)) ([fd83736](https://github.com/VeryGoodOpenSource/very_good_cli/commit/fd83736eee922a842884b03b1084139dadd149d2))
* **deps-dev:** bump eslint from 10.6.0 to 10.7.0 in /site ([#1647](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1647)) ([e30da76](https://github.com/VeryGoodOpenSource/very_good_cli/commit/e30da766b07431a42d4a70c6fdfd59756ecdef7b))
* **deps-dev:** bump eslint from 10.7.0 to 10.8.0 in /site ([#1671](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1671)) ([7157ddf](https://github.com/VeryGoodOpenSource/very_good_cli/commit/7157ddfdad073fb767119943029eec27ef05e892))
* **deps-dev:** bump eslint from 10.8.0 to 10.8.1 in /site ([#1698](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1698)) ([d0121bb](https://github.com/VeryGoodOpenSource/very_good_cli/commit/d0121bbbf9f3ca695b1b78a1843a4adce7f04f4a))
* **deps-dev:** bump eslint from 10.8.1 to 10.9.1 in /site ([#1709](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1709)) ([1e8a216](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1e8a216b2cb8abe951cd69e2c5c23958f2473b8c))
* **deps-dev:** bump eslint from 10.9.1 to 10.10.0 in /site ([#1732](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1732)) ([3159435](https://github.com/VeryGoodOpenSource/very_good_cli/commit/315943531410b19ad8cd6b42e9a337f17cacb4c4))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1553](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1553)) ([93e0e4c](https://github.com/VeryGoodOpenSource/very_good_cli/commit/93e0e4cc727fe076b0bfe6ace38902fcecbd721f))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1578](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1578)) ([a45b2d5](https://github.com/VeryGoodOpenSource/very_good_cli/commit/a45b2d55b635b083149594751e15366697563230))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1630](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1630)) ([5c00cf8](https://github.com/VeryGoodOpenSource/very_good_cli/commit/5c00cf83bd8b6e44b83ee921ea79cc677b6f04b1))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1637](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1637)) ([a27fbfd](https://github.com/VeryGoodOpenSource/very_good_cli/commit/a27fbfdf2e62a85980d949b8f244eee6923a4aa6))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1659](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1659)) ([8d8343a](https://github.com/VeryGoodOpenSource/very_good_cli/commit/8d8343ab8e719d077d1d3601b0c516bb9a4b365d))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1700](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1700)) ([5ec675f](https://github.com/VeryGoodOpenSource/very_good_cli/commit/5ec675f058e7a2aa2054eb18d93a59f606d9e132))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1710](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1710)) ([7a9e847](https://github.com/VeryGoodOpenSource/very_good_cli/commit/7a9e84720b55e5c7071cda5be8294c98171581b3))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1715](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1715)) ([3b6f7cf](https://github.com/VeryGoodOpenSource/very_good_cli/commit/3b6f7cf1555bbaa9b6c33b56e786658db7d94764))
* **deps-dev:** bump eslint-plugin-jest in /site ([#1776](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1776)) ([2b1897d](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2b1897df51cce536c5dc47cbf533d5a99c65f618))
* **deps-dev:** bump flatted from 3.3.3 to 3.4.2 in /site ([#1556](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1556)) ([2ab3c6f](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2ab3c6fd495b0a2645905ff02fb5c6de483d47ff))
* **deps-dev:** bump globals from 17.11.0 to 17.12.0 in /site ([#1714](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1714)) ([234d954](https://github.com/VeryGoodOpenSource/very_good_cli/commit/234d95466643096b5b51e22b6413f8150cf14a89))
* **deps-dev:** bump globals from 17.12.0 to 17.13.0 in /site ([#1761](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1761)) ([d7777d3](https://github.com/VeryGoodOpenSource/very_good_cli/commit/d7777d3d653bbd7926dc0dd871eb8ffdf5822d41))
* **deps-dev:** bump globals from 17.4.0 to 17.5.0 in /site ([#1569](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1569)) ([6125c50](https://github.com/VeryGoodOpenSource/very_good_cli/commit/6125c50c48d6b60922cba110b5193bab99fa6b74))
* **deps-dev:** bump globals from 17.5.0 to 17.6.0 in /site ([#1594](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1594)) ([71f54cf](https://github.com/VeryGoodOpenSource/very_good_cli/commit/71f54cf559c72a1e62aaab0e35a647c4297129e3))
* **deps-dev:** bump globals from 17.6.0 to 17.7.0 in /site ([#1631](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1631)) ([fb93b3b](https://github.com/VeryGoodOpenSource/very_good_cli/commit/fb93b3b6ad6e265904b18e9965444b0b4427d6e3))
* **deps-dev:** bump globals from 17.7.0 to 17.8.0 in /site ([#1660](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1660)) ([2266566](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2266566408f3bac2725725e65f991b2dcf3a2182))
* **deps-dev:** bump globals from 17.8.0 to 17.9.0 in /site ([#1680](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1680)) ([4754b98](https://github.com/VeryGoodOpenSource/very_good_cli/commit/4754b986427699af6fdabc7f9e9305a24f844c99))
* **deps-dev:** bump globals from 17.9.0 to 17.11.0 in /site ([#1699](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1699)) ([4f5b0be](https://github.com/VeryGoodOpenSource/very_good_cli/commit/4f5b0bec10de805ef4d05cdf544f18e778826c44))
* **deps-dev:** bump jest from 30.3.0 to 30.4.2 in /site ([#1592](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1592)) ([a183e7a](https://github.com/VeryGoodOpenSource/very_good_cli/commit/a183e7a210b43b3fc857cedae2037031f4451eae))
* **deps-dev:** bump jest from 30.4.2 to 30.5.0 in /site ([#1711](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1711)) ([ca19d23](https://github.com/VeryGoodOpenSource/very_good_cli/commit/ca19d23c3d8640798e574b00ced6c5a4b26600e7))
* **deps-dev:** bump jest from 30.5.0 to 30.5.1 in /site ([#1716](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1716)) ([26fc769](https://github.com/VeryGoodOpenSource/very_good_cli/commit/26fc769ea38642fef5469f27bea8d9a5ae6a12e3))
* **deps-dev:** bump jest from 30.5.1 to 30.5.2 in /site ([#1753](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1753)) ([1550f16](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1550f16710b5d127eef28a1862ccc716eb428280))
* **deps-dev:** bump picomatch from 2.3.1 to 2.3.2 in /site ([#1562](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1562)) ([880d810](https://github.com/VeryGoodOpenSource/very_good_cli/commit/880d8104f201fb480d528a1e8a86ddd7433a3b62))
* **deps-dev:** bump prettier from 3.8.1 to 3.8.3 in /site ([#1577](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1577)) ([822dedb](https://github.com/VeryGoodOpenSource/very_good_cli/commit/822dedbfef989042a32f727cdef7bb4c6b619e28))
* **deps-dev:** bump prettier from 3.8.3 to 3.8.4 in /site ([#1613](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1613)) ([31f1301](https://github.com/VeryGoodOpenSource/very_good_cli/commit/31f130166c598894c784ef547688e811d03cabdd))
* **deps-dev:** bump prettier from 3.8.4 to 3.9.1 in /site ([#1628](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1628)) ([8d0a280](https://github.com/VeryGoodOpenSource/very_good_cli/commit/8d0a2805700bacc4862bc08332365022078a06e6))
* **deps-dev:** bump prettier from 3.9.1 to 3.9.4 in /site ([#1638](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1638)) ([cd32f63](https://github.com/VeryGoodOpenSource/very_good_cli/commit/cd32f63ab79d0117049bfe76c2db86bfd9226c37))
* **deps-dev:** bump prettier from 3.9.4 to 3.9.5 in /site ([#1651](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1651)) ([78e353a](https://github.com/VeryGoodOpenSource/very_good_cli/commit/78e353aa6f2a0debde95eab3e1a6b858133e56cf))
* **deps-dev:** bump prettier from 3.9.5 to 3.9.6 in /site ([#1662](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1662)) ([f8fcb30](https://github.com/VeryGoodOpenSource/very_good_cli/commit/f8fcb308949c3d520ea3a0b63824c623944cc53a))
* **deps-dev:** bump prettier from 3.9.6 to 3.9.8 in /site ([#1749](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1749)) ([56825ad](https://github.com/VeryGoodOpenSource/very_good_cli/commit/56825adafe75c6bc4d08a3e292996be40d49b3ca))
* **deps-dev:** bump prettier from 3.9.8 to 3.9.9 in /site ([#1752](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1752)) ([9f00bc1](https://github.com/VeryGoodOpenSource/very_good_cli/commit/9f00bc165c351ca96eac6d6466c1678009c915c4))
* **deps-dev:** bump prettier from 3.9.9 to 3.9.10 in /site ([#1775](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1775)) ([2b7e8dc](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2b7e8dc5428cc9d4bb2553db8bffbc5a9bd445ef))
* **deps-dev:** bump typescript from 5.9.3 to 6.0.2 in /site ([#1552](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1552)) ([4a66cba](https://github.com/VeryGoodOpenSource/very_good_cli/commit/4a66cbaddbafba8d5a3981411946132ce87fdd20))
* **deps-dev:** bump typescript from 6.0.2 to 6.0.3 in /site ([#1576](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1576)) ([53669e9](https://github.com/VeryGoodOpenSource/very_good_cli/commit/53669e99fe8b903be581e0af7bf0262fa5f1db58))
* **deps-dev:** bump typescript from 6.0.3 to 7.0.2 in /site ([#1650](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1650)) ([0fc1106](https://github.com/VeryGoodOpenSource/very_good_cli/commit/0fc11060ed2004254307f3a8df66e6dd9d99ca7d))
* **deps:** bump @docusaurus/core from 3.10.1 to 3.10.2 in /site ([#1648](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1648)) ([1c4a302](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1c4a30252fbc8060f336b91a84e7715e3d6c8312))
* **deps:** bump @docusaurus/preset-classic in /site ([#1573](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1573)) ([8fa4868](https://github.com/VeryGoodOpenSource/very_good_cli/commit/8fa48683f60c9bc4983aa2d4eb271c6e06f5ba7b))
* **deps:** bump @docusaurus/preset-classic in /site ([#1585](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1585)) ([8841118](https://github.com/VeryGoodOpenSource/very_good_cli/commit/8841118124f774979b138c0579cfbb7efb58a5f4))
* **deps:** bump brace-expansion from 1.1.12 to 1.1.13 in /site ([#1565](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1565)) ([4bac565](https://github.com/VeryGoodOpenSource/very_good_cli/commit/4bac5654b52055b6c3231834b3c687d828787cf7))
* **deps:** bump minimatch and serve-handler in /site ([#1555](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1555)) ([6c3286d](https://github.com/VeryGoodOpenSource/very_good_cli/commit/6c3286da2bb343fc02109dbfa7ec2733cc28828a))
* **deps:** bump node-forge from 1.3.3 to 1.4.0 in /site ([#1563](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1563)) ([80dce25](https://github.com/VeryGoodOpenSource/very_good_cli/commit/80dce25c1d75e2f4e50c483664d2f5c597fefb6b))
* **deps:** bump path-to-regexp from 0.1.12 to 0.1.13 in /site ([#1564](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1564)) ([36bd899](https://github.com/VeryGoodOpenSource/very_good_cli/commit/36bd89933c5897f7a52e667b4f4d143efdde29be))
* **deps:** bump react and @types/react in /site ([#1731](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1731)) ([c49e792](https://github.com/VeryGoodOpenSource/very_good_cli/commit/c49e792285273bfff746fb995e82646f2f9cdea0))
* **deps:** bump react from 19.2.7 to 19.2.8 in /site ([#1661](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1661)) ([2d292dd](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2d292ddbb06753c4e33ca742a700e9a66a792d00))
* **deps:** bump react from 19.3.0 to 19.3.1 in /site ([#1773](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1773)) ([cf045bd](https://github.com/VeryGoodOpenSource/very_good_cli/commit/cf045bd3a8035155b00b6239498b2a44876c48fa))
* **deps:** bump react-dom from 19.2.4 to 19.2.5 in /site ([#1571](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1571)) ([896cd43](https://github.com/VeryGoodOpenSource/very_good_cli/commit/896cd43cb5bfac5b4eafa45a7149b80d03492942))
* **deps:** bump react-dom from 19.2.5 to 19.2.6 in /site ([#1590](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1590)) ([e0bef38](https://github.com/VeryGoodOpenSource/very_good_cli/commit/e0bef384e5a43de7dbc2e162f75ee6adbf3b2cfb))
* **deps:** bump react-dom from 19.2.6 to 19.2.7 in /site ([#1602](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1602)) ([fb26e0d](https://github.com/VeryGoodOpenSource/very_good_cli/commit/fb26e0d39d9de9532d5a375bfccc06accc272140))
* **deps:** bump svgo from 3.3.2 to 3.3.3 in /site ([#1561](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1561)) ([484dec8](https://github.com/VeryGoodOpenSource/very_good_cli/commit/484dec83df2fd0015b7d97d27979523e0d074969))
* upgrade to Flutter 3.44 and Dart 3.12 ([#1604](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1604)) ([2b33ce6](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2b33ce625a2d3565a2c3fb0e51c94eb30fdecea9))


### Docs

* clarify --min-coverage and configuration ([#1685](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1685)) ([b5c2457](https://github.com/VeryGoodOpenSource/very_good_cli/commit/b5c2457ffeb618a3cefb3880b86d0a48377196e6))
* document exclude-optimization ([#1729](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1729)) ([a203fbe](https://github.com/VeryGoodOpenSource/very_good_cli/commit/a203fbe98d3759a3bdb497af93d0182e5174568d))
* document test optimization annotation ([#1736](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1736)) ([1a08452](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1a08452294da455ea26ea4a5d93e55e6f70a18eb))
* update app icons on core template ([#1633](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1633)) ([77ff62a](https://github.com/VeryGoodOpenSource/very_good_cli/commit/77ff62a724d6ef130027c0467033bc80d342a85a))

## [1.1.1](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.1.0...site-v1.1.1) (2026-03-30)


### Miscellaneous Chores

* **deps-dev:** bump eslint from 10.0.3 to 10.1.0 in /site ([#1542](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1542)) ([12f1386](https://github.com/VeryGoodOpenSource/very_good_cli/commit/12f138690059a204a6fdd0c514d709f556231117))


### Docs

* add create command in current directory ([#1549](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1549)) ([8eefa56](https://github.com/VeryGoodOpenSource/very_good_cli/commit/8eefa56d29c4f1b5d929a0b1252417a7e9395fad))

## [1.1.0](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.0.3...site-v1.1.0) (2026-03-18)


### Features

* enables several globs to exclude from coverage calculations ([#1532](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1532)) ([21abe02](https://github.com/VeryGoodOpenSource/very_good_cli/commit/21abe0273d7668c6082af692f50c2a4ab7fec144))


### Miscellaneous Chores

* **deps-dev:** bump eslint from 10.0.2 to 10.0.3 in /site ([#1522](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1522)) ([90f2ea5](https://github.com/VeryGoodOpenSource/very_good_cli/commit/90f2ea54c57f16da36c5d37e951ff79ff590e08f))
* **deps-dev:** bump jest from 30.2.0 to 30.3.0 in /site ([#1533](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1533)) ([2b5b1ee](https://github.com/VeryGoodOpenSource/very_good_cli/commit/2b5b1ee97e01bc340f0a703afb1726af3c4d13ab))

## [1.0.3](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.0.2...site-v1.0.3) (2026-03-02)

### Miscellaneous Chores

- **deps-dev:** bump eslint from 10.0.1 to 10.0.2 in /site ([#1509](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1509)) ([9da8772](https://github.com/VeryGoodOpenSource/very_good_cli/commit/9da8772856d2ed20d350c58cf7668cf5648c72b3))
- **deps-dev:** bump globals from 17.3.0 to 17.4.0 in /site ([#1510](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1510)) ([b01eb38](https://github.com/VeryGoodOpenSource/very_good_cli/commit/b01eb386f56724c5d5dfe51375fcc369c4e36074))

## [1.0.2](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.0.1...site-v1.0.2) (2026-02-23)

### Miscellaneous Chores

- **deps-dev:** bump eslint from 10.0.0 to 10.0.1 in /site ([#1502](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1502)) ([c3a3c70](https://github.com/VeryGoodOpenSource/very_good_cli/commit/c3a3c7045bdebcaf33e16b3d8e12d1b119eccc3b))

## [1.0.1](https://github.com/VeryGoodOpenSource/very_good_cli/compare/site-v1.0.0...site-v1.0.1) (2026-02-20)

### Miscellaneous Chores

- **deps-dev:** bump eslint from 9.39.2 to 10.0.0 in /site ([#1470](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1470)) ([acc05ee](https://github.com/VeryGoodOpenSource/very_good_cli/commit/acc05ee131a16786767cdf9ff186e840e3b8a14f))

### Docs

- **site:** inconsistency fixes ([#1495](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1495)) ([1d8984e](https://github.com/VeryGoodOpenSource/very_good_cli/commit/1d8984e028c6e06eace187e4074170e26977977f))
- **site:** v1 updates ([#1492](https://github.com/VeryGoodOpenSource/very_good_cli/issues/1492)) ([91de5a7](https://github.com/VeryGoodOpenSource/very_good_cli/commit/91de5a76b655525e9d4d99a040a862d7d62e1bc6))
