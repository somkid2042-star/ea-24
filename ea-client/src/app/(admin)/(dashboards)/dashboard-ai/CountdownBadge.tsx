import { useEffect, useState } from 'react';

export const CountdownBadge = ({ interval, lastRunTime, isRunning, enabled }: { interval: number, lastRunTime: number | null, isRunning: boolean, enabled: boolean }) => {
    const [timeLeft, setTimeLeft] = useState<{ m: number, s: number } | null>(null);

    useEffect(() => {
        if (!interval || !enabled || isRunning) {
            setTimeLeft(null);
            return;
        }

        const totalMs = interval * 60 * 1000;
        const updateCountdown = () => {
            if (lastRunTime) {
                const target = lastRunTime + totalMs;
                const remaining = Math.max(0, target - Date.now());
                const totalSecs = Math.floor(remaining / 1000);
                setTimeLeft({ m: Math.floor(totalSecs / 60), s: totalSecs % 60 });
            } else {
                const totalSec = interval * 60;
                const now = Math.floor(Date.now() / 1000);
                const rem = totalSec - (now % totalSec);
                setTimeLeft({ m: Math.floor(rem / 60), s: rem % 60 });
            }
        };

        updateCountdown();
        const id = setInterval(updateCountdown, 1000);
        return () => clearInterval(id);
    }, [lastRunTime, interval, enabled, isRunning]);

    if (!enabled) return <span className="text-[10px] text-gray-500 uppercase px-2 py-0.5 rounded border border-gray-200 dark:border-gray-700">ระงับการทำงาน</span>;
    if (isRunning) return <span className="text-[10px] text-blue-600 dark:text-blue-400 font-bold uppercase animate-pulse px-2 py-0.5 rounded bg-blue-50 dark:bg-blue-900/30">กำลังวิเคราะห์...</span>;
    if (!timeLeft) return null;

    return (
        <span className="text-[11px] font-mono font-bold bg-blue-50/80 dark:bg-blue-900/30 px-2 py-0.5 rounded-full text-blue-600 dark:text-blue-400 border border-blue-100 dark:border-blue-800">
            {String(timeLeft.m).padStart(2, '0')}:{String(timeLeft.s).padStart(2, '0')}
        </span>
    );
};
