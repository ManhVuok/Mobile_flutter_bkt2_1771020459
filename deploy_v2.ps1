# ==========================================
# CONFIGURATION
# ==========================================
$VPS_IP = "103.77.172.159"
$VPS_USER = "root"  # Thường là 'root' hoặc 'ubuntu'. Anh check mail để chắc chắn.
# Mật khẩu: Nhom142022hZ@ (Anh nhập tay khi được hỏi)

# ==========================================
# 1. BUILD & PACKAGE
# ==========================================
Write-Host "1. Building Project..." -ForegroundColor Cyan
if (Test-Path "backend/publish") { Remove-Item -Recurse -Force "backend/publish" }
dotnet publish backend/PCM.Backend.csproj -c Release -o backend/publish

if ($LASTEXITCODE -ne 0) { Write-Error "Build Failed!"; exit 1 }

# Force release of file handles
dotnet build-server shutdown

# Wait for file handles to be released
Write-Host "Waiting 5s for files to unlock..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Host "2. Zipping..." -ForegroundColor Cyan
if (Test-Path "deploy_v2.zip") { Remove-Item "deploy_v2.zip" -Force }

# Robust Zipping with Retry
$maxRetries = 3
$retryCount = 0
$zipSuccess = $false

while (-not $zipSuccess -and $retryCount -lt $maxRetries) {
    try {
        Compress-Archive -Path "backend/publish/*" -DestinationPath "deploy_v2.zip" -Force -ErrorAction Stop
        $zipSuccess = $true
    }
    catch {
        Write-Warning "Zip failed (Attempt $($retryCount + 1)/$maxRetries). Retrying in 5s..."
        Start-Sleep -Seconds 5
        $retryCount++
    }
}

if (-not $zipSuccess) {
    Write-Error "Could not create zip file. Please check if files in backend/publish are open."
    exit 1
}

# ==========================================
# 2. UPLOAD TO VPS
# ==========================================
Write-Host "3. Uploading to VPS ($VPS_IP)..." -ForegroundColor Cyan
Write-Host "Luu y: Nhap mat khau 2 lan!" -ForegroundColor Yellow

# Upload to /tmp/ to avoid Permission Denied (works for all users)
# Upload to /tmp/ to avoid Permission Denied (works for all users)
# Use literal arguments to avoid parsing errors
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null deploy_v2.zip deployment/vps_init.sh deployment/pcm-bkt2.service deployment/nginx.conf ${VPS_USER}@${VPS_IP}:/tmp/

# ==========================================
# 3. INSTALL & RUN
# ==========================================
Write-Host "4. Installing on VPS..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${VPS_USER}@${VPS_IP} "chmod +x /tmp/vps_init.sh && sudo bash /tmp/vps_init.sh"

Write-Host "DONE! Kiem tra: https://pcm-bkt2.duckdns.org/swagger" -ForegroundColor Green
