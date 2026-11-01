# Localization architecture — Phase 0.5

## Coverage and ownership
`localization/ui.csv` is the editable UTF-8 source: 76 stable keys × 7 complete locales.
Godot's CSV importer generates the checked-in `ui.<locale>.translation` resources.
Project settings register them with `TranslationServer`; English is the fallback.
Commit CSV, .import metadata and regenerated .translation files together.

All existing player UI uses translation keys, including garden captions, dialogs,
settings, selected bed, labels, accessibility names and the painted wooden sign.
The CSV also includes initial plant names/descriptions, variants, future core
buttons, tutorial steps, notifications and save errors. Those future features are
not implemented by adding their strings. Boot has no visible textual menu.

`GardenStrings` retains the Phase 0 module as an alias list of stable keys.
Do not put translated names into gameplay IDs, resources or saves. PlotData still
uses stable `id` and `species_id` values. Only UI labels translate.

## Preferences lifecycle
`SettingsManager` is a real preferences-only autoload, introduced here because
language selection and reduced motion require it. Other planned gameplay autoloads
remain deferred. On first run it calls `OS.get_locale()`, resolves a supported
locale, sets TranslationServer and persists the result. Later runs prefer saved
language even if OS language changed.

Mappings: en_US/en-GB→en, ru_RU→ru, pl_PL→pl, es_MX→es, de_AT→de,
fr_CA→fr; case and hyphen/underscore variants are accepted. pt_BR/pt-BR stay pt_BR;
generic pt maps to pt_BR. pt_PT and all other unsupported languages fall back to en.
The explicit pt_BR locale is never shortened to an unregistered pt translation.

Preferences live in `user://settings_v1.cfg`, written to a sibling .tmp then renamed.
The file contains only `preferences.language` and `preferences.reduced_motion`.
No gameplay save, currencies, inventories or timestamps are read or rewritten.
A write failure is exposed through a localized nonblocking message. Platform-specific
atomic replacement still requires mobile testing.

`set_language()` updates TranslationServer synchronously, then emits language_changed.
The existing HUD updates text and measures layout without reloading the scene,
replacing plots or clearing selection. The environment handles translation-change
notification to repaint its sign. Language choices always use their native names;
the selected option gets a checkmark and tinted background, not color alone.

## Formatting and fonts
Open Sans regular is bundled with its license. The test suite verifies all unique
characters used in all seven translations, including Cyrillic, Polish accents,
French accents, German umlauts, Spanish ñ and Portuguese diacritics.

`SettingsManager.format_integer()` groups integers with comma (en), narrow no-break
space (ru/pl/fr) or period (de/es/pt_BR). `format_duration()` uses translated compact
unit templates. Future price displays should format the count first, then apply
PRICE_COINS. No real-money pricing or OS notification integration is introduced.

The UI uses a 390×844 logical reference, 14px minor captions, 16px body text,
17px buttons, 21–23px cards/dialog headings and 32px game branding. Text wraps;
fonts are not shrunk for longer translations. The game brand stays Mutant Garden
in every locale. Physical exports may render at any pixel density.

## Adding text
1. Add a stable uppercase key and all seven nonempty translations to ui.csv.
2. Preserve the order/type of %s/%d formatting placeholders.
3. Reimport CSV in Godot; check generated locale resources into source control.
4. Bind key through the garden UI binding helper or use tr(key) for dynamic text.
5. Avoid concatenating inflected plant/variant names in future languages; prefer
   contextual localized templates or separate labeled fields.
6. Run both GDScript suites and capture long translations at the two phone sizes.

## Verification boundaries
Tests cover catalog completeness, glyph support, English fallback via an English-only
test key, immediate UI changes, stable model identity, a gameplay-file sentinel,
OS mapping and separate-process preference persistence. A sentinel is not a test
of future gameplay saves: crop timers and reward transactions do not exist yet.

All 42 garden/settings/language screenshots were visually inspected. Native-speaker
editorial review, real Android/iOS keyboards, screen readers and device locale APIs
were not tested. Those remain explicit release QA tasks.
