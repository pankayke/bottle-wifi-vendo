<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\BottleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BottleController extends Controller
{
    public function __construct(
        private readonly BottleService $bottleService
    ) {}

    /**
     * Process bottle insertion from ESP32 device.
     */
    public function bottleDetected(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'machine_id' => ['required', 'integer', 'exists:machines,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $result = $this->bottleService->processBottleInsertion(
                $request->input('user_id'),
                $request->input('machine_id')
            );

            return response()->json([
                'success' => true,
                'message' => 'Bottle processed successfully',
                'data' => [
                    'credits_earned' => $result['bottle_log']->credits_earned,
                    'total_available_minutes' => $result['total_available_minutes'],
                    'bottle_log' => $result['bottle_log'],
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to process bottle',
                'error' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Get user's bottle insertion history.
     */
    public function history(Request $request): JsonResponse
    {
        try {
            $userId = $request->user()->id;
            $limit = $request->input('limit', 50);

            $history = $this->bottleService->getUserBottleHistory($userId, $limit);

            return response()->json([
                'success' => true,
                'data' => [
                    'history' => $history,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch history',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get user's bottle statistics.
     */
    public function statistics(Request $request): JsonResponse
    {
        try {
            $userId = $request->user()->id;
            $stats = $this->bottleService->getUserBottleStats($userId);

            return response()->json([
                'success' => true,
                'data' => $stats,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch statistics',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
