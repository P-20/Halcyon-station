/obj/item/device/handcloset
	name = "pizza box"
	desc = "It's a pizza box with a lot of extra space."
	icon = 'icons/obj/closet.dmi'
	icon_state = "handclosetclosed"
	density = 1
	var/icon_closed = "handclosetclosed"
	var/icon_opened = "handclosetopen"
	var/opened = 0
	var/locked = 0
	var/broken = 0
	var/wall_mounted = 0 //never solid (You can always pass over it)
	var/lastbang
	var/cutting_tool = /obj/item/weapon/weldingtool
	var/sound = 'sound/items/bikehorn.ogg'
	var/cutting_sound
	var/storage_capacity = 30 //This is so that someone can't pack hundreds of items in a locker/crate then open it in a populated area to crash clients.
	var/material_drop = /obj/item/stack/sheet/metal
	var/material_drop_amount = 2

/obj/item/device/handcloset/New()
	..()
	spawn(1)
		if(!opened)		// if closed, any item at the crate's loc is put in the contents
			for(var/obj/item/I in loc)
				if(I.density || I.anchored || I == src) continue
				I.forceMove(src)

// Fix for #383 - C4 deleting fridges with corpses
/obj/item/device/handcloset/Destroy()
	dump_contents()
	return ..()

/obj/item/device/handcloset/CanPass(atom/movable/mover, turf/target, height=0)
	if(height==0 || wall_mounted) return 1
	return (!density)

/obj/item/device/handcloset/proc/can_close()
	for(var/obj/item/device/handcloset/closet in get_turf(src))
		if(closet != src && closet.anchored != 1)
			return 0
	return 1

/obj/item/device/handcloset/proc/dump_contents()
	var/turf/T = get_turf(src)
	for(var/atom/movable/AM in src)
		AM.forceMove(T)
		if(throwing) // you keep some momentum when getting out of a thrown closet
			step(AM, dir)
	if(throwing)
		throwing.finalize(FALSE)

/obj/item/device/handcloset/proc/open()
	if(opened)
		return 0

	dump_contents()

	icon_state = icon_opened
	anchored = 1
	opened = 1
	if(sound)
		playsound(loc, sound, 15, 1, -3)
	else
		playsound(loc, 'sound/items/bikehorn.ogg', 15, 1, -3)
	density = 0
	return 1

/obj/item/device/handcloset/proc/close()
	if(!opened)
		return 0
	if(!can_close())
		return 0
	anchored = 0

	var/itemcount = 0

	//Cham Projector Exception
	for(var/obj/effect/dummy/chameleon/AD in loc)
		if(itemcount >= storage_capacity)
			break
		AD.forceMove(src)
		itemcount++

	for(var/obj/item/I in loc)
		if(itemcount >= storage_capacity)
			break
		if(!I.anchored)
			I.forceMove(src)
			itemcount++

	for(var/mob/M in loc)
		if(itemcount >= storage_capacity)
			break
		if(istype (M, /mob/dead/observer))
			continue
		if(M.buckled)
			continue

		M.forceMove(src)
		itemcount++

	icon_state = icon_closed
	opened = 0
	if(sound)
		playsound(loc, sound, 15, 1, -3)
	else
		playsound(loc, 'sound/items/zip.ogg', 15, 1, -3)
	density = 1
	return 1

/obj/item/device/handcloset/proc/toggle(mob/user)
	if(!(opened ? close() : open()))
		to_chat(user, "<span class='notice'>It won't budge!</span>")

// this should probably use dump_contents()
/obj/item/device/handcloset/ex_act(severity)
	switch(severity)
		if(1)
			for(var/atom/movable/A in src)//pulls everything out of the locker and hits it with an explosion
				A.forceMove(loc)
				A.ex_act(severity++)
			qdel(src)
		if(2)
			if(prob(50))
				for(var/atom/movable/A in src)
					A.forceMove(loc)
					A.ex_act(severity++)
				new /obj/item/stack/sheet/metal(loc)
				qdel(src)
		if(3)
			if(prob(5))
				for(var/atom/movable/A in src)
					A.forceMove(loc)
					A.ex_act(severity++)
				new /obj/item/stack/sheet/metal(loc)
				qdel(src)

/obj/item/device/handcloset/bullet_act(var/obj/item/projectile/Proj)
	..()
	playsound(loc, 'sound/items/bubblewrap.ogg', 75, 1)

/obj/item/device/handcloset/attack_animal(mob/living/simple_animal/user)
	if(user.environment_smash)
		user.do_attack_animation(src)
		visible_message("<span class='warning'>[user] destroys the [src].</span>")
		for(var/atom/movable/A in src)
			A.forceMove(loc)
		qdel(src)

obj/item/device/handcloset/MouseDrop(atom/over_object)
	var/mob/M = usr
	if(usr.stat || !ishuman(usr) || !usr.canmove || usr.restrained())
		return
	if(Adjacent(usr))
		if(over_object == M  && loc != M)
			close()
			M.put_in_hands(src)

		else if(istype(over_object, /obj/screen))
			switch(over_object.name)
				if("l_hand")
					if(!remove_item_from_storage(M))
						M.unEquip(src)
					close()
					M.put_in_l_hand(src)
				if("r_hand")
					if(!remove_item_from_storage(M))
						M.unEquip(src)
					close()
					M.put_in_r_hand(src)
	else
		to_chat(usr, "<span class='notice'>You can't reach it from here.</span>")

// this should probably use dump_contents()
/obj/item/device/handcloset/blob_act()
	if(prob(75))
		for(var/atom/movable/A in src)
			A.forceMove(loc)
		qdel(src)

/obj/item/device/handcloset/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W, /obj/item/weapon/rcs) && !opened)
		if(user in contents) //to prevent self-teleporting.
			return
		var/obj/item/weapon/rcs/E = W
		if(E.rcell && (E.rcell.charge >= E.chargecost))
			if(!is_level_reachable(z))
				to_chat(user, "<span class='warning'>The rapid-crate-sender can't locate any telepads!</span>")
				return
			if(E.mode == 0)
				if(!E.teleporting)
					var/list/L = list()
					var/list/areaindex = list()
					for(var/obj/machinery/telepad_cargo/R in world)
						if(R.stage == 0)
							var/turf/T = get_turf(R)
							var/tmpname = T.loc.name
							if(areaindex[tmpname])
								tmpname = "[tmpname] ([++areaindex[tmpname]])"
							else
								areaindex[tmpname] = 1
							L[tmpname] = R
					var/desc = input("Please select a telepad.", "RCS") in L
					E.pad = L[desc]
					if(!Adjacent(user))
						to_chat(user, "<span class='notice'>Unable to teleport, too far from crate.</span>")
						return
					playsound(E.loc, E.usesound, 50, 1)
					to_chat(user, "<span class='notice'>Teleporting [name]...</span>")
					E.teleporting = 1
					if(!do_after(user, 50 * E.toolspeed, target = src))
						E.teleporting = 0
						return
					E.teleporting = 0
					if(user in contents)
						to_chat(user, "<span class='warning'>Error: User located in container--aborting for safety.</span>")
						playsound(E.loc, 'sound/machines/buzz-sigh.ogg', 50, 1)
						return
					if(!(E.rcell && E.rcell.use(E.chargecost)))
						to_chat(user, "<span class='notice'>Unable to teleport, insufficient charge.</span>")
						return
					var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
					s.set_up(5, 1, src)
					s.start()
					do_teleport(src, E.pad, 0)
					to_chat(user, "<span class='notice'>Teleport successful. [round(E.rcell.charge/E.chargecost)] charge\s left.</span>")
					return
			else
				E.rand_x = rand(50,200)
				E.rand_y = rand(50,200)
				var/L = locate(E.rand_x, E.rand_y, 6)
				if(!Adjacent(user))
					to_chat(user, "<span class='notice'>Unable to teleport, too far from crate.</span>")
					return
				playsound(E.loc, E.usesound, 50, 1)
				to_chat(user, "<span class='notice'>Teleporting [name]...</span>")
				E.teleporting = 1
				if(!do_after(user, 50, E.toolspeed, target = src))
					E.teleporting = 0
					return
				E.teleporting = 0
				if(user in contents)
					to_chat(user, "<span class='warning'>Error: User located in container--aborting for safety.</span>")
					playsound(E.loc, 'sound/machines/buzz-sigh.ogg', 50, 1)
					return
				if(!(E.rcell && E.rcell.use(E.chargecost)))
					to_chat(user, "<span class='notice'>Unable to teleport, insufficient charge.</span>")
					return
				var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
				s.set_up(5, 1, src)
				s.start()
				do_teleport(src, L)
				to_chat(user, "<span class='notice'>Teleport successful. [round(E.rcell.charge/E.chargecost)] charge\s left.</span>")
				return
		else
			to_chat(user, "<span class='warning'>Out of charges.</span>")
			return

	if(opened)
		if(istype(W, /obj/item/weapon/grab))
			MouseDrop_T(W:affecting, user)      //act like they were dragged onto the closet
		if(istype(W,/obj/item/tk_grab))
			return 0
		if(istype(W, cutting_tool))
			if(istype(W, /obj/item/weapon/weldingtool))
				var/obj/item/weapon/weldingtool/WT = W
				if(!WT.remove_fuel(0, user))
					return
				to_chat(user, "<span class='notice'>You begin cutting \the [src] apart...</span>")
				playsound(loc, cutting_sound ? cutting_sound : WT.usesound, 40, 1)
				if(do_after(user, 40 * WT.toolspeed, 1, target = src))
					if(!opened || !WT.isOn())
						return
					playsound(loc, cutting_sound ? cutting_sound : WT.usesound, 50, 1)
					visible_message("<span class='notice'>[user] slices apart \the [src].</span>",
									"<span class='notice'>You cut \the [src] apart with \the [WT].</span>",
									"<span class='italics'>You hear welding.</span>")
					var/turf/T = get_turf(src)
					new material_drop(T, material_drop_amount)
					qdel(src)
					return
		if(isrobot(user))
			return
		if(!user.drop_item()) //couldn't drop the item
			to_chat(user, "<span class='notice'>\The [W] is stuck to your hand, you cannot put it in \the [src]!</span>")
			return
		if(W)
			W.forceMove(loc)
	else if(istype(W, /obj/item/stack/packageWrap))
		return
	else
		attack_hand(user)

/obj/item/device/handcloset/MouseDrop_T(atom/movable/O, mob/user)
	..()
	if(istype(O, /obj/screen))	//fix for HUD elements making their way into the world	-Pete
		return
	if(O.loc == user)
		return
	if(user.restrained() || user.stat || user.weakened || user.stunned || user.paralysis || user.lying)
		return
	if((!( istype(O, /atom/movable) ) || O.anchored || get_dist(user, src) > 1 || get_dist(user, O) > 1 || user.contents.Find(src)))
		return
	if(user.loc==null) // just in case someone manages to get a closet into the blue light dimension, as unlikely as that seems
		return
	if(!istype(user.loc, /turf)) // are you in a container/closet/pod/etc?
		return
	if(!opened)
		return
	if(istype(O, /obj/item/device/handcloset))
		return
	step_towards(O, loc)
	if(user != O)
		user.visible_message("<span class='danger'>[user] stuffs [O] into [src]!</span>", "<span class='danger'>You stuff [O] into [src]!</span>")
	add_fingerprint(user)

/obj/item/device/handcloset/attack_ai(mob/user)
	if(isrobot(user) && Adjacent(user)) //Robots can open/close it, but not the AI
		attack_hand(user)

/obj/item/device/handcloset/relaymove(mob/user)
	if(user.stat || !isturf(loc))
		return

	if(!open())
		to_chat(user, "<span class='notice'>It won't budge!</span>")
		if(!lastbang)
			lastbang = 1
			for(var/mob/M in hearers(src, null))
				to_chat(M, text("<FONT size=[]>BANG, bang!</FONT>", max(0, 5 - get_dist(src, M))))
			spawn(30)
				lastbang = 0

/obj/item/device/handcloset/attack_hand(mob/user)
	if(user.is_in_inactive_hand(src))
		return
	else
		add_fingerprint(user)
		toggle(user)

/obj/item/device/handcloset/attack_self(mob/user, params)
	if(user.drop_item())
		Move(user.loc)
		//var/list/click_params = params2list(params)
		//if(!click_params || !click_params["icon-x"] || !click_params["icon-y"])
			//return
		//Clamp it so that the icon never moves more than 16 pixels in either direction (thus leaving the turf)
		//pixel_x = Clamp(text2num(click_params["icon-x"]) - 16, -(world.icon_size/2), world.icon_size/2)
		//pixel_y = Clamp(text2num(click_params["icon-y"]) - 16, -(world.icon_size/2), world.icon_size/2)
		open()
		to_chat(user, "<span class='notice'>You put [src] on the ground and open it.</span>")


/obj/item/device/handcloset/attack_ghost(mob/user)
	if(user.can_advanced_admin_interact())
		toggle(user)

// tk grab then use on self
/obj/item/device/handcloset/attack_self_tk(mob/user)
	add_fingerprint(user)
	if(!toggle())
		to_chat(usr, "<span class='notice'>It won't budge!</span>")

/obj/item/device/handcloset/verb/verb_toggleopen()
	set src in oview(1)
	set category = null
	set name = "Toggle Open"

	if(usr.incapacitated())
		return

	if(ishuman(usr))
		add_fingerprint(usr)
		toggle(usr)
	else
		to_chat(usr, "<span class='warning'>This mob type can't use this verb.</span>")

/obj/item/device/handcloset/update_icon()
	overlays.Cut()
	if(!opened)
		icon_state = icon_closed
	else
		icon_state = icon_opened

// Objects that try to exit a locker by stepping were doing so successfully,
// and due to an oversight in turf/Enter() were going through walls.  That
// should be independently resolved, but this is also an interesting twist.
/obj/item/device/handcloset/Exit(atom/movable/AM)
	open()
	if(AM.loc == src) return 0
	return 1

/obj/item/device/handcloset/container_resist(var/mob/living/L)
	var/breakout_time = 2 //2 minutes by default
	if(opened)
		if(L.loc == src)
			L.forceMove(get_turf(src)) // Let's just be safe here
		return //Door's open... wait, why are you in it's contents then?
	//	else Meh, lets just keep it at 2 minutes for now
	//okay, so the closet is locked... resist!!!
	L.changeNext_move(CLICK_CD_BREAKOUT)
	L.last_special = world.time + CLICK_CD_BREAKOUT
	to_chat(L, "<span class='warning'>You lean on the back of \the [src] and start pushing the door open. (this will take about [breakout_time] minutes)</span>")
	for(var/mob/O in viewers(usr.loc))
		O.show_message("<span class='danger'>The [src] begins to shake violently!</span>", 1)


	spawn(0)
		if(do_after(L,(breakout_time*60*10), target = src)) //minutes * 60seconds * 10deciseconds
			if(!src || !L || L.stat != CONSCIOUS || L.loc != src || opened) //closet/user destroyed OR user dead/unconcious OR user no longer in closet OR closet opened
				return

			//Perform the same set of checks as above for weld and lock status to determine if there is even still a point in 'resisting'...

			if(istype(loc, /obj/structure/bigDelivery)) //nullspace ect.. read the comment above
				var/obj/structure/bigDelivery/BD = loc
				BD.attack_hand(usr)
			open()

/obj/item/device/handcloset/tesla_act(var/power)
	..()
	visible_message("<span class='danger'>[src] is blown apart by the bolt of electricity!</span>")
	qdel(src)

/obj/item/device/handcloset/get_remote_view_fullscreens(mob/user)
	if(user.stat == DEAD || !(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /obj/screen/fullscreen/impaired, 1)