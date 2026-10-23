from pathlib import Path
import csv
import gzip
import shutil

# Save this script inside your project's python folder.
project_folder = Path(__file__).resolve().parent.parent
YEAR = 2019
ROW_LIMIT = None # After checking the preview, change 5 to None.
data_folder = project_folder / f"sample_{YEAR}"
# Expanded files are separate from your original prepared_data files.
output_folder = project_folder / "prepared_data_v2"
output_folder.mkdir(exist_ok=True)

# Positions are from Freddie Mac's July 2026 layout (one-based).
origination_columns = {
    "loan_id": 20,
    "credit_score": 1,
    "first_payment_month": 2,
    "original_dti": 10,
    "original_balance": 11,
    "original_ltv": 12,
    "loan_purpose": 21,
    "original_interest_rate": 13,
    "original_loan_term": 22,
    "occupancy_status": 8,
    "property_state": 17,
    "channel": 14,
    "first_time_homebuyer": 3,
    "number_of_borrowers": 23,
    "original_cltv": 9,
    "mortgage_insurance_pct": 6,
    "maturity_month": 4,
}

performance_columns = {
    "loan_id": 1,
    "reporting_month": 2,
    "current_balance": 3,
    "delinquency_status": 4,
    "loan_age": 5,
    "zero_balance_code": 9,
    "zero_balance_month": 10,
    "current_interest_rate": 11,
    "modification_flag": 8,
    "borrower_assistance_plan": 30,
    "delinquency_due_to_disaster": 29,
    "payment_deferral_flag": 25,
    "remaining_months_to_maturity": 6,
    "defect_settlement_month": 7,
    "current_non_interest_bearing_balance": 12,
    "last_paid_installment_month": 13,
    "mi_recoveries": 14,
    "net_sales_proceeds": 15,
    "non_mi_recoveries": 16,
    "total_expenses": 17,
    "legal_costs": 18,
    "maintenance_preservation_costs": 19,
    "taxes_insurance": 20,
    "miscellaneous_expenses": 21,
    "actual_loss": 22,
    "cumulative_modification_costs": 23,
    "zero_balance_removal_balance": 27,
    "delinquent_accrued_interest": 28,
    "current_period_modification_costs": 31,
    "current_interest_bearing_balance": 32,
    "bankruptcy_cramdown_costs": 35,
}


def prepare_file(input_name, output_name, columns, expected_fields, limit=None):
    input_path = data_folder / input_name
    output_path = output_folder / output_name
    # Write to a temporary file; promote it only after successful processing.
    temporary_path = output_path.with_suffix(".csv.partial")
    rows_written = 0

    try:
        with input_path.open(encoding="utf-8", newline="") as source:
            with temporary_path.open("w", encoding="utf-8", newline="") as destination:
                reader = csv.reader(source, delimiter="|")
                writer = csv.writer(destination)
                writer.writerow(columns.keys())

                for row_number, fields in enumerate(reader, start=1):
                    if len(fields) != expected_fields:
                        raise ValueError(
                            f"{input_name}, row {row_number}: "
                            f"expected {expected_fields} fields, got {len(fields)}"
                        )
                    # Preserve raw strings, blanks and special codes for SQL cleaning.
                    selected_values = [
                        fields[position - 1] for position in columns.values()
                    ]
                    writer.writerow(selected_values)
                    rows_written += 1
                    if limit is not None and rows_written >= limit:
                        break
        temporary_path.replace(output_path)
    except Exception:
        temporary_path.unlink(missing_ok=True)
        raise

    print(f"{output_name}: {rows_written:,} data rows; {len(columns)} columns")
    print(f"Saved to: {output_path}")
    return output_path


def compress_file(csv_path):
    gzip_path = csv_path.with_suffix(".csv.gz")
    with csv_path.open("rb") as source:
        with gzip.open(gzip_path, "wb") as destination:
            shutil.copyfileobj(source, destination)
    print(f"{gzip_path.name}: {gzip_path.stat().st_size / 1_000_000:.2f} MB")


if __name__ == "__main__":
    print("PREVIEW RUN" if ROW_LIMIT is not None else "FULL RUN")
    origination_path = prepare_file(
        f"sample_orig_{YEAR}.txt", f"origination_{YEAR}_v2.csv",
        origination_columns, expected_fields=31, limit=ROW_LIMIT,
    )
    performance_path = prepare_file(
        f"sample_perf_{YEAR}.txt", f"performance_{YEAR}_v2.csv",
        performance_columns, expected_fields=35, limit=ROW_LIMIT,
    )
    # Compress both outputs; keep their uncompressed CSV copies as well.
    compress_file(origination_path)
    compress_file(performance_path)