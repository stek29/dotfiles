import type { FinickyConfig, BrowserResolver, BrowserHandler } from '/Applications/Finicky.app/Contents/Resources/finicky.d.ts';

const yaDomains = [
  'ya.ru',
  'yandex-team.ru',
  'yandex.ru',
  'yandex.zoom.us',
  'yandex.net',
  'yandex.cloud',
  'yandexcloud.net',
];

const workBrowser: BrowserResolver = (url: URL) => ({
  // TODO: replace with profile instead of args once https://github.com/johnste/finicky/pull/493 gets into release
  name: 'Yandex',
  args: [
    // add -n flag for the open command, and others for the browser itself
    // see https://github.com/johnste/finicky/blob/53414af0c1caba2a606e512848486366baa9c366/apps/finicky/src/browser/launcher.go#L73-L97
    '-n',
    '--args',
    '--profile-directory=Default',
    url.href,
  ],
});

const regexStrFrom = (strings: string[]) =>
  strings
    // Escape special characters
    .map(s => s.replace(/[()[\]{}*+?^$|#.,\/\\\s-]/g, '\\$&'))
    // Sort for maximal munch
    .sort((a, b) => b.length - a.length)
    .join('|');

const yaDomainRegexp = new RegExp(
  '^(.*\\.|)(' + regexStrFrom(yaDomains) + ')$'
);

let handlers: BrowserHandler[] = [
  // Open Zoom links in Zoom
  {
    match: (url: URL) => url.protocol === 'zoomus',
    browser: 'us.zoom.xos',
  },
  // Open Spotify links in Spotify
  {
    match: finicky.matchHostnames('open.spotify.com'),
    browser: 'Spotify',
  },
];

const isWorkOS = finicky.getSystemInfo().name.split('.')[0].endsWith('-osx');

if (isWorkOS) {
  console.log('Work OS detected');

  // Open Work domains in Yandex
  handlers.push({
    match: (url: URL) => yaDomainRegexp.test(url.host),
    browser: workBrowser,
  });

  // Finally, open all http/https from Work Telegram in Yandex
  handlers.push({
    match: (url: URL, { opener }) => (
      url.protocol === 'https' || url.protocol === 'http'
    ) && !!opener && opener.bundleId === 'ru.keepcoder.Telegram',
    browser: workBrowser,
  });
}

export default {
  defaultBrowser: 'Safari',
  options: {
    keepRunning: true,
    hideIcon: false,
  },
  rewrite: [
    // Open Zoom links in Zoom App
    {
      match: (url) => url.host.includes('zoom.us') && /\/j\/\d+/.test(url.pathname),
      url(url: URL) {
        const pwd = url.search.match(/pwd=(\w*)/)?.[1] || '';
        const pwdPart = pwd ? `&pwd=${pwd}` : '';
        const conf = url.pathname.match(/\/j\/(\d+)/)![1];

        return {
          search: `action=join&confno=${conf}${pwdPart}`,
          pathname: '/join',
          protocol: 'zoomus',
        } as URL;
      },
    },
    // Open Spotify links in Spotify -- need to remove search from them
    {
      match: finicky.matchHostnames('open.spotify.com'),
      url(_url: URL) {
        let url = new URL(_url);
        url.search = '';
        return url;
      },
    },
  ],
  handlers,
} satisfies FinickyConfig;
