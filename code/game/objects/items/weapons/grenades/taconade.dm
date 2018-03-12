
/obj/item/weapon/grenade/taconade
	name = "taconade"
	desc = "A magic grenade."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/grenade.dmi'
	icon_state = "banana"
	item_state = "flashbang"
	var/deliveryamt = 8
	var/spawner_type = /obj/item/weapon/reagent_containers/food/snacks/taco/magic

/obj/item/weapon/grenade/taconade/prime()
	if(spawner_type && deliveryamt)
		// Make a quick flash
		var/turf/T = get_turf(src)
		playsound(T, 'sound/items/bikehorn.ogg', 100, 1)
		for(var/mob/living/carbon/C in viewers(T, null))
			C.flash_eyes()
		for(var/i=1, i<=deliveryamt, i++)
			var/atom/movable/x = new spawner_type
			x.loc = T
			if(prob(50))
				for(var/j = 1, j <= rand(1, 3), j++)
					step(x, pick(NORTH,SOUTH,EAST,WEST))



	qdel(src)
	return

/obj/item/weapon/grenade/taconade/casing
	name = "tortilla casing"
	desc = "A grenade casing made of tortillas."
	icon_state = "banana_casing"
	var/fillamt = 0


/obj/item/weapon/grenade/taconade/casing/attackby(var/obj/item/I, mob/user as mob, params)
	if(istype(I, /obj/item/weapon/reagent_containers/food/snacks/taco))
		if(fillamt < 9)
			to_chat(usr, "<span  class='notice'>You add another taco to the assembly.</span>")
			fillamt += 1
			qdel(I)
		else
			to_chat(usr, "<span class='notice'>The taconade is full, screwdriver it shut to lock it down.</span>")
	if(istype(I, /obj/item/weapon/screwdriver))
		if(fillamt)
			var/obj/item/weapon/grenade/taconade/G = new /obj/item/weapon/grenade/taconade
			user.unEquip(src)
			user.put_in_hands(G)
			G.deliveryamt = src.fillamt
			to_chat(user, "<span  class='notice'>You lock the assembly shut, readying it for MMMM.</span>")
			qdel(src)
		else
			to_chat(usr, "<span class='notice'>You need to add tacos before you can ready the grenade!.</span>")
	else
		to_chat(usr, "<span class='notice'>Only tacos fit in this assembly, up to 9.</span>")
