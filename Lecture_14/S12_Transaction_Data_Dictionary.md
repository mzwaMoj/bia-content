# Synthetic transaction data dictionary

These files describe a fictional retailer's transaction batches for 1–14 September 2026. They contain no customer or contact information. Each row is intended to represent **one single-category transaction**, identified by `transaction_id`. Repeated categories, hubs, and dates are normal; inspect business IDs and row contents before deciding whether records repeat.

## Files and period

| File | Contents |
| --- | --- |
| `S12_Transactions_Week1.csv` | Nominal batch for 1–7 September 2026. |
| `S12_Transactions_Week2.csv` | Nominal batch for 8–14 September 2026. One carried-over record keeps its earlier transaction date, so file membership alone does not establish the transaction date. |
| `S12_Hub_Reference.xlsx` | Sheet `Hub Reference`, with one row for each valid hub code. |

The CSVs use UTF-8, a header row, comma separators, and the same column order. Dates are ISO-style text (`YYYY-MM-DD`). Prices are in US dollars per unit. The workbook is a standard `.xlsx` file with no macros.

## Transaction fields

| Field | Meaning |
| --- | --- |
| `transaction_id` | Text business identifier. It is a key, not a quantity to sum or average. |
| `transaction_date` | Calendar date of the recorded transaction. Parse it before date analysis. |
| `hub_code` | Short key used to join the hub reference. Valid reference codes are `E`, `C`, and `W`. |
| `category` | Single category assigned to the transaction: `Essentials`, `Home`, or `Electronics`. |
| `units` | Intended positive count of units. Inspect and convert the raw field before calculation. |
| `unit_price` | Price per unit in USD. A blank value means missing information, not a zero price. |
| `discount_rate` | Fraction of the pre-discount amount removed: `0.10` means 10% off. Valid values lie from 0 through 1. |
| `status` | `Fulfilled` or `Cancelled`. Cancelled records remain in the raw data for inspection. |

## Hub reference fields

| Field | Meaning |
| --- | --- |
| `hub_code` | Unique lookup key: `E`, `C`, or `W`. |
| `hub_name` | `East Hub`, `Central Hub`, or `West Hub`. |
| `region` | A descriptive operating-area label for this fictional retailer. It does not identify a real facility or certified geography. |

## Reporting measure

For validated, deduplicated, **Fulfilled** transactions with a matched hub, usable positive numeric units, usable nonnegative numeric price, valid discount rate, and valid date:

`net_order_value = units * unit_price * (1 - discount_rate)`

This is discount-adjusted **pre-tax fulfilled order value in USD**. It excludes tax and shipping and is not recognised accounting revenue. Keep excluded raw records available for a quality audit; do not replace a missing price with zero by default.

## Opening the files

Place all three files beside a local Jupyter/JupyterLab notebook, or upload them into the Colab session's current working directory. Then relative paths work in either setting:

```python
import pandas as pd

week1 = pd.read_csv("S12_Transactions_Week1.csv")
week2 = pd.read_csv("S12_Transactions_Week2.csv")
hubs = pd.read_excel("S12_Hub_Reference.xlsx", sheet_name="Hub Reference")
```

If the Excel read reports that `openpyxl` is missing, install the free reader in that notebook environment (`%pip install openpyxl`) and rerun the read. Uploaded Colab files must be uploaded again when its temporary runtime is reset. No account, API, or network request is needed to read these files after they are local.
