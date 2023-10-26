"use strict";(self.webpackChunksite=self.webpackChunksite||[]).push([[372],{3905:(e,t,n)=>{n.d(t,{Zo:()=>d,kt:()=>g});var r=n(7294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},o=Object.keys(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var i=r.createContext({}),c=function(e){var t=r.useContext(i),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},d=function(e){var t=c(e.components);return r.createElement(i.Provider,{value:t},e.children)},p={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},u=r.forwardRef((function(e,t){var n=e.components,a=e.mdxType,o=e.originalType,i=e.parentName,d=l(e,["components","mdxType","originalType","parentName"]),u=c(n),g=a,m=u["".concat(i,".").concat(g)]||u[g]||p[g]||o;return n?r.createElement(m,s(s({ref:t},d),{},{components:n})):r.createElement(m,s({ref:t},d))}));function g(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=n.length,s=new Array(o);s[0]=u;var l={};for(var i in t)hasOwnProperty.call(t,i)&&(l[i]=t[i]);l.originalType=e,l.mdxType="string"==typeof e?e:a,s[1]=l;for(var c=2;c<o;c++)s[c]=n[c];return r.createElement.apply(null,s)}return r.createElement.apply(null,n)}u.displayName="MDXCreateElement"},6777:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>i,contentTitle:()=>s,default:()=>p,frontMatter:()=>o,metadata:()=>l,toc:()=>c});var r=n(7462),a=(n(7294),n(3905));const o={sidebar_position:1},s="Overview",l={unversionedId:"overview",id:"overview",title:"Overview",description:"Very Good CLI is a Command-Line Interface that enables you to generate VGV-opinionated templates and execute helpful commands.",source:"@site/docs/overview.md",sourceDirName:".",slug:"/overview",permalink:"/docs/overview",draft:!1,editUrl:"https://github.com/verygoodopensource/very_good_cli/tree/main/site/docs/overview.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{sidebar_position:1},sidebar:"tutorialSidebar",next:{title:"Templates",permalink:"/docs/category/templates"}},i={},c=[{value:"Quick Start \ud83d\ude80",id:"quick-start-",level:2},{value:"Prerequisites \ud83d\udcdd",id:"prerequisites-",level:3},{value:"Installing",id:"installing",level:2},{value:"Commands",id:"commands",level:2},{value:"<code>very_good create</code>",id:"very_good-create",level:3},{value:"<code>very_good packages get</code>",id:"very_good-packages-get",level:3},{value:"<code>very_good packages check licenses</code>",id:"very_good-packages-check-licenses",level:3},{value:"<code>very_good test</code>",id:"very_good-test",level:3},{value:"<code>very_good --help</code>",id:"very_good---help",level:3}],d={toc:c};function p(e){let{components:t,...n}=e;return(0,a.kt)("wrapper",(0,r.Z)({},d,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h1",{id:"overview"},"Overview"),(0,a.kt)("p",null,"Very Good CLI is a Command-Line Interface that enables you to generate VGV-opinionated templates and execute helpful commands."),(0,a.kt)("p",null,(0,a.kt)("img",{parentName:"p",src:"https://raw.githubusercontent.com/VeryGoodOpenSource/very_good_cli/main/doc/assets/very_good_create.gif",alt:"Very Good CLI"})),(0,a.kt)("h2",{id:"quick-start-"},"Quick Start \ud83d\ude80"),(0,a.kt)("h3",{id:"prerequisites-"},"Prerequisites \ud83d\udcdd"),(0,a.kt)("p",null,"In order to use Very Good CLI you must have ",(0,a.kt)("a",{parentName:"p",href:"https://dart.dev/get-dart"},"Dart")," and ",(0,a.kt)("a",{parentName:"p",href:"https://docs.flutter.dev/get-started/install"},"Flutter")," installed on your machine."),(0,a.kt)("admonition",{type:"info"},(0,a.kt)("p",{parentName:"admonition"},"Very Good CLI requires Dart ",(0,a.kt)("inlineCode",{parentName:"p"},'">=3.1.0 <4.0.0"'))),(0,a.kt)("h2",{id:"installing"},"Installing"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},"dart pub global activate very_good_cli\n")),(0,a.kt)("p",null,"Or install a ",(0,a.kt)("a",{parentName:"p",href:"https://pub.dev/packages/very_good_cli/versions"},"specific version")," using:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},"dart pub global activate very_good_cli <version>\n")),(0,a.kt)("p",null,"If you haven't already, you might need to ","[set up your path][path_setup_link]","."),(0,a.kt)("p",null,"When that is not possible (eg: CI environments), run ",(0,a.kt)("inlineCode",{parentName:"p"},"very_good")," commands via:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},"dart pub global run very_good_cli:very_good <command> <args>\n")),(0,a.kt)("h2",{id:"commands"},"Commands"),(0,a.kt)("h3",{id:"very_good-create"},(0,a.kt)("inlineCode",{parentName:"h3"},"very_good create")),(0,a.kt)("p",null,"Create a very good project in seconds based on the provided template. Each template has a corresponding sub-command. Ex: ",(0,a.kt)("inlineCode",{parentName:"p"},"very_good create flutter_app")," will generate a Flutter starter app."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},'Creates a new very good project in the specified directory.\n\nUsage: very_good create <subcommand> <project-name> [arguments]\n-h, --help    Print this usage information.\n\nAvailable subcommands:\n  dart_cli          Generate a Very Good Dart CLI application.\n  dart_package      Generate a Very Good Dart package.\n  docs_site         Generate a Very Good documentation site.\n  flame_game        Generate a Very Good Flame game.\n  flutter_app       Generate a Very Good Flutter application.\n  flutter_package   Generate a Very Good Flutter package.\n  flutter_plugin    Generate a Very Good Flutter plugin.\n\nRun "very_good help" to see global options.\n')),(0,a.kt)("h3",{id:"very_good-packages-get"},(0,a.kt)("inlineCode",{parentName:"h3"},"very_good packages get")),(0,a.kt)("p",null,"Get packages in a Dart or Flutter project."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},"# Install packages in the current directory\nvery_good packages get\n\n# Install packages in ./some/other/directory\nvery_good packages get ./some/other/directory\n\n# Install packages recursively\nvery_good packages get --recursive\n\n# Install packages recursively (shorthand)\nvery_good packages get -r\n")),(0,a.kt)("h3",{id:"very_good-packages-check-licenses"},(0,a.kt)("inlineCode",{parentName:"h3"},"very_good packages check licenses")),(0,a.kt)("p",null,"Check packages' licenses in a Dart or Flutter project."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},'# Check licenses in the current directory\nvery_good packages check licenses\n\n# Only allow the use of certain licenses\nvery_good packages check licenses --allowed="MIT,BSD-3-Clause,BSD-2-Clause,Apache-2.0"\n\n# Deny the use of certain licenses\nvery_good packages check licenses --forbidden="unknown"\n\n# Check licenses for certain dependencies types\nvery_good packages check licenses --dependency-type="direct-main,transitive"\n')),(0,a.kt)("h3",{id:"very_good-test"},(0,a.kt)("inlineCode",{parentName:"h3"},"very_good test")),(0,a.kt)("p",null,"Run tests in a Dart or Flutter project."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},"# Run all tests\nvery_good test\n\n# Run all tests and collect coverage\nvery_good test --coverage\n\n# Run all tests and enforce 100% coverage\nvery_good test --coverage --min-coverage 100\n\n# Run only tests in ./some/other/directory\nvery_good test ./some/other/directory\n\n# Run tests recursively\nvery_good test --recursive\n\n# Run tests recursively (shorthand)\nvery_good test -r\n")),(0,a.kt)("h3",{id:"very_good---help"},(0,a.kt)("inlineCode",{parentName:"h3"},"very_good --help")),(0,a.kt)("p",null,"See the complete list of commands and usage information."),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-sh"},'\ud83e\udd84 A Very Good Command-Line Interface\n\nUsage: very_good <command> [arguments]\n\nGlobal options:\n-h, --help            Print this usage information.\n    --version         Print the current version.\n    --[no-]verbose    Noisy logging, including all shell commands executed.\n\nAvailable commands:\n  create     very_good create <subcommand> <project-name> [arguments]\n             Creates a new very good project in the specified directory.\n  packages   Command for managing packages.\n  test       Run tests in a Dart or Flutter project.\n  update     Update Very Good CLI.\n\nRun "very_good help <command>" for more information about a command.\n')))}p.isMDXComponent=!0}}]);