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
we always have a state_entry(), so there's no need to do _EVENT or _HOOK definitions - let the individual modules handle everything
*/
	state_entry()
	{
        #if defined TRACE_EVENT_STATE_ENTRY
            enLog_TraceParams("state_entry", [], []);
        #endif

        // enPrim_StopIfFlagged(), enPrim_StopIfOwnerRezzed(), enPrim_UpdateUUIDs(), enPrim_AlwaysPhantom()
        _enPrim_state_entry(); // highest priority - do not run any state_entry() handlers before this

        // pass to user-defined function if requested
		#if defined EVENT_EN_STATE_ENTRY
			en_state_entry();
		#endif
	}
