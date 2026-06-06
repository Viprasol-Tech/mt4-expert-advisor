<p align="center">
  <img src="docs/assets/logo.png" width="120" alt="Viprasol Tech logo">
</p>

<h1 align="center">MT4 Expert Advisor</h1>

<p align="center">
  <strong>A production-grade MetaTrader 4 (MQL4) Expert Advisor — EMA crossover with RSI/ADX filters, fixed-or-risk money management, break-even, trailing stops, a daily trade cap, and a live on-chart dashboard.</strong>
</p>

<p align="center">
  <em>Built and maintained by <a href="https://viprasol.com">Viprasol Tech</a> — Fintech Experts. Full-Stack Builders.</em>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Viprasol-Tech/mt4-expert-advisor?style=flat-square&color=blue" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/platform-MetaTrader%204-orange?style=flat-square" alt="MetaTrader 4">
  <img src="https://img.shields.io/badge/language-MQL4-blue?style=flat-square" alt="MQL4">
  <img src="https://img.shields.io/badge/version-0.2.0-success?style=flat-square" alt="Version 0.2.0">
  <a href="https://t.me/viprasol_help"><img src="https://img.shields.io/badge/Telegram-support-26A5E4?style=flat-square&logo=telegram&logoColor=white" alt="Telegram"></a>
</p>

---

> ## ⚠️ Disclaimer
> This Expert Advisor is for **educational purposes only** and is **not financial advice**. Trading leveraged instruments carries substantial risk, including the **rapid loss of capital**. Backtest and forward-test on a **demo account** before any live use. **Use at your own risk** — Viprasol Tech assumes no responsibility for your trading results.

---

## ✨ Features

- 📈 **EMA crossover signals** — configurable fast/slow periods, MA method, and applied price on any symbol/timeframe.
- 🧪 **Entry filters** — confirm with **RSI** (skip overbought longs / oversold shorts), require trend strength via **ADX**, restrict to a **server-time window** (overnight-wrap aware), and reject **wide spreads**.
- 💰 **Money management** — switch between a **fixed lot** and **risk-percent** sizing computed from the ATR stop distance and the symbol's tick value.
- 🛡️ **ATR stop-loss & take-profit** — stops and targets scale with volatility.
- 🪜 **Break-even** — lifts the stop to entry (plus a configurable lock) once the trade reaches a profit threshold in ATR.
- 🏃 **Trailing stop** — three modes (off / fixed points / ATR multiple) with a minimum-step guard so the stop only ever tightens.
- 🧮 **Daily trade cap** — limit new entries per server day; the counter rolls over at the day boundary and is rebuilt on attach.
- 🧱 **Magic-number trade management** — only ever touches its own trades; break-even and trailing run on every tick.
- 📊 **On-chart dashboard** — a live panel showing position, last signal, spread, sizing mode, trailing/break-even state, trades today, and equity.
- 🧷 **Defensive order handling** — every `OrderSend` / `OrderModify` / `OrderClose` is result-checked and logs `GetLastError()` on failure; 3/5-digit quotes are pip-normalised.

## 🚀 How to install & run on MetaTrader 4

1. In MetaTrader 4: **File → Open Data Folder**, then open `MQL4/Experts/`.
2. Copy `src/ViprasolMACrossEA.mq4` into that `Experts/` folder.
3. Open it in **MetaEditor** and press **Compile** (F7) to produce `ViprasolMACrossEA.ex4`.
4. Back in MT4, refresh the **Navigator → Expert Advisors** list.
5. Enable **AutoTrading** (the toolbar button), then drag the EA onto a chart.
6. In the dialog, tick **Allow live trading** under *Common*, set your inputs, and click **OK**.

> 🧪 **Test first.** Run it in the **Strategy Tester** (Ctrl+R) and on a **demo account** before going live. Compiled `.ex4` binaries are git-ignored — always compile from source in MetaEditor.

## ⚙️ Inputs / parameters

| Input | Default | Description |
|-------|---------|-------------|
| `FastPeriod` / `SlowPeriod` | 12 / 26 | EMA periods (fast must be < slow). |
| `MAMethod` / `MAPrice` | EMA / Close | Moving-average method and applied price. |
| `UseRSIFilter` | true | Confirm entries with RSI. |
| `RSIPeriod` | 14 | RSI period. |
| `RSIBuyMax` / `RSISellMin` | 70 / 30 | Skip longs above / shorts below these RSI levels. |
| `UseADXFilter` | true | Require trend strength before entering. |
| `ADXPeriod` / `ADXMin` | 14 / 20 | ADX period and minimum ADX to trade. |
| `UseTimeFilter` | false | Restrict trading to a server-time window. |
| `StartHour` / `EndHour` | 7 / 20 | Trading window (0–23; wraps past midnight). |
| `UseSpreadFilter` | true | Skip entries when the spread is too wide. |
| `MaxSpreadPoints` | 30 | Maximum allowed spread (points). |
| `ATRPeriod` | 14 | ATR period for stops. |
| `SL_ATR` / `TP_ATR` | 2.0 / 3.0 | Stop / target as multiples of ATR. |
| `LotMode` | Risk | `Fixed` lot size or `Risk` percent of equity. |
| `FixedLots` | 0.10 | Lots used when `LotMode = Fixed`. |
| `RiskPercent` | 1.0 | Equity % risked when `LotMode = Risk`. |
| `UseBreakEven` | true | Move the stop to break-even when in profit. |
| `BE_TriggerATR` | 1.0 | Profit (in ATR) needed to arm break-even. |
| `BE_LockPoints` | 20 | Points locked beyond entry at break-even. |
| `TrailMode` | ATR | Trailing mode: off / points / ATR multiple. |
| `TrailPoints` | 300 | Trail distance (points) when `TRAIL_POINTS`. |
| `TrailATR` | 2.0 | Trail distance (ATR) when `TRAIL_ATR`. |
| `TrailStepPoints` | 10 | Minimum SL improvement to modify (points). |
| `CloseOnOpposite` | true | Exit on an opposite EMA cross. |
| `MaxTradesPerDay` | 5 | Max new trades per server day (0 = off). |
| `MagicNumber` | 20250101 | Identifies this EA's trades. |
| `Slippage` | 30 | Max slippage (points). |
| `ShowDashboard` | true | Draw the on-chart dashboard. |

## 🗺️ Roadmap

- [x] EMA crossover entries with ATR stops/targets
- [x] Risk-percent and fixed money management
- [x] RSI / ADX / time / spread entry filters
- [x] Break-even and trailing stop
- [x] Daily trade cap and on-chart dashboard
- [ ] Partial take-profit (scale out at TP1 / TP2)
- [ ] Higher-timeframe trend filter
- [ ] News / high-impact event blackout window
- [ ] Email / push notifications on entry and exit
- [ ] Equity-based daily drawdown circuit breaker

## ❓ FAQ

**Does it work on MetaTrader 5?**
This EA targets **MQL4 / MetaTrader 4**. An MT5 port would require the `CTrade` API and is not included here.

**Can I run it on multiple charts at once?**
Yes — give each instance a distinct `MagicNumber` so trade management never crosses streams.

**Risk percent or fixed lots — which should I use?**
`Risk` sizing scales position size to your stop distance and equity for consistent per-trade risk. `Fixed` is simpler and predictable. Start with a small fixed lot on demo, then move to risk-based sizing.

**Why didn't it enter on a cross?**
An enabled filter likely blocked it (RSI/ADX/time/spread) or the daily cap was hit. The on-chart dashboard shows the last reason (e.g. `blocked: spread`).

**Does the stop trail on every tick?**
Yes. Signal evaluation is once-per-bar, but break-even and trailing are applied on each tick for responsiveness.

## 🤝 Contributing

Contributions are welcome. Open an issue to discuss a change, then submit a pull request. Please keep the MQL4 valid (compiles cleanly in MetaEditor with `#property strict`), keep inputs documented in the table above, and update `CHANGELOG.md`.

## Contact — Viprasol Tech Private Limited

- Website: [viprasol.com](https://viprasol.com)
- Email: [support@viprasol.com](mailto:support@viprasol.com)
- Telegram: [t.me/viprasol_help](https://t.me/viprasol_help) | WhatsApp: +91 96336 52112
- GitHub: [@Viprasol-Tech](https://github.com/Viprasol-Tech) | [LinkedIn](https://www.linkedin.com/in/viprasol/) | X [@viprasol](https://twitter.com/viprasol)

## License

[MIT](LICENSE) (c) 2025 Viprasol Tech Private Limited
