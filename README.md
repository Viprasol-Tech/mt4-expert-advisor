<p align="center">
  <img src="docs/assets/logo.png" width="120" alt="Viprasol Tech logo">
</p>

<h1 align="center">MT4 Expert Advisor</h1>

<p align="center">
  <strong>A complete MetaTrader 4 (MQL4) Expert Advisor — EMA crossover with risk-based lot sizing and ATR stops.</strong>
</p>

<p align="center">
  <em>Built and maintained by <a href="https://viprasol.com">Viprasol Tech</a> — Fintech Experts. Full-Stack Builders.</em>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Viprasol-Tech/mt4-expert-advisor?style=flat-square&color=blue" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-MetaTrader%204-orange?style=flat-square" alt="MT5">
  <img src="https://img.shields.io/badge/language-MQL4-blue?style=flat-square" alt="MQL4">
  <a href="https://t.me/viprasol_help"><img src="https://img.shields.io/badge/Telegram-support-26A5E4?style=flat-square&logo=telegram&logoColor=white" alt="Telegram"></a>
</p>

---

> ## ⚠️ Disclaimer
> This Expert Advisor is for **educational purposes only** and is **not financial advice**. Trading leveraged instruments carries substantial risk, including the **rapid loss of capital**. Backtest and forward-test on a **demo account** before any live use. **Use at your own risk** — Viprasol Tech assumes no responsibility for your trading results.

---

## ✨ What it does

- 📈 **EMA crossover signals** — configurable fast/slow EMAs on any timeframe.
- 🎯 **Risk-based position sizing** — risk a fixed % of equity, computed from the ATR stop distance and the symbol's tick value.
- 🛡️ **ATR stop-loss & take-profit** — stops/targets scale with volatility.
- 🔁 **Once-per-bar logic**, opposite-cross exit, and a magic-number guard so it manages only its own trades.
- 🧱 Built on the standard `OrderSend API; broker volume constraints (min/max/step) respected.

## 🚀 Install

1. Copy `src/ViprasolMACrossEA.mq4` into your terminal's `MQL4/Experts/` folder
   (in MetaTrader 4: **File → Open Data Folder**).
2. Open it in **MetaEditor** and press **Compile** (F7) to produce `ViprasolMACrossEA.ex4`.
3. In MT5, drag the EA onto a chart, allow algo-trading, and configure inputs.

> Compiled `ex4 ` binaries are git-ignored — compile from source in MetaEditor.

## ⚙️ Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `FastPeriod` / `SlowPeriod` | 12 / 26 | EMA periods (fast must be < slow) |
| `RiskPercent` | 1.0 | Equity % risked per trade |
| `ATRPeriod` | 14 | ATR period for stops |
| `SL_ATR` / `TP_ATR` | 2.0 / 3.0 | Stop / target as multiples of ATR |
| `MagicNumber` | 20250101 | Identifies this EA's trades |

## Contact — Viprasol Tech Private Limited

- 🌐 Website: [viprasol.com](https://viprasol.com)
- ✉️ Email: [support@viprasol.com](mailto:support@viprasol.com)
- 💬 Telegram: [t.me/viprasol_help](https://t.me/viprasol_help) · 📱 WhatsApp: +91 96336 52112
- 🐙 GitHub: [@Viprasol-Tech](https://github.com/Viprasol-Tech) · 💼 [LinkedIn](https://www.linkedin.com/in/viprasol/) · 𝕏 [@viprasol](https://twitter.com/viprasol)

> *Viprasol Tech — algorithmic trading systems, MT4/MT4 Expert Advisors, fintech software, and AI agents. Need a custom EA? [Get in touch](mailto:support@viprasol.com).*

## License

[MIT](LICENSE) © 2025 Viprasol Tech Private Limited
