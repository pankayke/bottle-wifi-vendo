<?php

namespace App\Services;

use App\Models\Machine;
use Illuminate\Database\Eloquent\Collection;

class MachineService
{
    /**
     * Get machine status and health information.
     */
    public function getMachineStatus(int $machineId): array
    {
        $machine = Machine::with(['wifiSessions' => function ($query) {
            $query->where('status', 'active');
        }])->findOrFail($machineId);

        $activeSessions = $machine->wifiSessions->count();
        $totalBottles = $machine->bottleLogs()->count();
        $todayBottles = $machine->bottleLogs()
            ->whereDate('created_at', today())
            ->count();

        return [
            'machine' => $machine,
            'is_online' => $machine->isOnline(),
            'active_sessions' => $activeSessions,
            'total_bottles_collected' => $totalBottles,
            'today_bottles_collected' => $todayBottles,
        ];
    }

    /**
     * Update machine's last online timestamp.
     */
    public function updateHeartbeat(int $machineId): Machine
    {
        $machine = Machine::findOrFail($machineId);
        $machine->update(['last_online' => now()]);

        return $machine;
    }

    /**
     * Get all machines with their status.
     */
    public function getAllMachines(): Collection
    {
        return Machine::orderBy('name')->get();
    }

    /**
     * Update machine status.
     */
    public function updateMachineStatus(int $machineId, string $status): Machine
    {
        $validStatuses = ['active', 'inactive', 'maintenance'];
        
        if (!in_array($status, $validStatuses)) {
            throw new \InvalidArgumentException('Invalid machine status.');
        }

        $machine = Machine::findOrFail($machineId);
        $machine->update(['status' => $status]);

        return $machine;
    }

    /**
     * Create a new machine.
     */
    public function createMachine(array $data): Machine
    {
        return Machine::create([
            'name' => $data['name'],
            'location' => $data['location'],
            'status' => $data['status'] ?? 'active',
            'last_online' => now(),
        ]);
    }
}
