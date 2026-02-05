<?php

namespace App\Services;

use App\Models\BottleLog;
use App\Models\User;
use App\Models\Machine;
use App\Models\InternetCredit;
use Illuminate\Support\Facades\DB;

class BottleService
{
    private const CREDITS_PER_BOTTLE = 10;

    /**
     * Process bottle insertion and award credits to user.
     *
     * @throws \Exception
     */
    public function processBottleInsertion(int $userId, int $machineId): array
    {
        return DB::transaction(function () use ($userId, $machineId) {
            $user = User::findOrFail($userId);
            $machine = Machine::findOrFail($machineId);

            if ($machine->status !== 'active') {
                throw new \Exception('Machine is not active.');
            }

            // Log the bottle insertion
            $bottleLog = BottleLog::create([
                'user_id' => $userId,
                'machine_id' => $machineId,
                'credits_earned' => self::CREDITS_PER_BOTTLE,
            ]);

            // Add credits to user
            $internetCredit = InternetCredit::create([
                'user_id' => $userId,
                'minutes' => self::CREDITS_PER_BOTTLE,
                'minutes_used' => 0,
                'status' => 'active',
                'expires_at' => now()->addDays(30),
            ]);

            // Update user total credits
            $user->increment('total_credits', self::CREDITS_PER_BOTTLE);

            // Update machine last_online
            $machine->update(['last_online' => now()]);

            return [
                'bottle_log' => $bottleLog,
                'internet_credit' => $internetCredit,
                'total_available_minutes' => $user->getTotalAvailableMinutes(),
            ];
        });
    }

    /**
     * Get bottle insertion history for a user.
     */
    public function getUserBottleHistory(int $userId, int $limit = 50): iterable
    {
        return BottleLog::where('user_id', $userId)
            ->with('machine')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();
    }

    /**
     * Get bottle insertion statistics for a user.
     */
    public function getUserBottleStats(int $userId): array
    {
        $totalBottles = BottleLog::where('user_id', $userId)->count();
        $totalCreditsEarned = BottleLog::where('user_id', $userId)
            ->sum('credits_earned');
        $todayBottles = BottleLog::where('user_id', $userId)
            ->whereDate('created_at', today())
            ->count();

        return [
            'total_bottles' => $totalBottles,
            'total_credits_earned' => $totalCreditsEarned,
            'today_bottles' => $todayBottles,
        ];
    }
}
