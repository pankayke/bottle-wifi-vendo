<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService
{
    /**
     * Register a new user and generate an API token.
     */
    public function register(array $data): array
    {
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone_number' => $data['phone_number'] ?? null,
        ]);

        $token = $user->generateApiToken();

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    /**
     * Authenticate a user and return  API token.
     *
     * @throws ValidationException
     */
    public function login(string $email, string $password): array
    {
        $user = User::where('email', $email)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->generateApiToken();

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    /**
     * Logout user by revoking API token.
     */
    public function logout(User $user): void
    {
        $user->api_token = null;
        $user->save();
    }
}
