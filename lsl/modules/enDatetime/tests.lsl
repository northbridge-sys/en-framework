/*
enDatetime
Copyright (C) 2025  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework

These tests are to check various enDatetime functions.
*/

/*
This one clearly doesn't work
*/
integer _enDatetime_Test_AddMillisec()
{
    // check that enDatetime_AddMillisec correctly handles month rollover
    string ts_a = "2020-01-31T23:59:59.999999Z";
    string ts_b = "2020-02-01T00:00:00.000000Z";
    integer ms_a = enDatetime_TimestampToMillisec(ts_a);
    integer ms_b = enDatetime_TimestampToMillisec(ts_b);
    integer ms_diff_fwd = enDatetime_AddMillisec(-ms_a, ms_b);
    integer ms_diff_rev = enDatetime_AddMillisec(ms_a, -ms_b);
    enLog_Print(enList_Elem([ts_a, ts_b, ms_a, ms_b, ms_diff_fwd, ms_diff_rev]));
    return 0;
}
