<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\InternetService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class InternetController extends Controller
{
    public function __construct(
        private readonly InternetService $internetService
    ) {}

    /**
     * Request internet access.
     */
    public function requestInternet(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'machine_id' => ['required', 'integer', 'exists:machines,id'],
            'requested_minutes' => ['required', 'integer', 'min:1', 'max:1440'],
            'mac_address' => ['nullable', 'string', 'max:17'],
            'ip_address' => ['nullable', 'ip'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $result = $this->internetService->requestInternetAccess(
                $request->user()->id,
                $request->input('machine_id'),
                $request->input('requested_minutes'),
                $request->input('mac_address'),
                $request->input('ip_address')
            );

            return response()->json([
                'success' => true,
                'message' => 'Internet access granted',
                'data' => [
                    'session_id' => $result['session']->id,
                    'allocated_minutes' => $result['allocated_minutes'],
                    'start_time' => $result['session']->start_time,
                    'machine' => $result['machine'],
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Internet access request failed',
                'error' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * End active internet session.
     */
    public function endSession(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'session_id' => ['required', 'integer', 'exists:wifi_sessions,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $result = $this->internetService->endSession(
                $request->input('session_id')
            );

            return response()->json([
                'success' => true,
                'message' => 'Session ended successfully',
                'data' => [
                    'session_id' => $result['session']->id,
                    'duration_minutes' => $result['duration_minutes'],
                    'end_time' => $result['session']->end_time,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to end session',
                'error' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Get current session status.
     */
    public function sessionStatus(Request $request): JsonResponse
    {
        try {
            $status = $this->internetService->getUserSessionStatus($request->user()->id);

            if (!$status) {
                return response()->json([
                    'success' => true,
                    'message' => 'No active session',
                    'data' => [
                        'active_session' => false,
                    ],
                ], 200);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'active_session' => true,
                    'session' => $status['session'],
                    'elapsed_minutes' => $status['elapsed_minutes'],
                    'machine' => $status['machine'],
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch session status',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get user's available credits.
     */
    public function userCredits(Request $request): JsonResponse
    {
        try {
            $credits = $this->internetService->getUserCredits($request->user()->id);

            return response()->json([
                'success' => true,
                'data' => $credits,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch credits',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
