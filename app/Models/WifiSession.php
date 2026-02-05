<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WifiSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'machine_id',
        'internet_credit_id',
        'start_time',
        'end_time',
        'duration_minutes',
        'ip_address',
        'mac_address',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'start_time' => 'datetime',
            'end_time' => 'datetime',
            'duration_minutes' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function machine(): BelongsTo
    {
        return $this->belongsTo(Machine::class);
    }

    public function internetCredit(): BelongsTo
    {
        return $this->belongsTo(InternetCredit::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active' && !$this->end_time;
    }

    public function calculateDuration(): int
    {
        if (!$this->start_time) {
            return 0;
        }

        $endTime = $this->end_time ?? now();
        return $this->start_time->diffInMinutes($endTime);
    }
}
