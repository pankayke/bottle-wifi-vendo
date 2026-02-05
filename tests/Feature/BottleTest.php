<?php

namespace Tests\Feature;

use App\Models\Machine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BottleTest extends TestCase
{
    use RefreshDatabase;

    public function test_bottle_detection_processes_successfully(): void
    {
        $user = User::factory()->create();
        $machine = Machine::factory()->create(['status' => 'active']);

        $response = $this->postJson('/api/v1/bottle-detected', [
            'user_id' => $user->id,
            'machine_id' => $machine->id,
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'credits_earned',
                    'total_available_minutes',
                    'bottle_log',
                ],
            ]);

        $this->assertDatabaseHas('bottle_logs', [
            'user_id' => $user->id,
            'machine_id' => $machine->id,
        ]);

        $this->assertDatabaseHas('internet_credits', [
            'user_id' => $user->id,
            'minutes' => 10,
        ]);
    }

    public function test_bottle_detection_fails_with_inactive_machine(): void
    {
        $user = User::factory()->create();
        $machine = Machine::factory()->create(['status' => 'inactive']);

        $response = $this->postJson('/api/v1/bottle-detected', [
            'user_id' => $user->id,
            'machine_id' => $machine->id,
        ]);

        $response->assertStatus(400)
            ->assertJson(['success' => false]);
    }

    public function test_authenticated_user_can_view_bottle_history(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();
        $machine = Machine::factory()->create();

        // Create some bottle logs
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/v1/bottle-detected', [
                'user_id' => $user->id,
                'machine_id' => $machine->id,
            ]);
        }

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->getJson('/api/v1/bottle/history');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'history',
                ],
            ]);
    }

    public function test_authenticated_user_can_view_bottle_statistics(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->getJson('/api/v1/bottle/statistics');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'total_bottles',
                    'total_credits_earned',
                    'today_bottles',
                ],
            ]);
    }
}
