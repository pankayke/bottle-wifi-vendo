<?php

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\BottleController;
use App\Http\Controllers\API\InternetController;
use App\Http\Controllers\API\MachineController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group.
|
*/

// Public routes
Route::prefix('v1')->group(function () {
    // Authentication routes
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    
    // Machine heartbeat (can be called by ESP32 without user auth)
    Route::post('/machine/heartbeat', [MachineController::class, 'heartbeat']);
    
    // Machine status (can be called by ESP32 without user auth)
    Route::get('/machine/status', [MachineController::class, 'status']);
    
    // Bottle detection (called by ESP32 when bottle is inserted)
    Route::post('/bottle-detected', [BottleController::class, 'bottleDetected']);
});

// Protected routes (require API token authentication)
Route::prefix('v1')->middleware('api.auth')->group(function () {
    // Authentication
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    
    // Bottle routes
    Route::get('/bottle/history', [BottleController::class, 'history']);
    Route::get('/bottle/statistics', [BottleController::class, 'statistics']);
    
    // Internet access routes
    Route::post('/request-internet', [InternetController::class, 'requestInternet']);
    Route::post('/internet/end-session', [InternetController::class, 'endSession']);
    Route::get('/internet/session-status', [InternetController::class, 'sessionStatus']);
    Route::get('/user-credits', [InternetController::class, 'userCredits']);
    
    // Machine routes
    Route::get('/machines', [MachineController::class, 'index']);
    Route::get('/machines', [MachineController::class, 'index']);
    Route::post('/machine', [MachineController::class, 'store']);
    Route::put('/machine/status', [MachineController::class, 'updateStatus']);
});
