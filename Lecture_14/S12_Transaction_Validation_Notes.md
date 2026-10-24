# S12 synthetic transaction pack — internal validation notes

For trainer and downstream artifact production. The files are newly synthesised, contain no real customer records, and represent a simplified one-row, one-category transaction export. All amounts below are **discount-adjusted pre-tax fulfilled order value (USD)**, calculated as `units * unit_price * (1 - discount_rate)` after the eligibility checks. They are not recognised accounting revenue.

## Files, scope, and structure

| Saved file | Actual rows | Date coverage in that file |
| --- | ---: | --- |
| `S12_Transactions_Week1.csv` | 56 | 2026-09-01 to 2026-09-07; eight rows per day. |
| `S12_Transactions_Week2.csv` | 57 | 56 legitimate rows dated 2026-09-08 to 2026-09-14 (eight per day), plus one exact Week 1 carryover dated 2026-09-03. Raw file minimum and maximum dates are therefore 2026-09-03 and 2026-09-14. |
| `S12_Hub_Reference.xlsx` | 3 lookup rows | One visible sheet, `Hub Reference`; unique, nonmissing keys `E`, `C`, `W`. |

The two CSVs have the same eight ordered fields: `transaction_id`, `transaction_date`, `hub_code`, `category`, `units`, `unit_price`, `discount_rate`, `status`. They concatenate to **113 raw rows**. All 14 intended transaction dates appear; raw date counts are eight per day except 2026-09-03, which has nine because of the carryover. The three-column Excel lookup has `hub_code`, `hub_name`, `region` and maps `E` → East Hub, `C` → Central Hub, `W` → West Hub. Its region labels are fictional operating-area descriptions, not real geography.

### Raw distributions

| Dimension | Counts (113 raw rows) | Counts after removing the exact repeat (112 distinct rows) |
| --- | --- | --- |
| Status | Fulfilled 99; Cancelled 14 | Fulfilled 98; Cancelled 14 |
| Hub code | C 47; E 33; W 32; unmatched X 1 | C 47; E 33; W 31; X 1 |
| Category | Electronics 26; Essentials 50; Home 37 | Electronics 26; Essentials 49; Home 37 |

The only raw missing field is one blank `unit_price`. `transaction_id` is a textual key, never a measure. All valid dates parse; all supplied discounts lie in `[0, 1]`; all usable numeric units are positive and all present prices nonnegative. The intended category and status sets have no extra labels.

## Seeded issues: record-level evidence

CSV line numbers include the header as line 1. The cases are on separate fulfilled transactions, except that the duplicate is the same record in both files.

| Issue | Transaction ID and location | Actual evidence and treatment |
| --- | --- | --- |
| Exact cross-file carryover | `TXN-260903-008`: Week 1 line 25; Week 2 line 58 | Both complete source rows are identical: date `2026-09-03`, hub W, Essentials, units `1`, unit price `6.80`, discount `0.00`, Fulfilled. It is one full-row duplicate and one duplicate business ID. Keep the Week 1 copy; remove one Week 2 copy. It contributes only once to eligible value. |
| Missing price | `TXN-260902-007`: Week 1 line 16 | `unit_price` is genuinely blank and reads as missing in pandas. Exclude from value aggregation; do not replace with zero. |
| Text units | `TXN-260906-003`: Week 1 line 44 | Raw `units` is `three`; `pd.to_numeric(..., errors="coerce")` returns missing. Exclude after flagging. |
| Text units | `TXN-260909-005`: Week 2 line 14 | Raw `units` is `two`; numeric coercion returns missing. Exclude after flagging. |
| Unmatched lookup key | `TXN-260904-008`: Week 1 line 33 | `hub_code` is `X`, absent from the three-row reference. A left merge exposes it with no lookup fields; exclude from eligible value without erasing the raw record. |

Two text-unit cases keep `units` visibly mixed-type in **both** weekly CSV reads. This also allows an ordinary pandas concat followed by full-row `.duplicated()` to identify the copied row without a cross-batch integer-versus-string mismatch in the otherwise equal `units` cell. The Week 2 out-of-period date is intrinsic to an exact carryover and is not treated as a legitimate Week 2 transaction date.

## Eligibility and count reconciliation

The validation run first concatenated the files, inspected both full-row and ID duplicates, and retained the first exact copy. It then parsed dates, coerced `units`, `unit_price` and `discount_rate` to numeric, validated the source values, and left-merged on `hub_code` with `validate="many_to_one"`. A valid analytical row must be Fulfilled, unique, have positive numeric units, nonnegative present numeric price, discount in `[0, 1]`, a parsed date, and a matched hub.

| Stage or disjoint reason | Rows |
| --- | ---: |
| Raw concatenated records | 113 |
| Removed exact repeated row | 1 |
| Distinct transactions after deduplication | 112 |
| Cancelled | 14 |
| Invalid/nonpositive numeric units | 2 |
| Missing/negative numeric price | 1 |
| Invalid discount | 0 |
| Invalid parsed date | 0 |
| Unmatched hub | 1 |
| **Eligible Fulfilled transactions** | **94** |

The exclusion reasons above do not overlap: **112 − 14 − 2 − 1 − 0 − 0 − 1 = 94**. The left merge preserves all 112 deduplicated rows: 111 matched, one unmatched. The comparable inner merge has 111 rows, silently omitting the unmatched transaction if used without an audit. Lookup keys are exactly three unique nonmissing values, and the validated many-to-one left merge did not inflate row count. The eligible table has 94 unique business IDs; the carryover does not survive twice.

## Confirmed eligible value

| Hub | Transactions | Net order value (USD) |
| --- | ---: | ---: |
| Central Hub | 38 | 4,247.66 |
| East Hub | 29 | 3,674.36 |
| West Hub | 27 | 2,552.37 |
| **Total** | **94** | **10,474.39** |

| Hub | Category | Transactions | Net order value (USD) |
| --- | --- | ---: | ---: |
| Central Hub | Electronics | 9 | 2,232.95 |
| Central Hub | Essentials | 18 | 993.49 |
| Central Hub | Home | 11 | 1,021.22 |
| East Hub | Electronics | 9 | 2,146.16 |
| East Hub | Essentials | 12 | 398.00 |
| East Hub | Home | 8 | 1,130.20 |
| West Hub | Electronics | 4 | 1,044.60 |
| West Hub | Essentials | 11 | 470.42 |
| West Hub | Home | 12 | 1,037.35 |
| **Total** | | **94** | **10,474.39** |

The row-level sum, hub group sum, and nine hub/category group sums all reconcile to **USD 10,474.39**. An independent `Decimal` computation from the saved CSV field values gave the same value. Eligible transaction values range from **USD 6.80 to USD 599.20**, have median **USD 73.60**, and contain **75 distinct values**; the three-hub comparison and value distribution are nondegenerate. These are descriptive results for fictional records, with no causal or population-wide claim.

## Reproduction, source check, and compatibility

- `sessions/S12/work/transaction_pack/generate_transactions.py` uses Python's standard library, deterministic seed `120926`, eight legitimate rows per day, fixed price menus by category, and explicit quality-case edits. It regenerates the two CSVs without changing their values. `create_hub_lookup.mjs` recreates the three-row workbook with the bundled `@oai/artifact-tool`. The saved native files, not these builders, are the learner inputs. `validate_pack.py` is the repeatable read-back audit; its detailed machine-readable results are in `work/transaction_pack/validation_report.json`.
- On **17 October 2026**, the [official Shopify order-export field description](https://help.shopify.com/en/manual/fulfillment/managing-orders/exporting-orders) was checked for a real operational pattern of IDs/dates, fulfillment state, line-item quantity and price, and discounts. This pack is **not** a Shopify export: real exports can have several lines per order and many payment, tax, shipping, and customer fields. The selected values and price bands (Essentials USD 6.80–27.20, Home USD 28.40–96.80, Electronics USD 89.60–299.60) were newly chosen as plausible teaching examples, not copied, sampled, or empirically sourced from a retailer.
- On the same date, [pandas `read_csv` documentation](https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html) and [pandas `read_excel` documentation](https://pandas.pydata.org/docs/reference/api/pandas.read_excel.html) were checked for CSV missing-value behavior and `.xlsx` reader support. The actual saved files were read and audited with **pandas 3.0.1** and **openpyxl 3.1.5**. The workbook was also rendered and visually inspected; it has one visible sheet and the `.xlsx` archive contains no macro project or external-link parts. A native Microsoft Excel GUI and a live Colab runtime were not exercised. Local Jupyter/Colab use requires the files in the notebook's working directory (or adjusted paths) and an installed `.xlsx` reader such as `openpyxl`.

### Saved-file SHA-256 identifiers

| File | SHA-256 |
| --- | --- |
| `S12_Transactions_Week1.csv` | `7a6f5b9b58be153cc23e7c961613548ecfbbb362fb2ea2b0cc035ec8925a253b` |
| `S12_Transactions_Week2.csv` | `655a1cf7af79e4ad9b9580536aed9d600468ca6b0a0fe782c1b7fd42da7984fa` |
| `S12_Hub_Reference.xlsx` | `086565b5507558d63d3826e51a3c6fa2a45378290539399fcfafd65adbb3f827` |
