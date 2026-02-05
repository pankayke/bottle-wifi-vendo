<?php

namespace Tests\Feature;

use App\Models\Machine;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MachineTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_get_machine_status(): void
    {
        $machine = Machine::factory()->create();

        $response = $this->getJson('/api/v1/machine/status?machine_id=' . $machine->id);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'machine',
                    'is_online',
                    'active_sessions',
                    'total_bottles_collected',
                    'today_bottles_collected',
                ],
            ]);
    }

    public function test_can_update_machine_heartbeat(): void
    {
        $machine = Machine::factory()->create();

        $response = $this->postJson('/api/v1/machine/heartbeat', [
            'machine_id' => $machine->id,
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $machine->refresh();
        $this->assertNotNull($machine->last_online);
    }

    public function test_authenticated_user_can_get_all_machines(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();

        Machine::factory()->count(3)->create();

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->getJson('/api/v1/machines');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'machines',
                ],
            ]);
    }

    public function test_authenticated_user_can_create_machine(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->postJson('/api/v1/machine', [
            'name' => 'Test Machine',
            'location' => 'Test Location',
            'status' => 'active',
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('machines', [
            'name' => 'Test Machine',
            'location' => 'Test Location',
        ]);
    }

    public function test_authenticated_user_can_update_machine_status(): void
    {
        $user = User::factory()->create();
        $user->generateApiToken();
        $machine = Machine::factory()->create(['status' => 'active']);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $user->api_token,
        ])->putJson('/api/v1/machine/status', [
            'machine_id' => $machine->id,
            'status' => 'maintenance',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $machine->refresh();
        $this->assertEquals('maintenance', $machine->status);
    }
}
