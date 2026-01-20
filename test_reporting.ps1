$ErrorActionPreference = "Stop"

function Test-Reporting {
    Write-Host "--- Testing MOH Reporting Endpoint ---" -ForegroundColor Cyan

    # 1. Login as MOH to get Token (Assuming MOH exists, or we use seed data)
    # If no MOH exists, we might need to create one or use a hardcoded token if we knew the secret (we don't easily).
    # Since we seeded `test_midwife`, we don't necessarily have `test_moh`.
    # But `seed_full_flow` created mothers.
    # Let's try to register a temp MOH officer first to ensure we can login.
    
    $mohUser = "test_moh_report"
    $mohPass = "Test@123"
    $mohArea = "Colombo"

    Write-Host "1. Registering/Ensuring MOH Account..."
    try {
        $body = @{
            username = $mohUser
            password = $mohPass
            full_name = "Test MOH Officer"
            moh_area = $mohArea
            email = "testmoh@example.com"
        } | ConvertTo-Json
        
        $reg = Invoke-RestMethod -Uri "http://localhost:8000/moh/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
        Write-Host "   Registered new MOH." -ForegroundColor Green
    } catch {
        Write-Host "   MOH likely already exists (Expected)." -ForegroundColor Yellow
    }

    # 2. Login
    Write-Host "2. Logging in..."
    $loginBody = "username=$mohUser&password=$mohPass"
    try {
        $tokenRes = Invoke-RestMethod -Uri "http://localhost:8000/moh/token" -Method Post -Body $loginBody -ContentType "application/x-www-form-urlencoded"
        $token = $tokenRes.access_token
        Write-Host "   Login Successful. Token received." -ForegroundColor Green
    } catch {
        Write-Host "   Login Failed! Check server logs." -ForegroundColor Red
        exit 1
    }

    # 3. Fetch Reports
    Write-Host "3. Fetching Weekly Stats..."
    $headers = @{ "Authorization" = "Bearer $token" }
    
    try {
        $stats = Invoke-RestMethod -Uri "http://localhost:8000/reports/stats" -Method Get -Headers $headers
        
        Write-Host "   Response Received!" -ForegroundColor Green
        # Write-Host ($stats | ConvertTo-Json -Depth 5)

        # 4. Verify Structure
        if ($stats.population -and $stats.risks -and $stats.weekly) {
            Write-Host "   [PASS] JSON Structure Valid." -ForegroundColor Green
            Write-Host "   Total Population: $($stats.population.total)"
            Write-Host "   High Risk Cases: $($stats.risks.high)"
        } else {
            Write-Host "   [FAIL] Invalid JSON Structure." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "   [FAIL] Could not fetch reports: $_" -ForegroundColor Red
        exit 1
    }
}

Test-Reporting
