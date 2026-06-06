# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-15

### Added
- **Entry filters** — optional RSI confirmation (skip overbought longs / oversold
  shorts), ADX trend-strength gate, server-time trading window (with overnight
  wrap support), and a max-spread filter.
- **Money management modes** — choose between a fixed lot size and risk-percent
  sizing via the new `LotMode` input.
- **Break-even** — automatically lifts the stop to entry (+ a configurable lock)
  once a trade reaches a profit threshold expressed in ATR.
- **Trailing stop** — three modes (off / fixed points / ATR multiple) with a
  minimum-step guard so the stop only ever tightens.
- **Daily trade cap** — `MaxTradesPerDay` limits new entries per server day, with
  a counter that rolls over at the day boundary and is rebuilt on attach.
- **On-chart dashboard** — live `Comment()` panel showing position, last signal,
  spread, sizing mode, trailing/break-even state, trades today, and equity.
- **Configurable MA method / applied price** and a `CloseOnOpposite` toggle.
- Section-separated, grouped inputs for a cleaner properties dialog.
- `CHANGELOG.md` following Keep a Changelog.

### Changed
- 3- and 5-digit broker quotes are now normalised via a pip factor so point-based
  inputs (spread, trailing, break-even lock) behave consistently across brokers.
- All `OrderSend` / `OrderModify` / `OrderClose` calls now check their result and
  log `GetLastError()` on failure.
- Lot normalisation centralised in a single helper that respects min/max/step.
- Trailing and break-even run on every tick; signal evaluation stays once-per-bar.
- README rewritten to flagship standard with inputs table, roadmap, and FAQ.

## [0.1.0] - 2025-01-01

### Added
- Initial release: EMA crossover Expert Advisor for MetaTrader 4 (MQL4).
- Risk-based lot sizing from the ATR stop distance and symbol tick value.
- ATR-scaled stop-loss and take-profit.
- Once-per-bar logic, opposite-cross exit, and magic-number trade isolation.

[0.2.0]: https://github.com/Viprasol-Tech/mt4-expert-advisor/releases/tag/v0.2.0
[0.1.0]: https://github.com/Viprasol-Tech/mt4-expert-advisor/releases/tag/v0.1.0
