const yaDomains = [
  'ya.ru',
  'yandex-team.ru',
  'yandex.ru',
  'yandex.zoom.us',
  'yandex.net',
];

const workBrowser = 'Yandex';

const regexStrFrom = (strings) =>
  strings
    // Escape special characters
    .map(s => s.replace(/[()[\]{}*+?^$|#.,\/\\\s-]/g, "\\$&"))
    // Sort for maximal munch
    .sort((a, b) => b.length - a.length)
    .join("|");

const yaDomainRegexp = new RegExp(
  '^(.*\\.|)(' + regexStrFrom(yaDomains) + ')$'
);

let handlers = [
  // Open Work domains in Yandex
  {
    match: ({ url }) => yaDomainRegexp.test(url.host),
    browser: workBrowser,
  },
  // Open Zoom links in Zoom
  {
    match: [
      finicky.matchDomains(/.*zoom.us/),
    ],
    browser: "us.zoom.xos",
  },
  // Open Spotify links in Spotify
  {
    match: finicky.matchDomains("open.spotify.com"),
    browser: "Spotify",
  },
];

const isWorkOS = finicky.getSystemInfo().name.split('.')[0].endsWith('-osx');
if (isWorkOS) {
  finicky.log('Work OS detected, opening links from TG in Work browser')
  // Finally, open all http/https from Work Telegram in Yandex
  handlers.push({
    match: ({ url, opener }) => (
      url.protocol === 'https' || url.protocol === 'http'
    ) && opener.bundleId === "ru.keepcoder.Telegram",
    browser: workBrowser,
  });
}

module.exports = {
  defaultBrowser: "Safari",
  options: {
    hideIcon: true,
    // logRequests: true,
  },
  rewrite: [
    // Open Zoom links in Zoom App
    {
      match: ({ url }) => url.host.includes("zoom.us") && url.pathname.includes("/j/"),
      url({ url }) {
        try {
          var pass = '&pwd=' + url.search.match(/pwd=(\w*)/)[1];
        } catch {
          var pass = ""
        }
        let conf = 'confno=' + url.pathname.match(/\/j\/(\d+)/)[1];

        return {
          search: conf + pass,
          pathname: '/join',
          protocol: "zoommtg"
        }
      },
    },
  ],
  handlers,
};
