from pathlib import Path
#reads the path
from itertools import islice
#is able to slice some of the data into rows

project_folder = Path(__file__).resolve().parent.parent
data_folder = project_folder / "sample_2017"

for filename in ["sample_orig_2017.txt", "sample_perf_2017.txt"]:
    file_path = data_folder / filename
    print(f"\nFile: {filename}")

    with file_path.open(encoding="utf-8") as file:
        for row_number, line in enumerate(islice(file, 5), start=1):
            fields = line.rstrip("\r\n").split("|")
            print(f"Row {row_number}: {len(fields)} columns")
            print("First five values:", fields[:5])