// Potato
/obj/item/seeds/potato
	name = "pack of potato seeds"
	desc = "Boil 'em! Mash 'em! Stick 'em in a stew!"
	icon_state = "seed-potato"
	species = "potato"
	plantname = "Potato Plants"
	product = /obj/item/weapon/reagent_containers/food/snacks/grown/potato
	lifespan = 30
	maturation = 10
	production = 1
	yield = 4
	growthstages = 4
	growing_icon = 'icons/obj/hydroponics/growing_vegetables.dmi'
	icon_grow = "potato-grow"
	icon_dead = "potato-dead"
	genes = list(/datum/plant_gene/trait/battery)
	mutatelist = list(/obj/item/seeds/potato/sweet,/obj/item/seeds/flashtato)
	reagents_add = list("vitamin" = 0.04, "plantmatter" = 0.1)

/obj/item/weapon/reagent_containers/food/snacks/grown/potato
	seed = /obj/item/seeds/potato
	name = "potato"
	desc = "Boil 'em! Mash 'em! Stick 'em in a stew!"
	icon_state = "potato"
	filling_color = "#E9967A"
	bitesize = 100


/obj/item/weapon/reagent_containers/food/snacks/grown/potato/wedges
	name = "potato wedges"
	desc = "Slices of neatly cut potato."
	icon_state = "potato_wedges"
	filling_color = "#E9967A"
	bitesize = 100


/obj/item/weapon/reagent_containers/food/snacks/grown/potato/attackby(obj/item/weapon/W, mob/user, params)
	if(is_sharp(W))
		to_chat(user, "<span class='notice'>You cut the potato into wedges with [W].</span>")
		var/obj/item/weapon/reagent_containers/food/snacks/grown/potato/wedges/Wedges = new /obj/item/weapon/reagent_containers/food/snacks/grown/potato/wedges
		if(!remove_item_from_storage(user))
			user.unEquip(src)
		user.put_in_hands(Wedges)
		qdel(src)
	else
		return ..()

/obj/item/seeds/flashtato
	name = "pack of flashtato seeds"
	desc = "The power of starch blinds you!"
	icon_state = "seed-potato"
	species = "flashtato"
	plantname = "Flashtato Plants"
	product = /obj/item/weapon/reagent_containers/food/snacks/grown/flashtato
	lifespan = 40
	maturation = 20
	production = 1
	yield = 4
	growthstages = 4
	growing_icon = 'icons/obj/hydroponics/growing_vegetables.dmi'
	icon_grow = "potato-grow"
	icon_dead = "potato-dead"
	genes = list(/datum/plant_gene/trait/battery)
	mutatelist = list(/obj/item/seeds/potato/sweet,/obj/item/seeds/flashtato)
	reagents_add = list("vitamin" = 0.4, "plantmatter" = 0.2, "iron" = 0.05)

/obj/item/weapon/reagent_containers/food/snacks/grown/flashtato
	seed = /obj/item/seeds/potato
	name = "flashtato"
	desc = "Just an ordinary flashbang."
	icon_state = "flashtato"
	filling_color = "#E9927A"
	bitesize = 20
	light_power = 10
	light_color = LIGHT_COLOR_WHITE
	var/light_time = 2
	var/power = 0


/obj/item/weapon/reagent_containers/food/snacks/grown/flashtato/attack_self(mob/living/user)
	var/area/A = get_area(user)
	user.visible_message("<span class='warning'>[user] primes the [src]!</span>", "<span class='userdanger'>You prime the [src]!</span>")
	var/message = "[ADMIN_LOOKUPFLW(user)] primed a flashtato for detonation at [A] [ADMIN_COORDJMP(user)]"
	bombers += message
	message_admins(message)
	log_game("[key_name(user)] primed a flashtato for detonation at [A] [COORD(user)].")
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.throw_mode_on()
	icon_state = "flashtato_active"
	playsound(loc, 'sound/weapons/armbomb.ogg', 75, 1, -3)
	addtimer(src, "prime", rand(10, 50))

/obj/item/weapon/reagent_containers/food/snacks/grown/flashtato/burn()
	prime()
	..()

/obj/item/weapon/reagent_containers/food/snacks/grown/flashtato/proc/update_mob()
	if(ismob(loc))
		var/mob/M = loc
		M.unEquip(src)

/obj/item/weapon/reagent_containers/food/snacks/grown/flashtato/proc/prime()
	switch(seed.potency)
		if(0 to 30)
			update_mob()
			power = 1
		if(31 to 50)
			update_mob()
			power = 2
		if(51 to 70)
			update_mob()
			power = 3
		if(71 to 90)
			update_mob()
			power = 5
		else
			update_mob()
			power = 8
	update_mob()
	var/flashbang_turf = get_turf(src)
	if(!flashbang_turf)
		return

	set_light(7)

	for(var/mob/living/M in hearers(7, flashbang_turf))
		bang(get_turf(M), M)

	for(var/obj/structure/blob/B in hear(8,flashbang_turf))     		//Blob damage here
		var/damage = round(30/(get_dist(B,get_turf(src))+1))
		B.health -= damage
		B.update_icon()

	spawn(light_time)
		qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/grown/flashtato/proc/bang(var/turf/T , var/mob/living/M)
	M.show_message("<span class='warning'>BANG</span>", 2)
	playsound(loc, 'sound/effects/bang.ogg', 25, 1)

//Checking for protections
	var/ear_safety = M.check_ear_prot()
	var/distance = max(1,get_dist(src,T))

//Flash
	if(M.weakeyes)
		M.visible_message("<span class='disarm'><b>[M]</b> screams and collapses!</span>")
		to_chat(M, "<span class='userdanger'><font size=3>AAAAGH!</font></span>")
		M.Weaken(2*power) //hella stunned
		M.Stun(2*power)
		if(ishuman(M))
			M.emote("scream")
			var/mob/living/carbon/human/H = M
			var/obj/item/organ/internal/eyes/E = H.get_int_organ(/obj/item/organ/internal/eyes)
			if(E)
				E.receive_damage(8, 1)

	if(M.flash_eyes(affect_silicon = 1))
		M.Stun(max(10/distance, 3))
		M.Weaken(max(10/distance, 3))


//Bang
	if((loc == M) || loc == M.loc)//Holding on person or being exactly where lies is significantly more dangerous and voids protection
		M.Stun(1.5*power)
		M.Weaken(1.5*power)
	if(!ear_safety)
		M.Stun(max(10/distance, 3))
		M.Weaken(max(10/distance, 3))
		M.EarDeaf(2*power)
		M.AdjustEarDamage(rand(0, power))
		if(M.ear_damage >= 15)
			to_chat(M, "<span class='warning'>Your ears start to ring badly!</span>")
			if(prob(M.ear_damage - 5))
				to_chat(M, "<span class='warning'>You can't hear anything!</span>")
				M.BecomeDeaf()
		else
			if(M.ear_damage >= 5)
				to_chat(M, "<span class='warning'>Your ears start to ring!</span>")

// Sweet Potato
/obj/item/seeds/potato/sweet
	name = "pack of sweet potato seeds"
	desc = "These seeds grow into sweet potato plants."
	icon_state = "seed-sweetpotato"
	species = "sweetpotato"
	plantname = "Sweet Potato Plants"
	product = /obj/item/weapon/reagent_containers/food/snacks/grown/potato/sweet
	mutatelist = list()
	reagents_add = list("vitamin" = 0.1, "sugar" = 0.1, "plantmatter" = 0.1)

/obj/item/weapon/reagent_containers/food/snacks/grown/potato/sweet
	seed = /obj/item/seeds/potato/sweet
	name = "sweet potato"
	desc = "It's sweet."
	icon_state = "sweetpotato"
