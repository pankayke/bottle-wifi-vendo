<?php

namespace Tests\Feature;

use App\Models\InternetCredit;
use App\Models\Machine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InternetTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_request_internet_access(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();
        $machine = Machine::factory()->create(['status' => 'active']);

        // Give user some credits
        InternetCredit::create([
            'user_id' => $user->id,
            'minutes' => 30,
            'minutes_used' => 0,
            'status' => 'active',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->postJson('/api/v1/request-internet', [
            'machine_id' => $machine->id,
            'requested_minutes' => 10,
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'session_id',
                    'allocated_minutes',
                    'start_time',
                ],
            ]);

        $this->assertDatabaseHas('wifi_sessions', [
            'user_id' => $user->id,
            'machine_id' => $machine->id,
            'status' => 'active',
        ]);
    }

    public function test_internet_request_fails_with_insufficient_credits(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();
        $machine = Machine::factory()->create(['status' => 'active']);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->postJson('/api/v1/request-internet', [
            'machine_id' => $machine->id,
            'requested_minutes' => 10,
        ]);

        $response->assertStatus(400)
            ->assertJson(['success' => false]);
    }

    public function test_user_can_get_available_credits(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();

        InternetCredit::create([
            'user_id' => $user->id,
            'minutes' => 50,
            'minutes_used' => 10,
            'status' => 'active',
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->getJson('/api/v1/user-credits');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'total_available_minutes',
                    'credits',
                    'total_credits_awarded',
                ],
            ]);
    }

    public function test_user_can_check_session_status(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->getJson('/api/v1/internet/session-status');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'active_session' => false,
                ],
            ]);
    }
}
