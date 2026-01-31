# Deploy Script for Vợt Thủ Phố Núi (PCM Backend)
# Run this script in PowerShell

$VPS_IP = "103.77.172.159"
$VPS_USER = "root"
$VPS_PASS = "01685032123Hz@" 

# 1. Publish Backend
Write-Host "1. Building and Publishing Backend..." -ForegroundColor Green

# Clean previous build to avoid locking/recursion
if (Test-Path "backend/publish") { Remove-Item -Recurse -Force "backend/publish" }

dotnet publish backend/PCM.Backend.csproj -c Release -o backend/publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed!" -ForegroundColor Red
    exit 1
}

# 2. Archive Artifacts
Write-Host "2. Zipping Deployment Package..." -ForegroundColor Green
$source = "backend/publish/*"
$destination = "deploy/app.zip"

# Ensure deploy directory exists
if (!(Test-Path "deploy")) {
    New-Item -ItemType Directory -Force -Path "deploy" | Out-Null
}

if (Test-Path $destination) { Remove-Item $destination }
# Wait a bit to ensure file handles are released
Start-Sleep -Seconds 2
Compress-Archive -Path $source -DestinationPath $destination

# 3. Upload to VPS
Write-Host "3. Uploading to VPS ($VPS_IP)..." -ForegroundColor Green
# 3. Upload to VPS
Write-Host "3. Uploading to VPS ($VPS_IP)..." -ForegroundColor Green

# Verify deployment files exist
$filesToUpload = @("deploy/app.zip", "deployment/vps_install.sh", "deployment/pcm-bkt2.service", "deployment/nginx.conf")
foreach ($file in $filesToUpload) {
    if (!(Test-Path $file)) {
        Write-Host "Error: Missing file $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Uploading all files to /root/deploy/ (You will need to enter password ONCE)..."
# Combining uploads reduces password prompts
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null deploy/app.zip deployment/vps_install.sh deployment/pcm-bkt2.service deployment/nginx.conf ${VPS_USER}@${VPS_IP}:/root/deploy/

# 4. Execute Setup
Write-Host "4. Analyzing and Executing Setup on VPS..." -ForegroundColor Green
Write-Host "Executing setup script (Enter password ONE MORE time)..."
# Execute from /root/deploy/
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $VPS_USER@$VPS_IP "chmod +x /root/deploy/vps_install.sh && bash /root/deploy/vps_install.sh"

Write-Host "Deployment Process Finished!" -ForegroundColor Cyan
Write-Host "Please check: https://pcm-bkt2.duckdns.org/swagger or API endpoints."
