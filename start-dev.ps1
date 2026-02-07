# Bottle WiFi Vendo - Development Server Startup Script
# Starts both Laravel backend and Flutter frontend

Write-Host "Starting Bottle WiFi Vendo Development Environment..." -ForegroundColor Green
Write-Host ""

# Check if Laravel backend directory exists
if (-Not (Test-Path ".\bottle-wifi-backend")) {
    Write-Host "Error: bottle-wifi-backend directory not found!" -ForegroundColor Red
    exit 1
}

# Start Laravel backend in a new window
Write-Host "Starting Laravel Backend Server..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\bottle-wifi-backend'; Write-Host 'Laravel Backend Server' -ForegroundColor Yellow; Write-Host 'URL: http://localhost:8000' -ForegroundColor Green; Write-Host ''; php artisan serve"

# Wait a moment for Laravel to start
Start-Sleep -Seconds 3

# Start Flutter app in another window
Write-Host "Starting Flutter App..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; Write-Host 'Flutter Development Server' -ForegroundColor Yellow; Write-Host ''; flutter run -d chrome"

Write-Host ""
Write-Host "Development servers starting..." -ForegroundColor Green
Write-Host "Laravel Backend:  http://localhost:8000" -ForegroundColor Yellow
Write-Host "Flutter App:      Will open in Chrome" -ForegroundColor Yellow
Write-Host ""
Write-Host "To stop servers: Close the PowerShell windows or press Ctrl+C in each" -ForegroundColor Gray
