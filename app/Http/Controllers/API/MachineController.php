<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\MachineService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class MachineController extends Controller
{
    public function __construct(
        private readonly MachineService $machineService
    ) {}

    /**
     * Get machine status and health information.
     */
    public function status(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'machine_id' => ['required', 'integer', 'exists:machines,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $status = $this->machineService->getMachineStatus(
                $request->input('machine_id')
            );

            return response()->json([
                'success' => true,
                'data' => $status,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch machine status',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update machine heartbeat (called by ESP32).
     */
    public function heartbeat(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'machine_id' => ['required', 'integer', 'exists:machines,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $machine = $this->machineService->updateHeartbeat(
                $request->input('machine_id')
            );

            return response()->json([
                'success' => true,
                'message' => 'Heartbeat updated',
                'data' => [
                    'machine' => $machine,
                    'is_online' => $machine->isOnline(),
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Heartbeat update failed',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get all machines.
     */
    public function index(): JsonResponse
    {
        try {
            $machines = $this->machineService->getAllMachines();

            return response()->json([
                'success' => true,
                'data' => [
                    'machines' => $machines,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch machines',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Create a new machine.
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'location' => ['required', 'string', 'max:255'],
            'status' => ['nullable', 'in:active,inactive,maintenance'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $machine = $this->machineService->createMachine($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Machine created successfully',
                'data' => [
                    'machine' => $machine,
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create machine',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update machine status.
     */
    public function updateStatus(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'machine_id' => ['required', 'integer', 'exists:machines,id'],
            'status' => ['required', 'in:active,inactive,maintenance'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $machine = $this->machineService->updateMachineStatus(
                $request->input('machine_id'),
                $request->input('status')
            );

            return response()->json([
                'success' => true,
                'message' => 'Machine status updated',
                'data' => [
                    'machine' => $machine,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update machine status',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
