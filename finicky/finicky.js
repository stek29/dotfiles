const vkDomains = [
  'devmail.ru',
  'ipmi',
  'mail.ru',
  'mvk.com',
  'odkl.ru',
  'smailru.net',
  'vk.team',
];

const regexStrFrom = (strings) =>
  strings
    // Escape special characters
    .map(s => s.replace(/[()[\]{}*+?^$|#.,\/\\\s-]/g, "\\$&"))
    // Sort for maximal munch
    .sort((a, b) => b.length - a.length)
    .join("|");

const vkDomainRegexp = new RegExp(
  '^(.*\\.|)(' + regexStrFrom(vkDomains) + ')$'
);

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
    // Open VK Calls links in VK Calls app
    {
      match: ({ url }) => url.host === "vk.com" && url.pathname.startsWith('/call/join/'),
      url({ url }) {
        const callId = url.pathname.replace(/^\/call\/join\//, '');

        return {
          host: 'vk.com',
          search: `callId=${encodeURIComponent(callId)}`,
          pathname: '/join',
          protocol: 'vkcalls',
        }
      },
    },
  ],
  handlers: [
    // Open VK domains in Firefox
    {
      match: ({ url }) => vkDomainRegexp.test(url.host),
      browser: "Firefox",
    },
    // Open Zoom links in Zoom
    {
      match: [
        finicky.matchDomains(/.*zoom.us/),
      ],
      browser: "us.zoom.xos",
    },
    // Open VK Calls apps in VK Calls
    {
      match: ({ url }) => url.protocol === 'vkcalls',
      browser: 'VK Calls',
    },
    // Open Spotify links in Spotify
    {
      match: finicky.matchDomains("open.spotify.com"),
      browser: "Spotify",
    },
    // Finally, open all http/https from VK Teams in Firefox
    {
      match: ({ url, opener }) => (
        url.protocol === 'https' || url.protocol === 'http'
      ) && opener.bundleId === "ru.mail.messenger-biz-avocado-desktop",
      browser: "Firefox",
    },
  ]
};
