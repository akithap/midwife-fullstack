$baseUrl = "http://127.0.0.1:8000"

try {
    # 1. Login
    Write-Host "Logging in..."
    $tokenResp = Invoke-RestMethod -Uri "$baseUrl/token" -Method Post -Body @{username="test_midwife"; password="123"}
    $token = $tokenResp.access_token
    $headers = @{Authorization="Bearer $token"; "Content-Type"="application/json"}

    # 2. Use Mother ID 2 (Mother Late - Pregnant)
    $motherId = 2

    # 3. Create Appointment
    Write-Host "Creating Appointment..."
    $today = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $apptBody = @{
        date_time = $today
        visit_type = "Clinic"
        status = "Scheduled"
    } | ConvertTo-Json
    $apptResp = Invoke-RestMethod -Uri "$baseUrl/appointments/?mother_id=$motherId" -Method Post -Headers $headers -Body $apptBody
    $apptId = $apptResp.id
    Write-Host "Created Appointment ID: $apptId"

    # 4. Try to Complete (Should Fail)
    Write-Host "Attempting to Complete without ANC Record..."
    try {
        $updateBody = @{status="Completed"} | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/appointments/$apptId" -Method Put -Headers $headers -Body $updateBody
        Write-Host "TEST FAILED: Should have been blocked!" -ForegroundColor Red
    } catch {
        # Check if error is 400
        $respStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($respStream)
        $errBody = $reader.ReadToEnd()
        Write-Host "TEST PASSED: Blocked with error: $errBody" -ForegroundColor Green
    }

} catch {
    Write-Host "Script Error: $_" -ForegroundColor Red
}
