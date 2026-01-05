/*
En LSL Framework
Copyright (C) 2024-25  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework

╒══════════════════════════════════════════════════════════════════════════════╕
│ LICENSE                                                                      │
└──────────────────────────────────────────────────────────────────────────────┘

This script is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this script.  If not, see <https://www.gnu.org/licenses/>.
*/

integer _ENTEST_BENCHMARK_RUNNING;

string _ENTEST_BENCHMARK_START_TIMESTAMP;
integer _ENTEST_BENCHMARK_START_MEMORY_USED;
string _ENTEST_BENCHMARK_END_TIMESTAMP;
integer _ENTEST_BENCHMARK_END_MEMORY_USED;

integer _ENTEST_BENCHMARK_CYCLES;
integer _ENTEST_BENCHMARK_CYCLES_EXCLUDED;
float _ENTEST_BENCHMARK_OVERHEAD_TIME;
float _ENTEST_BENCHMARK_TIME_MIN;
float _ENTEST_BENCHMARK_TIME_AVG;
float _ENTEST_BENCHMARK_TIME_MAX;
float _ENTEST_BENCHMARK_SR_MIN;
float _ENTEST_BENCHMARK_SR_AVG;
float _ENTEST_BENCHMARK_SR_MAX;
float _ENTEST_BENCHMARK_TD_MIN;
float _ENTEST_BENCHMARK_TD_AVG;
float _ENTEST_BENCHMARK_TD_MAX;

float _ENTEST_BENCHMARK_SR_THRESHOLD;

integer _ENTEST_BENCHMARK_END_CYCLES;
integer _ENTEST_BENCHMARK_END_UNIXTIME;

enTest_BenchmarkStart(
    integer cycles, // cycles before stopping benchmark
    integer seconds, // seconds before stopping benchmark
    float sr_threshold // typically 0.99
)
{
    // initialize globals
    _ENTEST_BENCHMARK_CYCLES = 0;
    _ENTEST_BENCHMARK_CYCLES_EXCLUDED = 0;
    _ENTEST_BENCHMARK_TIME_MIN = 999999.0;
    _ENTEST_BENCHMARK_TIME_AVG = 0.0;
    _ENTEST_BENCHMARK_TIME_MAX = 0.0;
    _ENTEST_BENCHMARK_SR_MIN = 999999.0;
    _ENTEST_BENCHMARK_SR_AVG = 0.0;
    _ENTEST_BENCHMARK_SR_MAX = 0.0;
    _ENTEST_BENCHMARK_TD_MIN = 999999.0;
    _ENTEST_BENCHMARK_TD_AVG = 0.0;
    _ENTEST_BENCHMARK_TD_MAX = 0.0;

    // set scripts run pause threshold
    _ENTEST_BENCHMARK_SR_THRESHOLD = sr_threshold;

    // set end states
    _ENTEST_BENCHMARK_END_CYCLES = cycles;
    _ENTEST_BENCHMARK_END_UNIXTIME = llGetUnixTime() + seconds;

    // start
    _ENTEST_BENCHMARK_RUNNING = TRUE;
    _ENTEST_BENCHMARK_START_TIMESTAMP = llGetTimestamp();
    _ENTEST_BENCHMARK_START_MEMORY_USED = llGetUsedMemory();
}

enTest_BenchmarkEnd() \
{
    _ENTEST_BENCHMARK_END_MEMORY_USED = llGetUsedMemory();
    _ENTEST_BENCHMARK_END_TIMESTAMP = llGetTimestamp();
    _ENTEST_BENCHMARK_RUNNING = FALSE;
}

integer enTest_BenchmarkCycleComplete() \
{
    if (!_ENTEST_BENCHMARK_RUNNING) return TRUE;

    float cycle_time = llGetAndResetTime();

    float sr = llGetSimStats(SIM_STAT_SCRIPT_RUN_PCT);
    if (sr < _ENTEST_BENCHMARK_SR_THRESHOLD)
    { // pause
        enLog_Info("Paused: llGetSimStats(SIM_STAT_SCRIPT_RUN_PCT) = " + (string)sr + "% < " + (string)_ENTEST_BENCHMARK_SR_THRESHOLD + "% (cycle " + (string)_ENTEST_BENCHMARK_CYCLES + " excluded from results)");
        _ENTEST_BENCHMARK_CYCLES_EXCLUDED++;
        do
        {
            llSleep(0.2);
            sr = llGetSimStats(SIM_STAT_SCRIPT_RUN_PCT);
            if (sr >= _ENTEST_BENCHMARK_SR_THRESHOLD) enLog_Info("Resumed: llGetSimStats(SIM_STAT_SCRIPT_RUN_PCT) = " + (string)sr + "% >= " + (string)_ENTEST_BENCHMARK_SR_THRESHOLD + "%");
        }
        while (sr < _ENTEST_BENCHMARK_SR_THRESHOLD);

        float overhead_time = llGetTime();
        _ENTEST_BENCHMARK_OVERHEAD_TIME += overhead_time;
    }
    else
    { // ingest cycle results

        if (sr < _ENTEST_BENCHMARK_SR_MIN) _ENTEST_BENCHMARK_SR_MIN = sr;
        if (sr > _ENTEST_BENCHMARK_SR_MAX) _ENTEST_BENCHMARK_SR_MAX = sr;
        _ENTEST_BENCHMARK_SR_AVG = (_ENTEST_BENCHMARK_SR_AVG * _ENTEST_BENCHMARK_CYCLES + sr) / (_ENTEST_BENCHMARK_CYCLES + 1);

        float td = llGetRegionTimeDilation();
        if (td < _ENTEST_BENCHMARK_TD_MIN) _ENTEST_BENCHMARK_TD_MIN = td;
        if (td > _ENTEST_BENCHMARK_TD_MAX) _ENTEST_BENCHMARK_TD_MAX = td;
        _ENTEST_BENCHMARK_TD_AVG = (_ENTEST_BENCHMARK_TD_AVG * _ENTEST_BENCHMARK_CYCLES + td) / (_ENTEST_BENCHMARK_CYCLES + 1);

        float overhead_time = llGetTime();
        if (cycle_time < _ENTEST_BENCHMARK_TIME_MIN) _ENTEST_BENCHMARK_TIME_MIN = cycle_time;
        if (cycle_time > _ENTEST_BENCHMARK_TIME_MAX) _ENTEST_BENCHMARK_TIME_MAX = cycle_time;
        _ENTEST_BENCHMARK_TIME_AVG = (_ENTEST_BENCHMARK_TIME_AVG * _ENTEST_BENCHMARK_CYCLES + cycle_time) / (_ENTEST_BENCHMARK_CYCLES + 1);
    }

    _ENTEST_BENCHMARK_CYCLES++;

    llResetTime();

    if (_ENTEST_BENCHMARK_END_CYCLES)
    { // check that we haven't exceeded the maximum cycles
        if (_ENTEST_BENCHMARK_CYCLES >= _ENTEST_BENCHMARK_END_CYCLES)
        {
            enTest_BenchmarkEnd();
            return TRUE;
        }
    }
    if (llGetUnixTime() > _ENTEST_BENCHMARK_END_UNIXTIME) 
    {
        enTest_BenchmarkEnd();
        return TRUE;
    }
    return FALSE;
}

enTest_BenchmarkResults() \
{
    float seconds = enDatetime_TimestampDiffToSecondsPrecise(_ENTEST_BENCHMARK_START_TIMESTAMP, _ENTEST_BENCHMARK_END_TIMESTAMP);

    integer mb_change = _ENTEST_BENCHMARK_END_MEMORY_USED - _ENTEST_BENCHMARK_START_MEMORY_USED;

    enLog_Print("== enTest Benchmark Results =="
        + "\nCycle time: " + (string)_ENTEST_BENCHMARK_TIME_MIN + " s min, " + (string)_ENTEST_BENCHMARK_TIME_AVG + " s avg, " + (string)_ENTEST_BENCHMARK_TIME_MAX + " s max"
        + "\nMemory used: " + (string)_ENTEST_BENCHMARK_START_MEMORY_USED + " B start, " + (string)_ENTEST_BENCHMARK_END_MEMORY_USED + " B end, " + enString_If(mb_change >= 0, "+", "") + (string)mb_change + " B change"
        + "\nScripts run: " + (string)_ENTEST_BENCHMARK_SR_MIN + "% min, " + (string)_ENTEST_BENCHMARK_SR_AVG + "% avg, " + (string)_ENTEST_BENCHMARK_SR_MAX + "% max"
        + "\nTime dilation: " + (string)_ENTEST_BENCHMARK_TD_MIN + " min, " + (string)_ENTEST_BENCHMARK_TD_AVG + " avg, " + (string)_ENTEST_BENCHMARK_TD_MAX + " max"
        + "\nCycles completed: " + (string)(_ENTEST_BENCHMARK_CYCLES - _ENTEST_BENCHMARK_CYCLES_EXCLUDED) + " included, " + (string)_ENTEST_BENCHMARK_CYCLES_EXCLUDED + " excluded"
        + "\nllGetTimestamp(): " + (string)_ENTEST_BENCHMARK_START_TIMESTAMP + " start, " + (string)_ENTEST_BENCHMARK_END_TIMESTAMP + " end"
        + "\nTotal time: " + (string)(seconds - _ENTEST_BENCHMARK_OVERHEAD_TIME) + " s running, " + (string)_ENTEST_BENCHMARK_OVERHEAD_TIME + " s overhead/paused"
        + "\nllGetRegionName(): " + llGetRegionName()
        + "\nllGetEnv(\"sim_channel\"): " + llGetEnv("sim_channel")
        + "\nllGetEnv(\"sim_version\"): " + llGetEnv("sim_version")
        + "\nllGetEnv(\"region_cpu_ratio\"): " + llGetEnv("region_cpu_ratio")
        + "\nllGetEnv(\"region_product_name\"): " + llGetEnv("region_product_name")
        + "\nllGetEnv(\"simulator_hostname\"): " + llGetEnv("simulator_hostname")
        + "\nllGetEnv(\"grid\"): " + llGetEnv("grid")
        + "\nBenchmark report generated: " + llGetTimestamp()
    );
}
