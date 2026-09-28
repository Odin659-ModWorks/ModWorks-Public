# HWDE Faster Bazaar (local bundle)

Combines the four independently tested Hyrule Warriors: Definitive Edition
update 1.0.1 UI-speed add-ons into one Eden add-on for this PC:

- Faster Blacksmith Confirmations
- Faster Training Results (Dojo)
- Faster Apothecary Confirmations
- Faster Badge Market Confirmations

The individual source projects remain separate for independent releases. This
bundle copies their ten cheat writes without changing addresses or opcodes.
It targets title ID `0100AE00096EA000`, build ID `815A2C19D1767896`.

## Development and test record

The four menus were analyzed and released independently first, because their waits live in different state flows: the Blacksmith waits on two animation completions, the Dojo has a repeated countdown, the Apothecary has a result-effect duration and layout wait, and the Badge Market uses animation playback rates. Each standalone add-on was reported working in play. The bundle was then assembled from those same ten writes so the user could keep a single local Faster Bazaar entry. There is no new global speed hook in the bundle. The component histories live in each source project's `README.md`.

No bundle-specific defect has been reported. If a future component changes, rebuild this package from the four current standalone patches and compare every write; do not add a second, contradictory patch at the same address.
