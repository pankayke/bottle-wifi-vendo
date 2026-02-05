<?php

namespace Database\Seeders;

use App\Models\Machine;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create test user
        $user = User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password123',
            'phone_number' => '+1234567890',
        ]);

        // Generate API token for the test user
        $user->generateApiToken();
        
        $this->command->info('Test User created:');
        $this->command->info('Email: test@example.com');
        $this->command->info('Password: password123');
        $this->command->info('API Token: ' . $user->api_token);

        // Create machines
        Machine::factory()->create([
            'name' => 'Machine Alpha',
            'location' => 'Building A - Floor 1',
            'status' => 'active',
        ]);

        Machine::factory()->create([
            'name' => 'Machine Beta',
            'location' => 'Building B - Floor 2',
            'status' => 'active',
        ]);

        Machine::factory()->create([
            'name' => 'Machine Gamma',
            'location' => 'Building C - Floor 3',
            'status' => 'maintenance',
        ]);

        $this->command->info('3 machines created successfully.');
    }
}

