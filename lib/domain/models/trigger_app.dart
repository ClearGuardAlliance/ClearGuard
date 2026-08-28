enum TriggerAppCategory { socialMedia, dating, messaging, circumvention }

class TriggerApp {
  const TriggerApp({
    required this.packageName,
    required this.displayName,
    required this.category,
    required this.weight,
  });

  final String packageName;
  final String displayName;
  final TriggerAppCategory category;

  final int weight;

  static const catalog = <TriggerApp>[
    TriggerApp(
      packageName: 'com.instagram.android',
      displayName: 'Instagram',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.zhiliaoapp.musically',
      displayName: 'TikTok',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.snapchat.android',
      displayName: 'Snapchat',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.twitter.android',
      displayName: 'X (Twitter)',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.reddit.frontpage',
      displayName: 'Reddit',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.tumblr',
      displayName: 'Tumblr',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.facebook.katana',
      displayName: 'Facebook',
      category: TriggerAppCategory.socialMedia,
      weight: 1,
    ),
    TriggerApp(
      packageName: 'com.pinterest',
      displayName: 'Pinterest',
      category: TriggerAppCategory.socialMedia,
      weight: 1,
    ),
    TriggerApp(
      packageName: 'tv.twitch.android.app',
      displayName: 'Twitch',
      category: TriggerAppCategory.socialMedia,
      weight: 1,
    ),
    TriggerApp(
      packageName: 'com.tinder',
      displayName: 'Tinder',
      category: TriggerAppCategory.dating,
      weight: 3,
    ),
    TriggerApp(
      packageName: 'com.bumble.app',
      displayName: 'Bumble',
      category: TriggerAppCategory.dating,
      weight: 3,
    ),
    TriggerApp(
      packageName: 'com.grindrapp.android',
      displayName: 'Grindr',
      category: TriggerAppCategory.dating,
      weight: 3,
    ),
    TriggerApp(
      packageName: 'co.hinge.app',
      displayName: 'Hinge',
      category: TriggerAppCategory.dating,
      weight: 3,
    ),
    TriggerApp(
      packageName: 'org.telegram.messenger',
      displayName: 'Telegram',
      category: TriggerAppCategory.messaging,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.discord',
      displayName: 'Discord',
      category: TriggerAppCategory.messaging,
      weight: 1,
    ),
    TriggerApp(
      packageName: 'kik.android',
      displayName: 'Kik',
      category: TriggerAppCategory.messaging,
      weight: 2,
    ),
    TriggerApp(
      packageName: 'com.nordvpn.android',
      displayName: 'NordVPN',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
    TriggerApp(
      packageName: 'com.expressvpn.vpn',
      displayName: 'ExpressVPN',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
    TriggerApp(
      packageName: 'ch.protonvpn.android',
      displayName: 'Proton VPN',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
    TriggerApp(
      packageName: 'com.psiphon3',
      displayName: 'Psiphon',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
    TriggerApp(
      packageName: 'com.windscribe.vpn',
      displayName: 'Windscribe',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
    TriggerApp(
      packageName: 'org.torproject.torbrowser',
      displayName: 'Tor Browser',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
    TriggerApp(
      packageName: 'org.torproject.android',
      displayName: 'Orbot',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    ),
  ];
}
