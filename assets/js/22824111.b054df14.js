"use strict";(self.webpackChunksite=self.webpackChunksite||[]).push([[688],{3905:(e,t,r)=>{r.d(t,{Zo:()=>u,kt:()=>g});var a=r(7294);function n(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function o(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,a)}return r}function l(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?o(Object(r),!0).forEach((function(t){n(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):o(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function c(e,t){if(null==e)return{};var r,a,n=function(e,t){if(null==e)return{};var r,a,n={},o=Object.keys(e);for(a=0;a<o.length;a++)r=o[a],t.indexOf(r)>=0||(n[r]=e[r]);return n}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(a=0;a<o.length;a++)r=o[a],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(n[r]=e[r])}return n}var p=a.createContext({}),i=function(e){var t=a.useContext(p),r=t;return e&&(r="function"==typeof e?e(t):l(l({},t),e)),r},u=function(e){var t=i(e.components);return a.createElement(p.Provider,{value:t},e.children)},s={inlineCode:"code",wrapper:function(e){var t=e.children;return a.createElement(a.Fragment,{},t)}},f=a.forwardRef((function(e,t){var r=e.components,n=e.mdxType,o=e.originalType,p=e.parentName,u=c(e,["components","mdxType","originalType","parentName"]),f=i(r),g=n,m=f["".concat(p,".").concat(g)]||f[g]||s[g]||o;return r?a.createElement(m,l(l({ref:t},u),{},{components:r})):a.createElement(m,l({ref:t},u))}));function g(e,t){var r=arguments,n=t&&t.mdxType;if("string"==typeof e||n){var o=r.length,l=new Array(o);l[0]=f;var c={};for(var p in t)hasOwnProperty.call(t,p)&&(c[p]=t[p]);c.originalType=e,c.mdxType="string"==typeof e?e:n,l[1]=c;for(var i=2;i<o;i++)l[i]=r[i];return a.createElement.apply(null,l)}return a.createElement.apply(null,r)}f.displayName="MDXCreateElement"},5867:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>p,contentTitle:()=>l,default:()=>s,frontMatter:()=>o,metadata:()=>c,toc:()=>i});var a=r(7462),n=(r(7294),r(3905));const o={sidebar_position:6},l="Flutter Package \ud83e\udd8b",c={unversionedId:"templates/flutter_pkg",id:"templates/flutter_pkg",title:"Flutter Package \ud83e\udd8b",description:"This template is for a Flutter package.",source:"@site/docs/templates/flutter_pkg.md",sourceDirName:"templates",slug:"/templates/flutter_pkg",permalink:"/docs/templates/flutter_pkg",draft:!1,editUrl:"https://github.com/verygoodopensource/very_good_cli/tree/main/site/docs/templates/flutter_pkg.md",tags:[],version:"current",sidebarPosition:6,frontMatter:{sidebar_position:6},sidebar:"tutorialSidebar",previous:{title:"Dart Package \ud83c\udfaf",permalink:"/docs/templates/dart_pkg"},next:{title:"Flutter Federated Plugin \u2699\ufe0f",permalink:"/docs/templates/federated_plugin"}},p={},i=[{value:"Usage",id:"usage",level:2}],u={toc:i};function s(e){let{components:t,...r}=e;return(0,n.kt)("wrapper",(0,a.Z)({},u,r,{components:t,mdxType:"MDXLayout"}),(0,n.kt)("h1",{id:"flutter-package-"},"Flutter Package \ud83e\udd8b"),(0,n.kt)("p",null,"This template is for a Flutter package."),(0,n.kt)("h2",{id:"usage"},"Usage"),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-sh"},'# Create a new Flutter package named my_flutter_package\nvery_good create flutter_package my_flutter_package --desc "My new Flutter package"\n\n# Create a new Flutter package named my_flutter_package that is publishable\nvery_good create flutter_package my_flutter_package --desc "My new Flutter package" --publishable\n')))}s.isMDXComponent=!0}}]);