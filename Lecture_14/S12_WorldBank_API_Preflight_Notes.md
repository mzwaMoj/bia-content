# S12 World Bank population API preflight and snapshot

Internal source and reproduction note. The companion `S12_WorldBank_Population_Snapshot.json` is the **unmodified response body** of the live request below. It is an explicitly dated offline fallback; loading it later is not evidence that a classroom HTTP call succeeded.

## Live retrieval evidence

| Item | Observed result |
| --- | --- |
| Method and client | One Python `requests.get` GET, with `(10, 25)` second connect/read timeouts; no API key or credentials. |
| Endpoint | `https://api.worldbank.org/v2/country/IND/indicator/SP.POP.TOTL` |
| Parameters | `format=json`, `date=2014:2023`, `per_page=50` |
| Fully resolved request URL | `https://api.worldbank.org/v2/country/IND/indicator/SP.POP.TOTL?format=json&date=2014%3A2023&per_page=50` |
| UTC request started and completed | 2026-10-17 09:11:02 UTC; 2026-10-17 09:11:02 UTC (second-level timestamps). |
| HTTP and decoding | HTTP **200**; `Content-Type: application/json;charset=utf-8`; `raise_for_status()` passed; `response.json()` decoded successfully and passed semantic checks. |
| Saved source body | 2,051 bytes; written directly from `response.content`, with no flattening, reordered observations, added wrapper, edited values or rounding. |
| World Bank response update field | `lastupdated: 2026-10-08` in response metadata. This is source metadata, distinct from the 17 October capture date. |

This GET was actually completed by the producing Python environment. The [World Bank Indicators API documentation](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392) also states that API keys and authentication are unnecessary. The [basic call documentation](https://datahelpdesk.worldbank.org/knowledgebase/articles/898581-api-basic-call-structures) documents JSON format, date ranges and pagination.

## Response and saved-file checks

The decoded top level is a two-element JSON array: a metadata object and a list of **10 observation objects**. Metadata was `page=1`, `pages=1`, `per_page=50`, `total=10`, `sourceid="2"`, and `lastupdated="2026-10-08"`. Thus one page contains the complete requested set; metadata was not counted as an observation. The observations contain `indicator`, `country`, `countryiso3code`, `date`, `value`, `unit`, `obs_status`, and `decimal`. Their `unit` strings are empty, so the persons label is drawn from the indicator's population-count meaning and metadata, not from a populated per-record unit field. Source name is **not** present in each observation; the response carries source ID `2`, which the [official indicator metadata](https://api.worldbank.org/v2/indicator/SP.POP.TOTL?format=json) identifies as World Development Indicators.

All ten years **2014–2023** appear once, with no missing, extra or duplicate years. Each `value` is a positive integer, with **zero null or unusable values**. Every observation has country `IN` / `IND` / `India` and indicator `SP.POP.TOTL` / `Population, total`. The response is ordered newest first; the year/persons table below was derived by numeric conversion and chronological sorting, without changing the raw snapshot:

| Year | Population (persons) |
| ---: | ---: |
| 2014 | 1,312,277,191 |
| 2015 | 1,328,024,498 |
| 2016 | 1,343,944,296 |
| 2017 | 1,359,657,400 |
| 2018 | 1,374,659,064 |
| 2019 | 1,389,030,312 |
| 2020 | 1,402,617,695 |
| 2021 | 1,414,203,896 |
| 2022 | 1,425,423,212 |
| 2023 | 1,438,069,596 |

The saved file was reopened from disk with `json.load()` immediately after capture and its parsed structure and validation summary matched the live response. It was then validated again in a **separate offline process**, with no HTTP request and without importing `requests`; it produced the same ten-row pandas year/population table. The saved-file SHA-256 is:

`3f499e74096a5a3d3c54c1f40bbd9e5d06833033075aeb90fa4427eb0757a6cd`

The numeric, unique chronological year/persons table supports a truthful line chart titled and labelled for India, 2014–2023, population in persons. A Matplotlib rendering was **not** executed in this environment because Matplotlib was absent; table extraction and numeric/chart-input validation were executed. The chart should be descriptive only: it cannot establish causes of population change.

## Provenance, reuse and attribution

The [World Bank World Development Indicators metadata for `SP.POP.TOTL`](https://databank.worldbank.org/metadataglossary/world-development-indicators/series/SP.POP.TOTL) identifies the dataset as `WB_WDI`, describes the series as **de facto midyear population estimates**, gives annual periodicity, and lists underlying providers including the UN Population Division's *World Population Prospects*, national statistical offices, Eurostat and the UN Statistics Division. The API indicator metadata confirms source `2` is World Development Indicators. The series is measured as a count of **persons** (the metadata's generic “Unit” label is not a populated API `unit` string). Population estimates and earlier-year values can be revised; the snapshot fixes only what the API returned at its retrieval time.

The [indicator-specific World Bank metadata](https://databank.worldbank.org/metadataglossary/world-development-indicators/series/SP.POP.TOTL) labels this series **CC BY 4.0**. The [World Bank dataset terms](https://www.worldbank.org/ext/en/legal/terms-conditions/datasets) allow copying and sharing with attribution but warn that some third-party indicators have different terms; this indicator's explicit license label resolves that exception for the cited series. Educational distribution of this captured JSON is supported with attribution, license identification and the source/terms links; do not imply World Bank endorsement.

Suggested learner chart/source credit: **Source: The World Bank, World Development Indicators, “Population, total” (`SP.POP.TOTL`), India, 2014–2023; underlying providers listed in [indicator metadata](https://databank.worldbank.org/metadataglossary/world-development-indicators/series/SP.POP.TOTL). Retrieved 17 October 2026, 09:11 UTC. [CC BY 4.0 / World Bank dataset terms](https://www.worldbank.org/ext/en/legal/terms-conditions/datasets).** This credits the World Bank dataset and points to provider detail without attributing each India observation to one unverified provider.

## Reproduction and classroom fallback

- The supplied `S12_WorldBank_API_Preflight.py` was exercised with **Python 3.12.14**, **requests 2.34.2**, and **pandas 3.0.1**. It performs exactly one GET in `--mode live`, separately checks HTTP status, JSON decoding, pagination, year/identity/value completeness, and prints diagnostics. A failure exits visibly; it never silently opens the offline file. Run `python S12_WorldBank_API_Preflight.py --mode live` shortly before class. `--save-snapshot` explicitly writes a new capture only after a passing live check; avoid using it when preserving this dated file.
- For offline verification, place the script and snapshot together and run `python S12_WorldBank_API_Preflight.py --mode offline`. This makes **no HTTP request**. The JSON itself also works with ordinary `json.load(open("S12_WorldBank_Population_Snapshot.json", encoding="utf-8"))`; the observation list is element `[1]`. In local Jupyter/JupyterLab or Colab, keep the snapshot beside the notebook or adjust the relative path. Colab's temporary runtime requires re-upload after reset. The offline path needs no login, key or network once the file is local.
- The tested Python environment initially lacked `requests`; the dependency was installed into a temporary work directory for the live run. A later runtime must have `requests` and `pandas` for the helper, plus Matplotlib for the later chart. The snapshot alone needs only Python's standard `json` module. The completed API call had no DNS, timeout, HTTP, decoding, pagination or missing-observation failure. Later network failure should be shown first, followed by a separately labelled offline choice.

Do not join these national observations to the separate fictional retailer transaction files. If the live API later returns revised values, keep live and dated-snapshot results clearly distinguished.
