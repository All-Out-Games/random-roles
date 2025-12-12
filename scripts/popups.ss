import "core:core.ss"

POPUP_DURATION: float : 5.0;
SCROLL_DURATION: float : 2.0;

Body_Found_Popup :: class {

	banner_texture: Texture_Asset;
	text_texture: Texture_Asset;
	ground_texture: Texture_Asset;
	body_texture: Texture_Asset;
	
	is_visible: bool;
	show_start_time: float;
	
	init :: proc(using this: Body_Found_Popup) {
		banner_texture = get_asset(Texture_Asset, "sprites/icons/Body Found/banner.png");
		text_texture = get_asset(Texture_Asset, "sprites/icons/Body Found/text.png");
		ground_texture = get_asset(Texture_Asset, "sprites/icons/Body Found/ground.png");
		body_texture = get_asset(Texture_Asset, "sprites/icons/Body Found/schleem.png");
		is_visible = false;
		show_start_time = 0.0;
	}

	show :: proc(using this: Body_Found_Popup) {
		is_visible = true;
		show_start_time = get_time();
	}

	hide :: proc(using this: Body_Found_Popup) {
		is_visible = false;
	}

	is_finished :: proc(using this: Body_Found_Popup) -> bool {
		if !is_visible { return true; }
		elapsed := get_time() - show_start_time;
		return elapsed >= POPUP_DURATION;
	}

	update :: proc(using this: Body_Found_Popup, delta_time: float) {
		if !is_visible { return; }
		
		elapsed := get_time() - show_start_time;
		
		// Auto-hide after duration
		if elapsed >= POPUP_DURATION {
			is_visible = false;
			return;
		}
		
		render_popup(this, elapsed);
	}
}

// Separate function to render the popup with scroll effects
render_popup :: proc(using popup: Body_Found_Popup, elapsed: float) {

	banner_progress := clamp((elapsed - 0.0) / SCROLL_DURATION, 0.0, 1.0);
	text_progress := clamp((elapsed - 0.2) / SCROLL_DURATION, 0.0, 1.0);
	ground_progress := clamp((elapsed - 0.4) / SCROLL_DURATION, 0.0, 1.0);
	body_progress := clamp((elapsed - 0.6) / SCROLL_DURATION, 0.0, 1.0);

	banner_ease := Ease.out_back(banner_progress);
	text_ease := Ease.out_cubic(text_progress);
	ground_ease := Ease.out_back(ground_progress);
	body_ease := Ease.out_elastic(body_progress);

	screen := UI.get_safe_screen_rect();
	top_center := screen->cut_top(200)->offset(0, -100);
	top_center->cut_left(50);
	top_center->cut_right(50);
	banner_rect := top_center;
	banner_rect = banner_rect->fit_aspect(banner_texture.aspect, .KEEP_HEIGHT);
	banner_rect = banner_rect->offset(0, 300.0 * (1.0 - banner_ease));
	UI.quad(banner_rect, banner_texture, .{1, 1, 1, 1});

	height := banner_rect->height();
	text_rect := banner_rect->inset_unscaled(height * 0.1, 0, height * 0.33, 0);
	text_rect = text_rect->fit_aspect(text_texture.aspect, .KEEP_HEIGHT);
	text_rect = text_rect->offset(-20.0 * (1.0 - text_ease), 0);
	UI.quad(text_rect, text_texture, .{1, 1, 1, 1});

	ground_rect := screen->cut_top(150)->offset(0, -150)->center_rect()->grow(150);
	ground_rect = ground_rect->fit_aspect(ground_texture.aspect, .KEEP_HEIGHT);
	ground_rect = ground_rect->offset(0, -200.0 * (1.0 - ground_ease));
	UI.quad(ground_rect, ground_texture, .{1, 1, 1, 1});

	body_rect := ground_rect->inset(0,0,25,0);
	body_rect = body_rect->fit_aspect(body_texture.aspect, .KEEP_HEIGHT);
	body_rect = body_rect->offset(0, 50.0 * (1.0 - body_ease));
	UI.quad(body_rect, body_texture, .{1, 1, 1, 1});
}

Meeting_Called_Popup :: class {

	banner_texture: Texture_Asset;
	text_texture: Texture_Asset;
	body_texture: Texture_Asset;
	
	is_visible: bool;
	show_start_time: float;
	
	init :: proc(using this: Meeting_Called_Popup) {
		banner_texture = get_asset(Texture_Asset, "sprites/icons/Meeting Called/banner.png");
		text_texture = get_asset(Texture_Asset, "sprites/icons/Meeting Called/text.png");
		body_texture = get_asset(Texture_Asset, "sprites/icons/Meeting Called/schleem.png");
		is_visible = false;
		show_start_time = 0.0;
	}
	show :: proc(using this: Meeting_Called_Popup) {
		is_visible = true;
		show_start_time = get_time();
	}

	hide :: proc(using this: Meeting_Called_Popup) {
		is_visible = false;
	}

	is_finished :: proc(using this: Meeting_Called_Popup) -> bool {
		if !is_visible { return true; }
		elapsed := get_time() - show_start_time;
		return elapsed >= POPUP_DURATION;
	}

	update :: proc(using this: Meeting_Called_Popup, delta_time: float) {
		if !is_visible { return; }
		
		elapsed := get_time() - show_start_time;
		
		// Auto-hide after duration
		if elapsed >= POPUP_DURATION {
			is_visible = false;
			return;
		}
		
		render_popup(this, elapsed);
	}
}

// Separate function to render the popup with scroll effects
render_popup :: proc(using popup: Meeting_Called_Popup, elapsed: float) {

	banner_progress := clamp((elapsed - 0.0) / SCROLL_DURATION, 0.0, 1.0);
	text_progress := clamp((elapsed - 0.2) / SCROLL_DURATION, 0.0, 1.0);
	body_progress := clamp((elapsed - 0.4) / SCROLL_DURATION, 0.0, 1.0);

	banner_ease := Ease.out_back(banner_progress);
	text_ease := Ease.out_cubic(text_progress);
	body_ease := Ease.out_back(body_progress);

	screen := UI.get_safe_screen_rect();
	top_center := screen->cut_top(200)->offset(0, -100);
	top_center->cut_left(50);
	top_center->cut_right(50);
	banner_rect := top_center;
	banner_rect = banner_rect->fit_aspect(banner_texture.aspect, .KEEP_HEIGHT);
	banner_rect = banner_rect->offset(0, 300.0 * (1.0 - banner_ease));
	UI.quad(banner_rect, banner_texture, .{1, 1, 1, 1});

	height := banner_rect->height();
	text_rect := banner_rect->inset_unscaled(height * 0.1, 0, height * 0.33, 0);
	text_rect = text_rect->fit_aspect(text_texture.aspect, .KEEP_HEIGHT);
	text_rect = text_rect->offset(-20.0 * (1.0 - text_ease), 0);
	UI.quad(text_rect, text_texture, .{1, 1, 1, 1});

	body_rect := screen->cut_top(150)->offset(0, -150)->center_rect()->grow(150);
	body_rect = body_rect->fit_aspect(body_texture.aspect, .KEEP_HEIGHT);
	body_rect = body_rect->offset(0, -200.0 * (1.0 - body_ease));
	UI.quad(body_rect, body_texture, .{1, 1, 1, 1});
}

Intro_Popup :: class {

	bg_texture: Texture_Asset;
	
	is_visible: bool;
	show_start_time: float;

	spine_instance: Spine_Instance;
	player_type: Player_Type;
	player_role: Player_Role;
	
	init :: proc(using this: Intro_Popup) {
		bg_texture = get_asset(Texture_Asset, "sprites/intro.png");
		is_visible = false;
		show_start_time = 0.0;
	}

	show :: proc(using this: Intro_Popup, player: Player, type: Player_Type, role: Player_Role) {
		is_visible = true;
		show_start_time = get_time();
		this.spine_instance = player.entity->get_component(Spine_Animator).instance;
		this.player_type = type;
		this.player_role = role;
	}

	hide :: proc(using this: Intro_Popup) {
		is_visible = false;
	}

	is_finished :: proc(using this: Intro_Popup) -> bool {
		if !is_visible { return true; }
		elapsed := get_time() - show_start_time;
		return elapsed >= POPUP_DURATION;
	}

	update :: proc(using this: Intro_Popup, delta_time: float) {
		if !is_visible { return; }
		
		elapsed := get_time() - show_start_time;
		
		// Auto-hide after duration
		if elapsed >= POPUP_DURATION {
			is_visible = false;
			return;
		}
		
		render_popup(this, elapsed);
	}
}

get_type_name :: proc(type: Player_Type) -> string {
	if type == Player_Type.CIVILIAN {
		return "CIVILIAN";
	} else if type == Player_Type.ANARCHIST {
		return "ANARCHIST";
	} else if type == Player_Type.TRAITOR {
		return "TRAITOR";
	}
	return "UNKNOWN";
}

get_role_name :: proc(role: Player_Role) -> string {
	if role == Player_Role.SHERIFF {
		return "Sheriff";
	} else if role == Player_Role.PIRATE {
		return "Pirate";
	}
	return "";
}

get_type_color :: proc(type: Player_Type) -> v4 {
	if type == Player_Type.CIVILIAN {
		return .{0.2, 0.8, 0.4, 1.0}; // Green
	} else if type == Player_Type.ANARCHIST {
		return .{0.9, 0.6, 0.1, 1.0}; // Orange
	} else if type == Player_Type.TRAITOR {
		return .{0.9, 0.2, 0.2, 1.0}; // Red
	}
	return .{1.0, 1.0, 1.0, 1.0};
}

// Separate function to render the popup with scroll effects
render_popup :: proc(using popup: Intro_Popup, elapsed: float) {
	// Calculate animation progress
	bg_progress := clamp(elapsed / 0.5, 0.0, 1.0);
	player_progress := clamp((elapsed - 0.3) / 0.8, 0.0, 1.0);
	type_progress := clamp((elapsed - 0.6) / 0.6, 0.0, 1.0);
	role_progress := clamp((elapsed - 0.9) / 0.6, 0.0, 1.0);
	
	bg_alpha := Ease.out_cubic(bg_progress);
	player_scale := Ease.out_back(player_progress);
	type_ease := Ease.out_back(type_progress);
	role_ease := Ease.out_elastic(role_progress);
	
	screen := UI.get_screen_rect();
	
	// Background with fade in
	bg_rect := screen->fit_aspect(bg_texture.aspect, .KEEP_BIGGER);
	UI.quad(bg_rect, bg_texture, .{1, 1, 1, bg_alpha});
	
	// Player spine in center with scale animation
	player_size := 150.0 * player_scale;
	player_rect := screen->center_rect()->grow(player_size);
	player_rect = player_rect->offset(0, 50);
	UI.spine(player_rect, spine_instance, .{1, 1}, 0.0);
	
	// Type text above player
	type_name := get_type_name(player_type);
	type_color := get_type_color(player_type);
	
	ts := UI.default_text_settings();
	ts.size = 72;
	ts.color = type_color;
	ts.color.w = type_ease;
	ts.halign = .CENTER;
	ts.valign = .CENTER;
	
	type_rect := screen->center_rect()->grow(200);
	type_rect = type_rect->offset(0, -150 + 30.0 * (1.0 - type_ease));
	UI.text(type_rect, ts, type_name);
	
	// Role text below type (if player has a role)
	role_name := get_role_name(player_role);
	if role_name != "" {
		rs := UI.default_text_settings();
		rs.size = 48;
		rs.color = .{1.0, 0.9, 0.3, role_ease}; // Golden color for roles
		rs.halign = .CENTER;
		rs.valign = .CENTER;
		
		role_rect := screen->center_rect()->grow(200);
		role_rect = role_rect->offset(0, -80 + 20.0 * (1.0 - role_ease));
		UI.text(role_rect, rs, role_name);
	}
	
	// "You are a..." label at top
	label_ts := UI.default_text_settings();
	label_ts.size = 36;
	label_ts.color = .{1.0, 1.0, 1.0, type_ease * 0.8};
	label_ts.halign = .CENTER;
	label_ts.valign = .CENTER;
	
	label_rect := screen->center_rect()->grow(150);
	label_rect = label_rect->offset(0, -220);
	UI.text(label_rect, label_ts, "You are a...");
}