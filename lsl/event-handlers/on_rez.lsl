/*
En LSL Framework
Copyright (C) 2024-25  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework

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

/*
we always have an on_rez(), so there's no need to do _EVENT or _HOOK definitions - let the individual modules handle everything
*/
on_rez(integer param)
{
    #if defined TRACE_EVENT_ON_REZ
        enLog_TraceParams(
            "on_rez",
            [
                "param"
            ],
            [
                param
            ]
        );
    #endif

    _enPrim_on_rez(param); // highest priority - do not run any on_rez() handlers before this
    _enLNX_on_rez(param);

    #if defined EVENT_EN_ON_REZ
        en_on_rez(param);
    #endif
}
