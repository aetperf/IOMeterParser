 <#
    .SYNOPSIS
        Parse CSV files from IOMeter containing benchmark test data and extract access specifications.
    .DESCRIPTION
        Objective: The script processes multiple CSV files located in a specified directory. 
        It reads each file, extracts benchmark test data, and specifically retrieves access specifications from the CSV content. 
        The script then organizes the extracted data into structured objects and outputs the results in a JSON format.

        The script will:
        - Read CSV files from a directory based on a specified pattern.
        - Extract test type, description, timestamp, and access specifications from each file.
        - Structure the extracted data for further use or output.
        
        The output data will be stored in a JSON file at the specified location.
       
    .PARAMETER csvDirectory
        The directory containing the CSV files to be parsed.

    .PARAMETER csvPattern
        The pattern used to filter the CSV files (e.g., "iometer_HDD_D_NTFS_Custom_OLTP.csv" ,"*.csv" ,"toto*.csv").

    .PARAMETER outputJsonPath
        The file path where the structured results in JSON format will be saved.

    .PARAMETER notIncludeProcessors
        A Boolean flag that indicates whether processors should be excluded from the test.
        If this parameter is set, the script will skip any processor-related data processing.
        If not provided, the default behavior will be to include processor data.

    .PARAMETER notIncludeWorkers
        A Boolean flag that indicates whether workers should be excluded from the test.
        If this parameter is set, the script will skip any worker-related data processing.
        If not provided, the default behavior will be to include worker data.

    .NOTES
        Tags: Benchmark, IOMeter
        Author: Pierre-Antoine Collet
        Website: 
        Copyright: (c) 2025 by Pierre-Antoine Collet, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT
        

    .LINK
        
    .EXAMPLE
        PS D:\pacollet\Client\Edilians\Benchmark> .\parserIOMeter.ps1 -csvDirectory "D:\pacollet\\Benchmark" -csvPattern "iometer_HDD_D_NTFS_Custom_OLTP.csv" -outputJsonPath "D:\pacollet\Client\Benchmark\output_benchmark.json"
        This will extract the data of the iometer_HDD_D_NTFS_Custom_OLTP.csv file 
    
    .EXAMPLE
        PS D:\pacollet\Client\Edilians\Benchmark> .\parserIOMeter.ps1 -csvDirectory "D:\pacollet\Benchmark" -csvPattern "*.csv" -outputJsonPath "D:\pacollet\Benchmark\output_benchmark.json"
        This will extract the data of all the csv file located in the directory D:\pacollet\Benchmark

    .EXAMPLE
        PS D:\pacollet\Client\Edilians\Benchmark> .\parserIOMeter.ps1 -csvDirectory "D:\pacollet\Benchmark" -csvPattern "iometer_HDD_D_NTFS_Custom_OLTP.csv" -outputJsonPath "D:\pacollet\Benchmark\output_benchmark.json" -notIncludeProcessors -notIncludeWorkers
        This will not extract the processors data and workers data
    #>

param (
    [Parameter(Mandatory=$true)] [string]$csvDirectory,  
    [Parameter(Mandatory=$true)] [string]$csvPattern,  
    [Parameter(Mandatory=$true)] [string]$outputJsonPath,
    [Parameter(Mandatory=$false)] [switch]$notIncludeProcessors,
    [Parameter(Mandatory=$false)] [switch]$notIncludeWorkers
)

#############################################################################################
## GET ALL THE CSV FILE MATCHING THE PATTERN
#############################################################################################
$csvFiles = Get-ChildItem -Path $csvDirectory -Filter $csvPattern

# Initialiser une liste pour stocker les résultats de tous les fichiers CSV
$outputJsonData = @()

# Traiter chaque fichier CSV
foreach ($csvFile in $csvFiles) {
    # Chemin vers le fichier CSV actuel
    $csvFilePath = $csvFile.FullName

    write-host $csvFile.Name

    # Check if the file exists
    if (Test-Path $csvFilePath) {
        # Read the contet of the csv file
        $lines = Get-Content -Path $csvFilePath

        # Initialize a dictionary to store test data
        $testData = @{
            'File Name' = $csvFile.Name  
            'Test Type' = $null
            'Test Description' = $null
            'Time Stamp' = $null
            'Access Specifications' = @()
        }
        

        # Initialize an array to store test access specifications
        $testAccessSpecs = @()
        # Initialize an array to store all test results
        $testResultAlls = @()
        # Initialize an array to store test results for managers
        $testResultManagers = @()
        # Initialize an array to store test results for processors
        $testResultProcessors = @()
        # Initialize an array to store test results for workers
        $testResultWorkers = @()
        
        $inAccessSpecs = $false
        $index = 0

        foreach ($line in $lines) {
            $line = $line.Trim()

#############################################################################################
## PARSING : Get test informations and access specifications
#############################################################################################
            # Check if the line is a test line
            if ($line -match "^'(Test Type),(Test Description)$") {
                if ($lines[$index + 1].Trim() -match "(\d+),(.+)") {
                    $testData['Test Type'] = $matches[1]
                    $testData['Test Description'] = $matches[2]
                }
            }

            # Check if we have found the timestamp
            elseif ($line -match "^'Time Stamp$") {
                $testData['Time Stamp'] = $lines[$lines.IndexOf($line) + 1].Trim()
            }

            # Check if we have found the 'Access specifications' section
            elseif ($line -match "^'Access specifications$") {
                $inAccessSpecs = $true
            }

            # Check if we have reached the end of the 'Access specifications' section
            elseif ($line -match "^'End access specifications$") {
                $inAccessSpecs = $false
            }


            if ($inAccessSpecs -and $line -match "^(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),$") {
                $accessSpec = @{
                    'Access specification name' = $accessSpecName
                    'default assignment' = $defaultAssign
                    'size' = [int]$matches[1]
                    'percent of size' = [int]$matches[2]
                    'percent reads' = [int]$matches[3]
                    'percent random' = [int]$matches[4]
                    'delay' = [int]$matches[5]
                    'burst' = [int]$matches[6]
                    'align' = [int]$matches[7]
                    'reply' = [int]$matches[8]
                }
                $testAccessSpecs += $accessSpec
            }

#############################################################################################
## PARSING : Get data for ALL
#############################################################################################

            if ($line -match "^ALL,(([^,]*),)*([^,]*)$") {
                $values = $lines[$index].Trim() -split ","
                
                $testResultAll = @{
                    'Target Type' = $values[0]
                    'Target Name' = $values[1]
                    'Access Specification Name' = $values[2]
                    '# Managers' = if ($values[3] -ne "") { [int]$values[3] } else { $null }  
                    '# Workers' = if ($values[4] -ne "") { [int]$values[4] } else { $null }
                    '# Disks' = if ($values[5] -ne "") { [int]$values[5] } else { $null }
                    'IOps' = [float]$values[6]
                    'Read IOps' = [float]$values[7]
                    'Write IOps' = [float]$values[8]
                    'MiBps (Binary)' = [float]$values[9]
                    'Read MiBps (Binary)' = [float]$values[10]
                    'Write MiBps (Binary)' = [float]$values[11]
                    'MBps (Decimal)' = [float]$values[12]
                    'Read MBps (Decimal)' = [float]$values[13]
                    'Write MBps (Decimal)' = [float]$values[14]
                    'Transactions per Second' = [float]$values[15]
                    'Connections per Second' = [float]$values[16]
                    'Average Response Time' = [float]$values[17]
                    'Average Read Response Time' = [float]$values[18]
                    'Average Write Response Time' = [float]$values[19]
                    'Average Transaction Time' = [float]$values[20]
                    'Average Connection Time' = [float]$values[21]
                    'Maximum Response Time' = [float]$values[22]
                    'Maximum Read Response Time' = [float]$values[23]
                    'Maximum Write Response Time' = [float]$values[24]
                    'Maximum Transaction Time' = [float]$values[25]
                    'Maximum Connection Time' = [float]$values[26]
                    'Errors' = [int]$values[27]
                    'Read Errors' = [int]$values[28]
                    'Write Errors' = [int]$values[29]
                    'Bytes Read' = [int64]$values[30]
                    'Bytes Written' = [int64]$values[31]
                    'Read I/Os' = [int]$values[32]
                    'Write I/Os' = [int]$values[33]
                    'Connections' = [int]$values[34]
                    'Transactions per Connection' = [float]$values[35]
                    'Total Raw Read Response Time' = [int64]$values[36]
                    'Total Raw Write Response Time' = [int64]$values[37]
                    'Total Raw Transaction Time' = [int64]$values[38]
                    'Total Raw Connection Time' = [int64]$values[39]
                    'Maximum Raw Read Response Time' = [int64]$values[40]
                    'Maximum Raw Write Response Time' = [int64]$values[41]
                    'Maximum Raw Transaction Time' = [int64]$values[42]
                    'Maximum Raw Connection Time' = [int64]$values[43]
                    'Total Raw Run Time' = [int64]$values[44]
                    'Starting Sector' = [int]$values[45]
                    'Maximum Size' = [int]$values[46]
                    'Queue Depth' = [int]$values[47]
                    '% CPU Utilization' = [float]$values[48]
                    '% User Time' = [float]$values[49]
                    '% Privileged Time' = [float]$values[50]
                    '% DPC Time' = [float]$values[51]
                    '% Interrupt Time' = [float]$values[52]
                    'Processor Speed' = [float]$values[53]
                    'Interrupts per Second' = [float]$values[54]
                    'CPU Effectiveness' = [float]$values[55]
                    'Packets/Second' = [float]$values[56]
                    'Packet Errors' = [float]$values[57]
                    'Segments Retransmitted/Second' = [float]$values[58]
                    '0 to 50 uS' = [int]$values[59]
                    '50 to 100 uS' = [int]$values[60]
                    '100 to 200 uS' = [int]$values[61]
                    '200 to 500 uS' = [int]$values[62]
                    '0.5 to 1 mS' = [int]$values[63]
                    '1 to 2 mS' = [int]$values[64]
                    '2 to 5 mS' = [int]$values[65]
                    '5 to 10 mS' = [int]$values[66]
                    '10 to 15 mS' = [int]$values[67]
                    '15 to 20 mS' = [int]$values[68]
                    '20 to 30 mS' = [int]$values[69]
                    '30 to 50 mS' = [int]$values[70]
                    '50 to 100 mS' = [int]$values[71]
                    '100 to 200 mS' = [int]$values[72]
                    '200 to 500 mS' = [int]$values[73]
                    '0.5 to 1 S' = [int]$values[74]
                    '1 to 2 s' = [int]$values[75]
                    '2 to 4.7 s' = [int]$values[76]
                    '4.7 to 5 s' = [int]$values[77]
                    '5 to 10 s' = [int]$values[78]
                    'more or equals than 10 s' = [int]$values[79]
                }
                
                $testResultAlls += $testResultAll
            }

#############################################################################################
## PARSING : Get data for Managers
#############################################################################################

            if ($line -match "^MANAGER,(([^,]*),)*([^,]*)$") {
                $values = $lines[$index].Trim() -split ","
                
                $testResultManager = @{
                    'Target Type' = $values[0]
                    'Target Name' = $values[1]
                    'Access Specification Name' = $values[2]
                    '# Managers' = if ($values[3] -ne "") { [int]$values[3] } else { $null }
                    '# Workers' = if ($values[4] -ne "") { [int]$values[4] } else { $null }
                    '# Disks' = if ($values[5] -ne "") { [int]$values[5] } else { $null }
                    'IOps' = [float]$values[6]
                    'Read IOps' = [float]$values[7]
                    'Write IOps' = [float]$values[8]
                    'MiBps (Binary)' = [float]$values[9]
                    'Read MiBps (Binary)' = [float]$values[10]
                    'Write MiBps (Binary)' = [float]$values[11]
                    'MBps (Decimal)' = [float]$values[12]
                    'Read MBps (Decimal)' = [float]$values[13]
                    'Write MBps (Decimal)' = [float]$values[14]
                    'Transactions per Second' = [float]$values[15]
                    'Connections per Second' = [float]$values[16]
                    'Average Response Time' = [float]$values[17]
                    'Average Read Response Time' = [float]$values[18]
                    'Average Write Response Time' = [float]$values[19]
                    'Average Transaction Time' = [float]$values[20]
                    'Average Connection Time' = [float]$values[21]
                    'Maximum Response Time' = [float]$values[22]
                    'Maximum Read Response Time' = [float]$values[23]
                    'Maximum Write Response Time' = [float]$values[24]
                    'Maximum Transaction Time' = [float]$values[25]
                    'Maximum Connection Time' = [float]$values[26]
                    'Errors' = [int]$values[27]
                    'Read Errors' = [int]$values[28]
                    'Write Errors' = [int]$values[29]
                    'Bytes Read' = [int64]$values[30]
                    'Bytes Written' = [int64]$values[31]
                    'Read I/Os' = [int]$values[32]
                    'Write I/Os' = [int]$values[33]
                    'Connections' = [int]$values[34]
                    'Transactions per Connection' = [float]$values[35]
                    'Total Raw Read Response Time' = [int64]$values[36]
                    'Total Raw Write Response Time' = [int64]$values[37]
                    'Total Raw Transaction Time' = [int64]$values[38]
                    'Total Raw Connection Time' = [int64]$values[39]
                    'Maximum Raw Read Response Time' = [int64]$values[40]
                    'Maximum Raw Write Response Time' = [int64]$values[41]
                    'Maximum Raw Transaction Time' = [int64]$values[42]
                    'Maximum Raw Connection Time' = [int64]$values[43]
                    'Total Raw Run Time' = [int64]$values[44]
                    'Starting Sector' = [int]$values[45]
                    'Maximum Size' = [int]$values[46]
                    'Queue Depth' = [int]$values[47]
                    '% CPU Utilization' = [float]$values[48]
                    '% User Time' = [float]$values[49]
                    '% Privileged Time' = [float]$values[50]
                    '% DPC Time' = [float]$values[51]
                    '% Interrupt Time' = [float]$values[52]
                    'Processor Speed' = [float]$values[53]
                    'Interrupts per Second' = [float]$values[54]
                    'CPU Effectiveness' = [float]$values[55]
                    'Packets/Second' = [float]$values[56]
                    'Packet Errors' = [float]$values[57]
                    'Segments Retransmitted/Second' = [float]$values[58]
                    '0 to 50 uS' = [int]$values[59]
                    '50 to 100 uS' = [int]$values[60]
                    '100 to 200 uS' = [int]$values[61]
                    '200 to 500 uS' = [int]$values[62]
                    '0.5 to 1 mS' = [int]$values[63]
                    '1 to 2 mS' = [int]$values[64]
                    '2 to 5 mS' = [int]$values[65]
                    '5 to 10 mS' = [int]$values[66]
                    '10 to 15 mS' = [int]$values[67]
                    '15 to 20 mS' = [int]$values[68]
                    '20 to 30 mS' = [int]$values[69]
                    '30 to 50 mS' = [int]$values[70]
                    '50 to 100 mS' = [int]$values[71]
                    '100 to 200 mS' = [int]$values[72]
                    '200 to 500 mS' = [int]$values[73]
                    '0.5 to 1 S' = [int]$values[74]
                    '1 to 2 s' = [int]$values[75]
                    '2 to 4.7 s' = [int]$values[76]
                    '4.7 to 5 s' = [int]$values[77]
                    '5 to 10 s' = [int]$values[78]
                    'more or equals than 10 s' = [int]$values[79]
                }
                
                $testResultManagers += $testResultManager

            }

#############################################################################################
## PARSING : Get data for Processors
#############################################################################################
            if (!$notIncludeProcessors -and $line -match "^PROCESSOR,(([^,]*),)*([^,]*)$") {
                $values = $lines[$index].Trim() -split ","
                
                $testResultProcessor = @{
                    'Target Type' = $values[0]
                    'Target Name' = $values[1]
                    'Access Specification Name' =if ($values[2] -ne "") { [int]$values[3] } else { $null }
                    '# Managers' = if ($values[3] -ne "") { [int]$values[3] } else { $null }  # Si vide, mettre à $null
                    '# Workers' = if ($values[4] -ne "") { [int]$values[4] } else { $null }
                    '# Disks' = if ($values[5] -ne "") { [int]$values[5] } else { $null }
                    'IOps' = [float]$values[6]
                    'Read IOps' = [float]$values[7]
                    'Write IOps' = [float]$values[8]
                    'MiBps (Binary)' = [float]$values[9]
                    'Read MiBps (Binary)' = [float]$values[10]
                    'Write MiBps (Binary)' = [float]$values[11]
                    'MBps (Decimal)' = [float]$values[12]
                    'Read MBps (Decimal)' = [float]$values[13]
                    'Write MBps (Decimal)' = [float]$values[14]
                    'Transactions per Second' = [float]$values[15]
                    'Connections per Second' = [float]$values[16]
                    'Average Response Time' = [float]$values[17]
                    'Average Read Response Time' = [float]$values[18]
                    'Average Write Response Time' = [float]$values[19]
                    'Average Transaction Time' = [float]$values[20]
                    'Average Connection Time' = [float]$values[21]
                    'Maximum Response Time' = [float]$values[22]
                    'Maximum Read Response Time' = [float]$values[23]
                    'Maximum Write Response Time' = [float]$values[24]
                    'Maximum Transaction Time' = [float]$values[25]
                    'Maximum Connection Time' = [float]$values[26]
                    'Errors' = [int]$values[27]
                    'Read Errors' = [int]$values[28]
                    'Write Errors' = [int]$values[29]
                    'Bytes Read' = [int64]$values[30]
                    'Bytes Written' = [int64]$values[31]
                    'Read I/Os' = [int]$values[32]
                    'Write I/Os' = [int]$values[33]
                    'Connections' = [int]$values[34]
                    'Transactions per Connection' = [float]$values[35]
                    'Total Raw Read Response Time' = [int64]$values[36]
                    'Total Raw Write Response Time' = [int64]$values[37]
                    'Total Raw Transaction Time' = [int64]$values[38]
                    'Total Raw Connection Time' = [int64]$values[39]
                    'Maximum Raw Read Response Time' = [int64]$values[40]
                    'Maximum Raw Write Response Time' = [int64]$values[41]
                    'Maximum Raw Transaction Time' = [int64]$values[42]
                    'Maximum Raw Connection Time' = [int64]$values[43]
                    'Total Raw Run Time' = [int64]$values[44]
                    'Starting Sector' = [int]$values[45]
                    'Maximum Size' = [int]$values[46]
                    'Queue Depth' = [int]$values[47]
                    '% CPU Utilization' = [float]$values[48]
                    '% User Time' = [float]$values[49]
                    '% Privileged Time' = [float]$values[50]
                    '% DPC Time' = [float]$values[51]
                    '% Interrupt Time' = [float]$values[52]
                    'Processor Speed' = [float]$values[53]
                    'Interrupts per Second' = [float]$values[54]
                    'CPU Effectiveness' = [float]$values[55]
                    'Packets/Second' = [float]$values[56]
                    'Packet Errors' = [float]$values[57]
                    'Segments Retransmitted/Second' = [float]$values[58]
                    '0 to 50 uS' = [int]$values[59]
                    '50 to 100 uS' = [int]$values[60]
                    '100 to 200 uS' = [int]$values[61]
                    '200 to 500 uS' = [int]$values[62]
                    '0.5 to 1 mS' = [int]$values[63]
                    '1 to 2 mS' = [int]$values[64]
                    '2 to 5 mS' = [int]$values[65]
                    '5 to 10 mS' = [int]$values[66]
                    '10 to 15 mS' = [int]$values[67]
                    '15 to 20 mS' = [int]$values[68]
                    '20 to 30 mS' = [int]$values[69]
                    '30 to 50 mS' = [int]$values[70]
                    '50 to 100 mS' = [int]$values[71]
                    '100 to 200 mS' = [int]$values[72]
                    '200 to 500 mS' = [int]$values[73]
                    '0.5 to 1 S' = [int]$values[74]
                    '1 to 2 s' = [int]$values[75]
                    '2 to 4.7 s' = [int]$values[76]
                    '4.7 to 5 s' = [int]$values[77]
                    '5 to 10 s' = [int]$values[78]
                    'more or equals than 10 s' = [int]$values[79]
                }
                
                $testResultProcessors += $testResultProcessor

            }

#############################################################################################
## PARSING : Get data for Workers
#############################################################################################
            if (!$notIncludeWorkers -and $line -match "^WORKER,(([^,]*),)*([^,]*)$") {
                $values = $lines[$index].Trim() -split ","
                
                $testResultWorker = @{
                    'Target Type' = $values[0]
                    'Target Name' = $values[1]
                    'Access Specification Name' = $values[2]
                    '# Managers' = if ($values[3] -ne "") { [int]$values[3] } else { $null }  
                    '# Workers' = if ($values[4] -ne "") { [int]$values[4] } else { $null }
                    '# Disks' = if ($values[5] -ne "") { [int]$values[5] } else { $null }
                    'IOps' = [float]$values[6]
                    'Read IOps' = [float]$values[7]
                    'Write IOps' = [float]$values[8]
                    'MiBps (Binary)' = [float]$values[9]
                    'Read MiBps (Binary)' = [float]$values[10]
                    'Write MiBps (Binary)' = [float]$values[11]
                    'MBps (Decimal)' = [float]$values[12]
                    'Read MBps (Decimal)' = [float]$values[13]
                    'Write MBps (Decimal)' = [float]$values[14]
                    'Transactions per Second' = [float]$values[15]
                    'Connections per Second' = [float]$values[16]
                    'Average Response Time' = [float]$values[17]
                    'Average Read Response Time' = [float]$values[18]
                    'Average Write Response Time' = [float]$values[19]
                    'Average Transaction Time' = [float]$values[20]
                    'Average Connection Time' = [float]$values[21]
                    'Maximum Response Time' = [float]$values[22]
                    'Maximum Read Response Time' = [float]$values[23]
                    'Maximum Write Response Time' = [float]$values[24]
                    'Maximum Transaction Time' = [float]$values[25]
                    'Maximum Connection Time' = [float]$values[26]
                    'Errors' = [int]$values[27]
                    'Read Errors' = [int]$values[28]
                    'Write Errors' = [int]$values[29]
                    'Bytes Read' = [int64]$values[30]
                    'Bytes Written' = [int64]$values[31]
                    'Read I/Os' = [int]$values[32]
                    'Write I/Os' = [int]$values[33]
                    'Connections' = [int]$values[34]
                    'Transactions per Connection' = [float]$values[35]
                    'Total Raw Read Response Time' = [int64]$values[36]
                    'Total Raw Write Response Time' = [int64]$values[37]
                    'Total Raw Transaction Time' = [int64]$values[38]
                    'Total Raw Connection Time' = [int64]$values[39]
                    'Maximum Raw Read Response Time' = [int64]$values[40]
                    'Maximum Raw Write Response Time' = [int64]$values[41]
                    'Maximum Raw Transaction Time' = [int64]$values[42]
                    'Maximum Raw Connection Time' = [int64]$values[43]
                    'Total Raw Run Time' = [int64]$values[44]
                    'Starting Sector' = [int]$values[45]
                    'Maximum Size' = [int]$values[46]
                    'Queue Depth' = [int]$values[47]
                    '% CPU Utilization' = [float]$values[48]
                    '% User Time' = [float]$values[49]
                    '% Privileged Time' = [float]$values[50]
                    '% DPC Time' = [float]$values[51]
                    '% Interrupt Time' = [float]$values[52]
                    'Processor Speed' = [float]$values[53]
                    'Interrupts per Second' = [float]$values[54]
                    'CPU Effectiveness' = [float]$values[55]
                    'Packets/Second' = [float]$values[56]
                    'Packet Errors' = [float]$values[57]
                    'Segments Retransmitted/Second' = [float]$values[58]
                    '0 to 50 uS' = [int]$values[59]
                    '50 to 100 uS' = [int]$values[60]
                    '100 to 200 uS' = [int]$values[61]
                    '200 to 500 uS' = [int]$values[62]
                    '0.5 to 1 mS' = [int]$values[63]
                    '1 to 2 mS' = [int]$values[64]
                    '2 to 5 mS' = [int]$values[65]
                    '5 to 10 mS' = [int]$values[66]
                    '10 to 15 mS' = [int]$values[67]
                    '15 to 20 mS' = [int]$values[68]
                    '20 to 30 mS' = [int]$values[69]
                    '30 to 50 mS' = [int]$values[70]
                    '50 to 100 mS' = [int]$values[71]
                    '100 to 200 mS' = [int]$values[72]
                    '200 to 500 mS' = [int]$values[73]
                    '0.5 to 1 S' = [int]$values[74]
                    '1 to 2 s' = [int]$values[75]
                    '2 to 4.7 s' = [int]$values[76]
                    '4.7 to 5 s' = [int]$values[77]
                    '5 to 10 s' = [int]$values[78]
                    'more or equals than 10 s' = [int]$values[79]
                }
                
                $testResultWorkers += $testResultWorker

            }
   
            $index++
        }

#############################################################################################
## MERGING : Merge the different results
#############################################################################################

        # Add the test results and access specifications to the test data
        $testData['Test Results All'] = $testResultAlls
        $testData['Test Results Managers'] = $testResultManagers
        $testData['Test Results Processors'] = $testResultProcessors
        $testData['Test Results Workers'] = $testResultWorkers
        $testData['Access Specifications'] = $testAccessSpecs

        # Add the data from the CSV file to the global array
        $outputJsonData += $testData
    } else {
        Write-Host "The file "+$csvFile.Name+" does not exist. Please check the file path." -ForegroundColor Red
    }
}

#############################################################################################
## OUTPUT
#############################################################################################

    # Convert the global data into JSON format
    # The '-Depth 5' parameter ensures that the conversion includes nested objects up to 5 levels deep
    $globalJson = $outputJsonData | ConvertTo-Json -Depth 5

    # Save the converted JSON data to a file
    # The JSON is saved in the file specified by $outputJsonPath with UTF-8 encoding
    $globalJson | Out-File -FilePath $outputJsonPath -Encoding utf8

Write-Host "The JSON file has been saved. : $outputJsonPath"
