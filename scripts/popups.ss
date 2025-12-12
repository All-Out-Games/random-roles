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