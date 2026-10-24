"""Check the fixed S12 World Bank population query or its saved JSON response.

Live:    python S12_WorldBank_API_Preflight.py --mode live
Save:    python S12_WorldBank_API_Preflight.py --mode live --save-snapshot
Offline: python S12_WorldBank_API_Preflight.py --mode offline

The live mode makes one HTTP GET, reports failures, and never silently uses the
offline file. Saving is explicit; a successful validation is required first.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd


ENDPOINT = "https://api.worldbank.org/v2/country/IND/indicator/SP.POP.TOTL"
PARAMS = {"format": "json", "date": "2014:2023", "per_page": 50}
SNAPSHOT = Path(__file__).with_name("S12_WorldBank_Population_Snapshot.json")
YEARS = set(range(2014, 2024))


def validate_payload(payload: object) -> tuple[dict, pd.DataFrame, dict]:
    if not isinstance(payload, list) or len(payload) != 2:
        raise ValueError("Expected a two-element JSON array: metadata, observations")
    metadata, observations = payload
    if not isinstance(metadata, dict) or not isinstance(observations, list):
        raise ValueError("Expected metadata object followed by observation array")
    for field in ("page", "pages", "per_page", "total"):
        if field not in metadata:
            raise ValueError(f"Missing pagination field: {field}")
    if metadata["page"] != 1 or metadata["pages"] != 1:
        raise ValueError(f"Incomplete pagination: {metadata}")
    if metadata.get("sourceid") != "2":
        raise ValueError(f"Unexpected source ID: {metadata.get('sourceid')}")
    if int(metadata["total"]) != len(observations):
        raise ValueError("Metadata total differs from returned observation count")
    if int(metadata["per_page"]) < len(observations):
        raise ValueError("Reported per_page is smaller than returned observation count")
    if len(observations) != 10 or not all(isinstance(row, dict) for row in observations):
        raise ValueError("Expected exactly ten annual observation dictionaries")

    years = []
    for row in observations:
        if not isinstance(row.get("date"), str) or not row["date"].isdigit():
            raise ValueError("Observation year is missing or not numeric year text")
        year = int(row["date"])
        years.append(year)
        if not isinstance(row.get("value"), (int, float)) or isinstance(row["value"], bool):
            raise ValueError(f"Missing or nonnumeric population in {year}")
        if row["value"] <= 0:
            raise ValueError(f"Nonpositive population in {year}")
        if row.get("countryiso3code") != "IND":
            raise ValueError(f"Unexpected ISO3 country in {year}")
        country = row.get("country")
        indicator = row.get("indicator")
        if not isinstance(country, dict) or country.get("id") != "IN":
            raise ValueError(f"Unexpected country object in {year}")
        if not isinstance(indicator, dict) or indicator.get("id") != "SP.POP.TOTL":
            raise ValueError(f"Unexpected indicator object in {year}")
    if set(years) != YEARS or any(count != 1 for count in Counter(years).values()):
        raise ValueError(f"Missing, extra, or repeated years: {sorted(years)}")

    table = pd.DataFrame(
        {"year": int(row["date"]), "population": row["value"]}
        for row in observations
    ).sort_values("year", ignore_index=True)
    if table.population.isna().any() or not pd.api.types.is_numeric_dtype(table.population):
        raise ValueError("Population column cannot support a numeric line chart")
    if table.year.tolist() != list(range(2014, 2024)):
        raise ValueError("Chronological year table is incomplete")
    summary = {
        "top_level": "list[metadata object, observation list]",
        "metadata": metadata,
        "observation_count": len(observations),
        "observation_fields": sorted(set().union(*(row.keys() for row in observations))),
        "years": sorted(years),
        "duplicate_years": [year for year, count in Counter(years).items() if count > 1],
        "null_values": sum(row["value"] is None for row in observations),
        "country_ids": sorted({row["country"]["id"] for row in observations}),
        "country_names": sorted({row["country"].get("value") for row in observations}),
        "country_iso3_codes": sorted({row["countryiso3code"] for row in observations}),
        "indicator_ids": sorted({row["indicator"]["id"] for row in observations}),
        "indicator_names": sorted({row["indicator"].get("value") for row in observations}),
        "response_source_id": metadata["sourceid"],
        "source_named_in_observation_records": any("source" in row for row in observations),
        "year_population": table.to_dict(orient="records"),
    }
    return metadata, table, summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=["live", "offline"], required=True)
    parser.add_argument("--save-snapshot", action="store_true")
    parser.add_argument("--report", type=Path, help="Optional path for compact JSON diagnostics")
    args = parser.parse_args()
    if args.mode == "offline" and args.save_snapshot:
        parser.error("--save-snapshot is only valid in live mode")

    report = {"mode": args.mode, "python": sys.version.split()[0], "pandas": pd.__version__}
    if args.mode == "live":
        import requests

        report["requests"] = requests.__version__
        started_utc = datetime.now(timezone.utc).isoformat(timespec="seconds")
        try:
            response = requests.get(ENDPOINT, params=PARAMS, timeout=(10, 25))
        except requests.exceptions.RequestException as exc:
            raise RuntimeError(f"Live World Bank GET failed: {exc}") from exc
        completed_utc = datetime.now(timezone.utc).isoformat(timespec="seconds")
        report.update({
            "started_utc": started_utc,
            "completed_utc": completed_utc,
            "url": response.url,
            "status_code": response.status_code,
            "content_type": response.headers.get("Content-Type"),
            "response_bytes": len(response.content),
        })
        try:
            response.raise_for_status()
        except requests.exceptions.HTTPError as exc:
            raise RuntimeError(
                f"Live World Bank GET returned HTTP {response.status_code}: {response.url}"
            ) from exc
        try:
            payload = response.json()
        except requests.exceptions.JSONDecodeError as exc:
            raise ValueError("HTTP succeeded but the response was not valid JSON") from exc
        _, _, summary = validate_payload(payload)
        report["validation"] = summary
        if args.save_snapshot:
            # Keep the response body itself. No flattening, rounding, or metadata wrapper.
            SNAPSHOT.write_bytes(response.content)
            report["snapshot_path"] = str(SNAPSHOT)
            report["snapshot_sha256"] = hashlib.sha256(SNAPSHOT.read_bytes()).hexdigest()
            with SNAPSHOT.open("r", encoding="utf-8") as stream:
                saved_payload = json.load(stream)
            _, _, saved_summary = validate_payload(saved_payload)
            if saved_payload != payload or saved_summary != summary:
                raise ValueError("Saved JSON differs from the validated live response")
            report["saved_file_reopened_and_validated"] = True
    else:
        with SNAPSHOT.open("r", encoding="utf-8") as stream:
            payload = json.load(stream)
        _, _, report["validation"] = validate_payload(payload)
        report["snapshot_path"] = str(SNAPSHOT)
        report["snapshot_sha256"] = hashlib.sha256(SNAPSHOT.read_bytes()).hexdigest()
        report["http_request_made"] = False

    text = json.dumps(report, indent=2, ensure_ascii=False)
    print(text)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(text + "\n", encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError) as exc:
        print(f"Preflight failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
