GLOBAL_LIST_INIT(valid_keys, list(
	"F1" = 1,
	"F2" = 1,
	"F3" = 1,
	"F4" = 1,
	"F5" = 1,
	"F6" = 1,
	"F7" = 1,
	"F8" = 1,
	"F9" = 1,
	"F10" = 1,
	"F11" = 1,
	"F12" = 1,
	"A" = 1,
	"B" = 1,
	"C" = 1,
	"D" = 1,
	"E" = 1,
	"F" = 1,
	"G" = 1,
	"H" = 1,
	"I" = 1,
	"J" = 1,
	"K" = 1,
	"L" = 1,
	"M" = 1,
	"N" = 1,
	"O" = 1,
	"P" = 1,
	"Q" = 1,
	"R" = 1,
	"S" = 1,
	"T" = 1,
	"U" = 1,
	"V" = 1,
	"W" = 1,
	"X" = 1,
	"Y" = 1,
	"Z" = 1,
	"0" = 1,
	"1" = 1,
	"2" = 1,
	"3" = 1,
	"4" = 1,
	"5" = 1,
	"6" = 1,
	"7" = 1,
	"8" = 1,
	"9" = 1,
	"-" = 1,
	"=" = 1,
	"\[" = 1,
	"\]" = 1,
	"\\" = 1,
	"." = 1,
	"/" = 1,
	"`" = 1,
	"Capslock" = 1,
	"Numpad0" = 1,
	"Numpad1" = 1,
	"Numpad2" = 1,
	"Numpad3" = 1,
	"Numpad4" = 1,
	"Numpad5" = 1,
	"Numpad6" = 1,
	"Numpad7" = 1,
	"Numpad8" = 1,
	"Numpad9" = 1,
	"North" = 1,
	"South" = 1,
	"East" = 1,
	"West" = 1,
	"Northwest" = 1,
	"Southwest" = 1,
	"Northeast" = 1,
	"Southeast" = 1,
	"Center" = 1,
	"Return" = 1,
	"Escape" = 1,
	"Tab" = 1,
//	"Space" = 1,
	"Back" = 1,
	"Insert" = 1,
	"Delete" = 1,
	"Pause" = 1,
	"Snapshot" = 1,
	"LWin" = 1,
	"RWin" = 1,
	"Apps" = 1,
	"Multiply" = 1,
	"Add" = 1,
	"Subtract" = 1,
	"Divide" = 1,
	"Separator" = 1,
	"Decimal" = 1,
	"Shift" = 1,
	"Ctrl" = 1,
	"Numlock" = 1,
	"Scroll" = 1,
	"Alt" = 1
))

// Clients aren't datums so we have to define these procs indpendently.
// These verbs are called for all key press and release events
/client/verb/keyDown(_key as text)
	set instant = TRUE
	set hidden = TRUE

	client_keysend_amount += 1

	var/cache = client_keysend_amount

	if(keysend_tripped && next_keysend_trip_reset <= world.time)
		keysend_tripped = FALSE

	if(next_keysend_reset <= world.time)
		client_keysend_amount = 0
		next_keysend_reset = world.time + (1 SECONDS)

	if(cache >= MAX_KEYPRESS_AUTOKICK)
		if(!keysend_tripped)
			keysend_tripped = TRUE
			next_keysend_trip_reset = world.time + (2 SECONDS)
		else
			log_admin("Client [ckey] was just autokicked for flooding keysends; likely abuse but potentially lagspike.")
			message_admins("Client [ckey] was just autokicked for flooding keysends; likely abuse but potentially lagspike.")
			QDEL_IN(src, 1)
			return
		//check if the keycommand is even valid before firing it through the full chain

	if(!GLOB.valid_keys[_key])
		//Sanity check, nothing valid in game generates keypress "keys" this long
		//Means it's some kind of bullshit going on, so get rid of them.
		var/kicked = FALSE
		if(length(_key) > MAX_KEYPRESS_COMMANDLENGTH)
			QDEL_IN(src, 10)
			kicked = TRUE
		var/message = "Client [ckey] just attempted to send an invalid keypress."
		if(kicked)
			message += " Keymessage was over [MAX_KEYPRESS_COMMANDLENGTH] characters, autokicking due to likely abuse."
		else
			message += " Keymessage was \"[_key]\", report this!"
		log_admin(message)
		message_admins(message)
		//No matter what, reject the message.
		return



	keys_held[_key] = world.time
	var/movement = SSinput.movement_keys[_key]
	if(!(next_move_dir_sub & movement) && !keys_held["Ctrl"])
		next_move_dir_add |= movement

	// Client-level keybindings are ones anyone should be able to do at any time
	// Things like taking screenshots, hitting tab, and adminhelps.

	switch(_key)
		if("F1")
			if(keys_held["Ctrl"] && keys_held["Shift"]) // Is this command ever used?
				winset(src, null, "command=.options")
			else
				get_adminhelp()
			return
		if("F2") // Screenshot. Hold shift to choose a name and location to save in
			winset(src, null, "command=.screenshot [!keys_held["shift"] ? "auto" : ""]")
			return
		if("F12") // Toggles minimal HUD
			mob.button_pressed_F12()
			return

	if(holder)
		holder.key_down(_key, src)
	if(mob.focus)
		mob.focus.key_down(_key, src)

/client/verb/keyUp(_key as text)
	set instant = TRUE
	set hidden = TRUE

	keys_held -= _key
	var/movement = SSinput.movement_keys[_key]
	if(!(next_move_dir_add & movement))
		next_move_dir_sub |= movement

	if(holder)
		holder.key_up(_key, src)
	if(mob.focus)
		mob.focus.key_up(_key, src)

// Called every game tick
/client/keyLoop()
	if(holder)
		holder.keyLoop(src)
	if(mob.focus)
		mob.focus.keyLoop(src)