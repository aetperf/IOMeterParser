# Paramètres d'entrée
param (
    [Parameter(Mandatory=$true)]
    [string]$csvDirectory,  # Répertoire des fichiers CSV
    
    [Parameter(Mandatory=$true)]
    [string]$csvPattern  # Modèle pour rechercher les fichiers CSV
)

# Obtenir la liste de tous les fichiers CSV dans le répertoire qui respectent le modèle
$csvFiles = Get-ChildItem -Path $csvDirectory -Filter $csvPattern

# Initialiser une liste pour stocker les résultats de tous les fichiers CSV
$allTestData = @()

# Traiter chaque fichier CSV
foreach ($csvFile in $csvFiles) {
    # Chemin vers le fichier CSV actuel
    $csvFilePath = $csvFile.FullName

    # Vérifiez si le fichier existe
    if (Test-Path $csvFilePath) {
        # Lire le fichier CSV brut
        $lines = Get-Content -Path $csvFilePath

        # Initialiser un dictionnaire pour stocker les données du test
        $testData = @{
            'File Name' = $csvFile.Name  # Ajouter le nom du fichier au testData
            'Test Type' = $null
            'Test Description' = $null
            'Time Stamp' = $null
            'Access Specifications' = @()
            'Test Results' = @()
        }

        # Variables pour stocker les spécifications d'accès
        $accessSpecs = @()

        # Variables pour stocker les résultats des tests
        $testResults= @()

        # Parcours ligne par ligne
        $inAccessSpecs = $false

        $index = 0
        foreach ($line in $lines) {
            # Nettoyer la ligne (supprimer les espaces et sauter les lignes vides)
            $line = $line.Trim()

            # Vérifier si la ligne est une ligne de test
            if ($line -match "^'(Test Type),(Test Description)$") {
                if ($lines[$index + 1].Trim() -match "(\d+),(.+)") {
                    $testData['Test Type'] = $matches[1]
                    $testData['Test Description'] = $matches[2]
                }
            }
            # Vérifier si nous avons trouvé le timestamp
            elseif ($line -match "^'Time Stamp$") {
                $testData['Time Stamp'] = $lines[$lines.IndexOf($line) + 1].Trim()
            }

            # Vérifier si nous avons trouvé la section 'Access specifications'
            elseif ($line -match "^'Access specifications$") {
                $inAccessSpecs = $true
            }

            # Vérifier si nous avons atteint la fin des spécifications d'accès
            elseif ($line -match "^'End access specifications$") {
                $inAccessSpecs = $false
            }

            # Si nous sommes dans la section des spécifications d'accès
            if ($inAccessSpecs -and $line -match "^'(Access specification name),(default assignment)$") {
                if ($lines[$index + 1].Trim() -match "^(\S+),(\d+)$") {
                    $accessSpecName = $matches[1]
                    $defaultAssign = $matches[2]
                }
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
                $accessSpecs += $accessSpec
            }

            # Vérifier si la ligne est la ligne de résultats des tests
            if ($line -like "'Target Type,Target Name,Access Specification Name,# Managers,# Workers,# Disks,IOps,Read IOps,Write IOps,MiBps (Binary),Read MiBps (Binary),Write MiBps (Binary),MBps (Decimal),Read MBps (Decimal),Write MBps (Decimal),Transactions per Second,Connections per Second,Average Response Time,Average Read Response Time,Average Write Response Time,Average Transaction Time,Average Connection Time,Maximum Response Time,Maximum Read Response Time,Maximum Write Response Time,Maximum Transaction Time,Maximum Connection Time,Errors,Read Errors,Write Errors,Bytes Read,Bytes Written,Read I/Os,Write I/Os,Connections,Transactions per Connection,Total Raw Read Response Time,Total Raw Write Response Time,Total Raw Transaction Time,Total Raw Connection Time,Maximum Raw Read Response Time,Maximum Raw Write Response Time,Maximum Raw Transaction Time,Maximum Raw Connection Time,Total Raw Run Time,Starting Sector,Maximum Size,Queue Depth,% CPU Utilization,% User Time,% Privileged Time,% DPC Time,% Interrupt Time,Processor Speed,Interrupts per Second,CPU Effectiveness,Packets/Second,Packet Errors,Segments Retransmitted/Second,0 to 50 uS,50 to 100 uS,100 to 200 uS,200 to 500 uS,0.5 to 1 mS,1 to 2 mS,2 to 5 mS,5 to 10 mS,10 to 15 mS,15 to 20 mS,20 to 30 mS,30 to 50 mS,50 to 100 mS,100 to 200 mS,200 to 500 mS,0.5 to 1 S,1 to 2 s,2 to 4.7 s,4.7 to 5 s,5 to 10 s, >= 10 s") {
                if ($lines[$index + 2].Trim() -match "^(([^,]*),)*([^,]*)$") {
                    # Séparer la ligne en utilisant la virgule comme délimiteur
                    $values = $lines[$index + 2].Trim() -split ","
                
                    $testResult = @{
                        'Target Type' = $values[0]
                        'Target Name' = $values[1]
                        'Access Specification Name' = $values[2]
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
                    
                    $testResults += $testResult
                }
            }
            $index++
        }

        # Ajouter les résultats du test et des spécifications d'accès aux données du test
        $testData['Test Results'] = $testResults
        $testData['Access Specifications'] = $accessSpecs

        # Ajouter les données du fichier CSV au tableau global
        $allTestData += $testData
    } else {
        Write-Host "Le fichier spécifié n'existe pas. Vérifiez le chemin du fichier." -ForegroundColor Red
    }
}

# Convertir les données globales en JSON
$globalJson = $allTestData | ConvertTo-Json -Depth 5


# Sauvegarder le JSON global dans un fichier
$jsonFilePath = "D:\pacollet\Client\Edilians\Benchmark\global_test_output.json"
$globalJson | Out-File -FilePath $jsonFilePath -Encoding utf8

Write-Host "Le fichier JSON global a été sauvegardé à : $jsonFilePath"
