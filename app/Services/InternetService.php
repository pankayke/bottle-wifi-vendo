<?php

namespace App\Services;

use App\Models\User;
use App\Models\Machine;
use App\Models\WifiSession;
use App\Models\InternetCredit;
use Illuminate\Support\Facades\DB;

class InternetService
{
    /**
     * Request internet access for a user.
     *
     * @throws \Exception
     */
    public function requestInternetAccess(
        int $userId,
        int $machineId,
        int $requestedMinutes,
        ?string $macAddress = null,
        ?string $ipAddress = null
    ): array {
        return DB::transaction(function () use ($userId, $machineId, $requestedMinutes, $macAddress, $ipAddress) {
            $user = User::findOrFail($userId);
            $machine = Machine::findOrFail($machineId);

            // Check if user has enough credits
            $availableMinutes = $user->getTotalAvailableMinutes();
            if ($availableMinutes < $requestedMinutes) {
                throw new \Exception('Insufficient credits. Available: ' . $availableMinutes . ' minutes.');
            }

            // Check if machine is available
            if ($machine->status !== 'active') {
                throw new \Exception('Machine is not available.');
            }

            // Check for existing active session
            $existingSession = WifiSession::where('user_id', $userId)
                ->where('status', 'active')
                ->first();

            if ($existingSession) {
                throw new \Exception('User already has an active session.');
            }

            // Get available credit
            $credit = InternetCredit::where('user_id', $userId)
                ->where('status', 'active')
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                        ->orWhere('expires_at', '>', now());
                })
                ->whereRaw('minutes - minutes_used >= ?', [$requestedMinutes])
                ->orderBy('created_at')
                ->lockForUpdate()
                ->first();

            if (!$credit) {
                throw new \Exception('No suitable credit found.');
            }

            // Create WiFi session
            $session = WifiSession::create([
                'user_id' => $userId,
                'machine_id' => $machineId,
                'internet_credit_id' => $credit->id,
                'start_time' => now(),
                'mac_address' => $macAddress,
                'ip_address' => $ipAddress,
                'status' => 'active',
            ]);

            // Update machine
            $machine->update(['last_online' => now()]);

            return [
                'session' => $session,
                'allocated_minutes' => $requestedMinutes,
                'machine' => $machine,
            ];
        });
    }

    /**
     * End an active WiFi session.
     *
     * @throws \Exception
     */
    public function endSession(int $sessionId): array
    {
        return DB::transaction(function () use ($sessionId) {
            $session = WifiSession::with('internetCredit')->findOrFail($sessionId);

            if ($session->status !== 'active') {
                throw new \Exception('Session is not active.');
            }

            $session->end_time = now();
            $session->duration_minutes = $session->calculateDuration();
            $session->status = 'completed';
            $session->save();

            // Update credit usage
            if ($session->internetCredit) {
                $session->internetCredit->increment('minutes_used', $session->duration_minutes);

                // Mark credit as used if depleted
                if ($session->internetCredit->remaining_minutes <= 0) {
                    $session->internetCredit->update(['status' => 'used']);
                }
            }

            return [
                'session' => $session,
                'duration_minutes' => $session->duration_minutes,
            ];
        });
    }

    /**
     * Get user's current session status.
     */
    public function getUserSessionStatus(int $userId): ?array
    {
        $session = WifiSession::where('user_id', $userId)
            ->where('status', 'active')
            ->with(['machine', 'internetCredit'])
            ->first();

        if (!$session) {
            return null;
        }

        return [
            'session' => $session,
            'elapsed_minutes' => $session->calculateDuration(),
            'machine' => $session->machine,
        ];
    }

    /**
     * Get user's internet credit details.
     */
    public function getUserCredits(int $userId): array
    {
        $user = User::findOrFail($userId);
        $totalMinutes = $user->getTotalAvailableMinutes();
        
        $credits = $user->availableCredits()
            ->orderBy('created_at')
            ->get();

        return [
            'total_available_minutes' => $totalMinutes,
            'credits' => $credits,
            'total_credits_awarded' => $user->total_credits,
        ];
    }
}
