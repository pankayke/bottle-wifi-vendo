<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class InternetCredit extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'minutes',
        'minutes_used',
        'status',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'minutes' => 'integer',
            'minutes_used' => 'integer',
            'expires_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function wifiSessions(): HasMany
    {
        return $this->hasMany(WifiSession::class);
    }

    public function getRemainingMinutesAttribute(): int
    {
        return max(0, $this->minutes - $this->minutes_used);
    }

    public function isExpired(): bool
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    public function isAvailable(): bool
    {
        return $this->status === 'active' 
            && !$this->isExpired() 
            && $this->remaining_minutes > 0;
    }
}
