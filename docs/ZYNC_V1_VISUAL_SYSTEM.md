# Zync V1 — Visual System & Release QA

This document is the visual source of truth for the V1 rebuild. The product must not ship looking like a default Flutter demo or a functional prototype.

## 1. Brand idea

Zync visualizes **connection through overlapping interests**. The core mark is two overlapping rings: warm orange for one person, electric plum for the other. Their overlap is the product idea — two different people discovering a connection.

The visual language should feel:

- warm and social, not corporate;
- modern and international, not tied to one culture;
- playful enough to invite interaction, but not childish;
- premium enough that screenshots look launch-ready;
- simple enough to remain readable across eight initial languages.

## 2. Core palette

- `Ink` — `#17181C` — primary text / strong contrast
- `Ink Soft` — `#5F626B` — supporting text
- `Zync Orange` — `#FF6A21` — primary action / Person A / energy
- `Orange Deep` — `#E65310` — stronger orange state
- `Peach` — `#FFE5D6` — orange support surface
- `Cream` — `#FFFAF6` — main background / launch background
- `Surface` — `#FFFFFF` — cards / QR contrast surface
- `Line` — `#E9E4DF` — quiet borders
- `Plum` — `#6E5AE6` — Person B / connection contrast / secondary accent
- `Mint` — `#BDECDD` — positive secondary state
- `Blue` — `#9FC8FF` — optional tertiary information accent

Orange is the dominant call-to-action color. Plum exists to communicate the second person / counterpart, not to create a two-primary-color UI.

## 3. Mark / graphics

The reusable Zync mark is two overlapping circular rings. It is implemented as source-controlled vector/code artwork, not a stock icon.

Use it for:

- loading state;
- launcher icon;
- splash / launch screen;
- match / connection moments;
- empty states where connection is the subject.

Do not add decorative stock people photography to V1. The product itself should create the personality through motion, typography, interest labels and the connection motif.

## 4. Layout rules

- Standard horizontal page padding: 20–24 dp.
- Standard card radius: 22–24 dp.
- Main actions: minimum 54 dp height.
- Small icon tiles: about 46 dp.
- Prefer one clear primary action per visual block.
- Avoid dense settings-style rows on consumer-facing moments.
- Avoid full-width dividers when card separation or whitespace can do the job.
- Keep important UI inside comfortable thumb reach on ordinary Android phones.

## 5. Typography

Use the platform system font so every supported script renders well without shipping a large custom font bundle.

Hierarchy matters more than font novelty:

- hero / magic moment: large, heavy, short;
- page heading: strong but compact;
- card title: semibold/bold;
- explanatory copy: softer ink and generous line height;
- metadata: clearly secondary.

Do not rely on all-caps except short brand moments such as `YOU ZYNC!`.

## 6. Motion / interaction

V1 motion should be restrained and purposeful:

- Hidden Match reveal: quick scale/fade or slide reveal, with haptic feedback on supported devices.
- Question refresh: AnimatedSwitcher / crossfade rather than abrupt text replacement.
- Scanner: subtle moving scan line and clear processing state.
- Loading: branded mark, not a generic spinner as the only visual.

Animation must never delay the user from continuing.

## 7. Screen quality bar

### Onboarding / Interests

- User understands the product before being asked to fill data.
- Interest selection count is always visible.
- Search and AI-add state are obvious.
- Keyboard must not cover the final action.
- Long interest labels must wrap or truncate gracefully.

### Home

- `Zync with someone` is visually dominant.
- Show QR and Scan are immediately distinguishable.
- My Interests / History / Interest DNA are clearly secondary.
- The page should not resemble a settings screen.

### Show QR

- QR must remain high-contrast and unobstructed.
- No decorative element may enter the QR quiet zone.
- Nickname / identity is secondary to scan success.
- Privacy explanation is visible but not alarming.

### Scanner

- Camera fills the useful screen area.
- Scan frame remains visible against light and dark backgrounds.
- Error / processing state is readable in one glance.
- Back navigation remains obvious.

### Match Reveal

This is the V1 magic moment and should receive the most polish.

- Initial state celebrates the number of hidden matches without revealing them.
- Every reveal should feel rewarding but fast.
- Interest label has visual priority over metadata.
- Zero exact matches must still feel positive because AI crossover is the reward.

### Conversation

- Question is the focal object on screen.
- Mode switching is easy with one hand.
- Local fallback remains usable and should not look like a broken state.

### History

- Empty state explains why the screen matters.
- Returning users can understand person, match count, session count and recency quickly.

### Interest DNA

- Must feel share-worthy even if actual share export is not in V1.
- Avoid implying scientific personality analysis.
- Show ranked interest/category mix clearly.

## 8. Localization QA

Test at least:

- English
- Traditional Chinese
- Simplified Chinese
- Japanese
- Korean
- Spanish
- French
- Portuguese

For every screen test:

- 320 dp wide small Android layout;
- ordinary ~360–412 dp phone;
- large text / accessibility font scaling;
- long strings (especially French, Portuguese and Spanish);
- CJK line breaking;
- no clipped button labels;
- no fixed-height text containers where wrapping is expected.

## 9. Accessibility

- Keep primary text contrast high against Cream / White.
- Do not communicate state by color alone.
- Touch targets should be at least ~48 dp where practical.
- Icons that perform actions need semantic/tool-tip labels.
- Haptics supplement visual feedback; they never replace it.

## 10. Release visual sign-off checklist

Before Play internal testing, explicitly verify:

- launcher icon is Zync artwork, not Flutter default;
- Android launch / splash screen is branded and visually continuous with app loading;
- no debug banners;
- no default Flutter placeholder graphics;
- no raw canonical IDs visible to users;
- no English fallback on supported-locale core flows unless intentionally accepted;
- no RenderFlex overflow on supported test widths;
- QR scans reliably from another physical device;
- scanner permission denial / retry is understandable;
- AI loading, timeout and fallback all look intentional;
- Hidden Match reveal feels like the product's signature moment.

This document should be updated if the visual direction changes materially. Do not silently drift screen-by-screen into unrelated styles.
