<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone_number',
        'total_credits',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'api_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'total_credits' => 'integer',
        ];
    }

    public function bottleLogs(): HasMany
    {
        return $this->hasMany(BottleLog::class);
    }

    public function internetCredits(): HasMany
    {
        return $this->hasMany(InternetCredit::class);
    }

    public function wifiSessions(): HasMany
    {
        return $this->hasMany(WifiSession::class);
    }

    public function availableCredits(): HasMany
    {
        return $this->internetCredits()
            ->where('status', 'active')
            ->where(function ($query) {
                $query->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            });
    }

    public function getTotalAvailableMinutes(): int
    {
        return $this->availableCredits()
            ->selectRaw('SUM(minutes - minutes_used) as total')
            ->value('total') ?? 0;
    }

    public function generateApiToken(): string
    {
        $this->api_token = Str::random(80);
        $this->save();

        return $this->api_token;
    }
}
