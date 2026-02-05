<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Machine extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'location',
        'status',
        'last_online',
    ];

    protected function casts(): array
    {
        return [
            'last_online' => 'datetime',
        ];
    }

    public function bottleLogs(): HasMany
    {
        return $this->hasMany(BottleLog::class);
    }

    public function wifiSessions(): HasMany
    {
        return $this->hasMany(WifiSession::class);
    }

    public function isOnline(): bool
    {
        if (!$this->last_online) {
            return false;
        }

        return $this->last_online->diffInMinutes(now()) <= 5;
    }
}
