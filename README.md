# README for `parserIOMeter.ps1`

## Overview

The `parserIOMeter.ps1` script is designed to parse CSV files generated by IOMeter benchmarking tests. The script extracts key test data, including test type, description, timestamp, and access specifications. It processes multiple CSV files located in a specified directory, organizes the extracted data into structured objects, and outputs the results in JSON format.

## Features

- **Reads CSV Files**: Processes CSV files from a specified directory based on a pattern.
- **Extracts Benchmark Data**: Extracts essential test data, including test type, description, timestamp, and access specifications.
- **Configurable Data Inclusion**: Provides options to include or exclude processor and worker data from the parsed results.
- **Structured Output**: Outputs the processed data in a structured JSON format for easy integration with other tools or systems.
- **Error Handling**: Handles missing files gracefully and provides user feedback.

## Parameters

### `-csvDirectory` (Mandatory)
Specifies the directory containing the CSV files to be parsed. The path should point to the location where the IOMeter CSV files are stored.

### `-csvPattern` (Mandatory)
Defines the pattern used to filter the CSV files (e.g., `"iometer_HDD_D_NTFS_Custom_OLTP.csv"`, `"*.csv"`, `"toto*.csv"`). Only the files that match the pattern will be processed.

### `-outputJsonPath` (Mandatory)
Specifies the full file path where the structured results will be saved in JSON format. The JSON file will contain all the extracted data.

### `-notIncludeProcessors` (Optional)
A Boolean flag indicating whether to exclude processor-related data from the results. If this parameter is provided, processor data will be skipped during parsing. By default, processor data is included.

### `-notIncludeWorkers` (Optional)
A Boolean flag indicating whether to exclude worker-related data from the results. If this parameter is provided, worker data will be skipped during parsing. By default, worker data is included.

## Usage Examples

### Example 1: Parse a specific CSV file
```powershell
PS D:\pacollet\Benchmark> .\parserIOMeter.ps1 -csvDirectory "D:\pacollet\Benchmark" -csvPattern "iometer_HDD_D_NTFS_Custom_OLTP.csv" -outputJsonPath "D:\pacollet\Benchmark\output_benchmark.json"
```
This will extract the data from the `iometer_HDD_D_NTFS_Custom_OLTP.csv` file and save the structured data in the `output_benchmark.json` file.


### Example 2: Parse all CSV files in a directory
```powershell
PS D:\pacollet\Benchmark> .\parserIOMeter.ps1 -csvDirectory "D:\pacollet\Benchmark" -csvPattern "*.csv" -outputJsonPath "D:\pacolle\Benchmark\output_benchmark.json"
```
This will extract data from all CSV files in the directory `D:\pacollet\Benchmark`.

### Example 3: Exclude processors and workers data

```powershell
PS D:\pacollet\Benchmark> .\parserIOMeter.ps1 -csvDirectory "D:\pacollet\Benchmark" -csvPattern "iometer_HDD_D_NTFS_Custom_OLTP.csv" -outputJsonPath "D:\pacollet\Benchmark\output_benchmark.json" -notIncludeProcessors -notIncludeWorkers
```
This will parse the `iometer_HDD_D_NTFS_Custom_OLTP.csv` file but exclude processor and worker data from the results.

### Script Workflow

1. **Get CSV Files**: The script first fetches all the CSV files from the specified directory that match the given pattern.

2. **Process Each CSV File**: It reads each CSV file, extracts key benchmark test data, including test type, description, timestamp, and access specifications.

3. **Organize Data**: The extracted data is stored in structured objects (arrays and hash tables).

4. **Output JSON**: The structured data is then converted into JSON format and saved to the specified output file.

### Notes

- The script can handle multiple CSV files in parallel as long as they match the pattern specified.
- The output JSON file will contain all the extracted data from all processed CSV files.
- This script is intended for use with IOMeter CSV files that follow a specific structure. Ensure your files conform to the expected format for correct parsing.

### License

This script is licensed under the MIT License.

```csharp
Copyright (c) 2025 by Pierre-Antoine Collet  
Licensed under MIT License - https://opensource.org/licenses/MIT
```

### Contact
For more information or if you have any questions, feel free to contact the author, Pierre-Antoine Collet.
