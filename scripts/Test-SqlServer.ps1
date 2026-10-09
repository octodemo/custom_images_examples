[CmdletBinding()]
param(
    [switch]$CreateExampleDatabase,
    [int]$TimeoutSeconds = 90
)

$ErrorActionPreference = "Stop"
$connectionString = "Server=localhost;Database=master;Integrated Security=True;Encrypt=False;Connection Timeout=5"
$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
$lastError = $null

do {
    $connection = [System.Data.SqlClient.SqlConnection]::new($connectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128))"
        $version = [string]$command.ExecuteScalar()

        if ($CreateExampleDatabase) {
            $command.CommandText = @"
IF DB_ID(N'CustomImageExample') IS NULL
BEGIN
    CREATE DATABASE [CustomImageExample];
END;
"@
            $command.ExecuteNonQuery() | Out-Null
        }

        Write-Host "SQL Server $version is ready."
        exit 0
    } catch {
        $lastError = $_
        Start-Sleep -Seconds 3
    } finally {
        $connection.Dispose()
    }
} while ([DateTime]::UtcNow -lt $deadline)

throw "SQL Server did not become ready within $TimeoutSeconds seconds: $lastError"

