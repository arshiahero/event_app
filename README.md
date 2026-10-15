# event.

A dark, editorial event-discovery app inspired by Fever, implemented from `New Text Document (3).txt`. English, LTR, London by default, British pounds and Gregorian dates.

## Screens and mock flows

- **Home:** atmospheric carousel, categories, ranked trending cards, inspiration collections and more experiences.
- **Search:** debounced queries, popular searches, eight moods, horizontal results and an interactive offline map preview.
- **Discover:** image-led categories, sorting and category/date/price filters.
- **Event:** event-specific gallery, fullscreen zoom, sharing, community reviews, FAQs, venue preview and booking controls.
- **Booking:** date, time and quantity selection; confirmation and animated success; session reservation storage.
- **Tickets:** Upcoming/Past tabs and reservation-detail overlay.
- **Profile:** persistent desktop sidebar, mobile menu, interests, notifications and favourites.
- **Club:** sample membership, points, milestones and locally claimable rewards.
- **Gift cards:** amount selection, recipient/message form and sample confirmation.
- **Support:** help topics, FAQs and a local request form.
- **Demo sign-in/register:** branded forms with validation and a session display name.

All data and transactions are mocks. No payment, real ticket, redeemable gift card, support message, account, JWT or backend request is created. Data resets when the app session ends. Sample events are available on every selectable date; the date filter prefills booking rather than checking real inventory. City filtering uses London and Barcelona sample events; other cities have a designed empty state. Map positions are illustrative, not navigation data.

## Design system

`lib/core/theme/app_theme.dart` defines colors, typography, dimensions, gradients, shadows and component themes from the specification. DM Sans is bundled. Navigation switches at 801px; layouts use mobile/tablet/desktop spacing and retain tab state. Cards, galleries, modals, favourites, buttons and the carousel include their respective hover and motion states.

## Run later

```sh
flutter pub get
flutter run -d chrome
```

## Build later

```sh
flutter build web --release
flutter build apk --release
```

Web output: `build/web`. Configure the web host to serve `index.html` for application routes. Android requires its SDK and Gradle dependencies; iOS requires macOS and Xcode.

Testing is deferred while completing the design. Existing visual baselines are from an earlier design iteration; review and refresh them before using visual regression tests as an acceptance check.

## Assets

Candlelight, immersive and garden images are cropped from the reference screenshots supplied in `pic/`; gallery crops are illustrative. Other sample images are bundled from Unsplash. Replace screenshot-derived crops with licensed high-resolution originals before publishing. DM Sans is bundled under the SIL Open Font License (`assets/fonts/DMSans-OFL.txt`). No runtime image or font download is required.
