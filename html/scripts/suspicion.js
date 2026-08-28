class Suspicion {
    constructor() {
        this._constructor();
    }

    _constructor() {
        this.position_left = "0px";
        this.position_top = "0px";
        this.position_scale = 1.0;
        this.position_justify_h = "center";
        this.position_justify_v = "top";
        this.vignetta_effect = true;

        this.panel_active = false;
        this.loop = this.loop.bind(this);
        this.last_ts = null;
        this.anim_time = 0;

        this.blink_phase = 0;
        this.pulse_phase = 0;
        this.scan_offset = 0;
        this.particles = [];
        this.transition_alpha = 0;

        this.vignette_ele = null;
        this.vignette_visible = false;

        this.suspicion_level = 0;
        this.suspicion_amount = 0;
        this.suspicion_titles = ['Undetected', 'Restricted Area', 'Suspicious Activity', 'Spotted', 'Alarmed'];
        this.suspicion_text = '';
    }

    init(data) {
        this.suspicion_titles = data.suspicion_titles ?? this.suspicion_titles;
        this.vignetta_effect = data.vignetta_effect ?? this.vignetta_effect;
        if (data.position) {
            this.position_left = data.position.left ?? this.position_left;
            this.position_top = data.position.top ?? this.position_top;
            this.position_scale = data.position.scale ?? this.position_scale;
            this.position_justify_h = data.position.justify_h ?? this.position_justify_h;
            this.position_justify_v = data.position.justify_v ?? this.position_justify_v;
        }
    }

    show_panel() {
        if (this.panel_active) return;
        this.particles = this.create_particles();
        this.create_vignette();
        this.build_ui();
        this.panel_active = true;
    }

    set_level(level, amount, text) {
        this.suspicion_level = level;
        this.suspicion_amount = amount;
        this.suspicion_text = text;
        this.transition_alpha = 1.0;
        this.apply_level_styles();
        this.updateText();
        this.updateAmountBar();
    }

    level_config(level) {
        const configs = [
            {
                label: 'Undetected',
                color: 'rgba(138,184,160,1)',
                color_dim: 'rgba(58,90,72,1)',
                color_glow: 'rgba(138,184,160,0.12)',
                bg_color: 'rgba(4,12,8,0.78)',
                border_color: 'rgba(138,184,160,0.28)',
                icon: '◈',
                bar_count: 0,
                scan_speed: 0.12,
                ring_count: 0,
                pulse_speed: 0,
                icon_scale: 1.0,
                blink_rate: 0,
                rotate_icon: false,
                shake_icon: false,
            },
            {
                label: 'Restricted Area',
                color: 'rgba(245,197,24,1)',
                color_dim: 'rgba(122,96,8,1)',
                color_glow: 'rgba(245,197,24,0.18)',
                bg_color: 'rgba(14,10,0,0.86)',
                border_color: 'rgba(245,197,24,0.38)',
                icon: '⚠',
                bar_count: 1,
                scan_speed: 0.22,
                ring_count: 1,
                pulse_speed: 1.2,
                icon_scale: 1.05,
                blink_rate: 0,
                rotate_icon: false,
                shake_icon: false,
            },
            {
                label: 'Suspicious Activity',
                color: 'rgba(255,140,26,1)',
                color_dim: 'rgba(122,58,0,1)',
                color_glow: 'rgba(255,140,26,0.46)',
                bg_color: 'rgba(18,6,0,0.90)',
                border_color: 'rgba(255,140,26,0.48)',
                icon: '◉',
                bar_count: 2,
                scan_speed: 0.5,
                ring_count: 2,
                pulse_speed: 2.0,
                icon_scale: 1.12,
                blink_rate: 2.2,
                rotate_icon: false,
                shake_icon: false,
            },
            {
                label: 'Target Spotted',
                color: 'rgba(255,56,56,1)',
                color_dim: 'rgba(122,0,0,1)',
                color_glow: 'rgba(255,56,56,0.28)',
                bg_color: 'rgba(20,0,0,0.93)',
                border_color: 'rgba(255,56,56,0.6)',
                icon: '◎',
                bar_count: 3,
                scan_speed: 0.85,
                ring_count: 3,
                pulse_speed: 3.2,
                icon_scale: 1.2,
                blink_rate: 3.2,
                rotate_icon: false,
                shake_icon: true,
            },
            {
                label: 'Full Alarm',
                color: 'rgba(255,26,26,1)',
                color_dim: 'rgba(106,0,0,1)',
                color_glow: 'rgba(255,26,26,0.05)',
                bg_color: 'rgba(26,0,0,0.96)',
                border_color: 'rgba(255,26,26,0.75)',
                icon: '☢',
                bar_count: 4,
                scan_speed: 1.4,
                ring_count: 4,
                pulse_speed: 0.5,
                icon_scale: 1.3,
                blink_rate: 0,
                rotate_icon: true,
                shake_icon: false,
            },
        ];
        return configs[Math.max(0, Math.min(4, level))];
    }

    create_particles() {
        const pts = [];
        for (let i = 0; i < 10; i++) {
            pts.push({
                x: Math.random(),
                y: Math.random(),
                speed: 0.008 + Math.random() * 0.016,
                size: 0.8 + Math.random() * 1.2,
                opacity: 0.08 + Math.random() * 0.18,
                phase: Math.random() * Math.PI * 2,
            });
        }
        return pts;
    }

    create_vignette() {
        if (document.getElementById('susp-vignette')) {
            this.vignette_ele = document.getElementById('susp-vignette');
            return;
        }

        const vin = document.createElement('div');
        vin.id = 'susp-vignette';

        const edge = document.createElement('div');
        edge.id = 'susp-vignette-edge';
        vin.appendChild(edge);

        const pulse = document.createElement('div');
        pulse.id = 'susp-vignette-pulse';
        vin.appendChild(pulse);

        document.body.appendChild(vin);
        this.vignette_ele = vin;
    }

    update_vignette(cfg) {
        const vin = document.getElementById('susp-vignette');
        const edge = document.getElementById('susp-vignette-edge');
        if (!vin || !edge) return;

        const should_show = this.vignetta_effect && this.suspicion_level >= 2;
        this.vignette_visible = should_show;
        vin.style.opacity = should_show ? '1' : '0';

        const spread = 40 + cfg.ring_count * 25;
        const blur = 120 + cfg.ring_count * 40;
        edge.style.boxShadow = `inset 0 0 ${blur}px ${spread}px ${cfg.color_glow}`;

        const pulse = document.getElementById('susp-vignette-pulse');
        if (pulse) {
            pulse.style.background = `radial-gradient(circle at center, transparent 50%, ${cfg.color} 150%)`;
        }
    }

    build_ui() {
        const cfg = this.level_config(this.suspicion_level);
        const container = document.getElementById('suspicion_level_container');

        const panel = document.createElement('div');
        panel.id = 'suspicion_panel';

        if (this.position_justify_v == "bottom") {
            panel.style.top = "auto";
            panel.style.bottom = "0px";
        } else if (this.position_justify_v == "center") {
            panel.style.top = "50%";
        }
        
        if (this.position_justify_h == "right") {
            panel.style.justifyContent = "right";
        } else if (this.position_justify_h == "center") {
            panel.style.justifyContent = "center";
        }

        const wrap = document.createElement('div');
        wrap.id = 'susp-panel-wrap';
        wrap.style.left = this.position_left;
        wrap.style.top = this.position_top;
        wrap.style.scale = this.position_scale;

        const inner = document.createElement('div');
        inner.id = 'susp-inner';
        inner.style.background = cfg.bg_color;

        const canvas = document.createElement('canvas');
        canvas.id = 'susp-canvas';
        inner.appendChild(canvas);

        const border_svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        border_svg.id = 'susp-border-svg';
        border_svg.setAttribute('preserveAspectRatio', 'none');
        inner.appendChild(border_svg);

        const icon_wrap = document.createElement('div');
        icon_wrap.id = 'susp-icon-wrap';

        const icon_canvas = document.createElement('canvas');
        icon_canvas.id = 'susp-icon-canvas';
        icon_canvas.width = 52;
        icon_canvas.height = 52;
        icon_wrap.appendChild(icon_canvas);

        const icon = document.createElement('span');
        icon.id = 'susp-icon';
        icon.style.color = cfg.color;
        icon.style.transformOrigin = 'center center';
        icon.textContent = cfg.icon;
        icon_wrap.appendChild(icon);

        inner.appendChild(icon_wrap);

        const label = document.createElement('span');
        label.id = 'susp-label';
        label.style.color = cfg.color;
        label.textContent = this.suspicion_titles[this.suspicion_level];
        inner.appendChild(label);

        const text = document.createElement('span');
        text.id = 'susp-text';
        text.style.color = cfg.color;
        text.textContent = this.suspicion_text;
        inner.appendChild(text);

        const amount_wrap = document.createElement('div');
        amount_wrap.id = 'susp-amount-wrap';
        amount_wrap.style.width = '100%';
        amount_wrap.style.padding = '2px 8px';
        amount_wrap.style.boxSizing = 'border-box';
        amount_wrap.style.display = (this.suspicion_level === 2 || this.suspicion_level === 3) ? 'block' : 'none';

        const amount_bar = document.createElement('div');
        amount_bar.id = 'susp-amount-bar';
        amount_bar.style.height = '3px';
        amount_bar.style.width = '100%';
        amount_bar.style.background = 'rgba(0,0,0,0.5)';
        amount_bar.style.border = `1px solid ${cfg.color_dim}`;
        amount_bar.style.borderRadius = '1px';
        amount_bar.style.overflow = 'hidden';
        amount_bar.style.position = 'relative';

        const amount_fill = document.createElement('div');
        amount_fill.id = 'susp-amount-fill';
        amount_fill.style.height = '100%';
        amount_fill.style.width = `${(Math.max(0, Math.min(1, this.suspicion_amount ?? 0)) * 100).toFixed(1)}%`;
        amount_fill.style.background = cfg.color;
        amount_fill.style.boxShadow = `0 0 6px ${cfg.color}`;
        amount_fill.style.borderRadius = '1px';
        amount_fill.style.transition = 'width 0.25s ease';

        amount_bar.appendChild(amount_fill);
        amount_wrap.appendChild(amount_bar);
        inner.appendChild(amount_wrap);

        const tab_bottom = document.createElement('div');
        tab_bottom.id = 'susp-tab-bottom';
        for (let i = 0; i < 4; i++) {
            const bar = document.createElement('div');
            bar.className = 'susp-bar';
            bar.style.background = i < cfg.bar_count ? cfg.color : cfg.color_dim;
            bar.style.opacity = i < cfg.bar_count ? '1' : '0.2';
            tab_bottom.appendChild(bar);
        }
        inner.appendChild(tab_bottom);

        wrap.appendChild(inner);

        const tab_foot = document.createElement('div');
        tab_foot.id = 'susp-tab-foot';

        const foot_corner_left = document.createElement('div');
        foot_corner_left.className = 'susp-foot-corner susp-foot-corner-l';
        foot_corner_left.style.border_color = cfg.border_color;

        const foot_line_left = document.createElement('div');
        foot_line_left.className = 'susp-foot-line';
        foot_line_left.style.background = cfg.border_color;

        const foot_line_right = document.createElement('div');
        foot_line_right.className = 'susp-foot-line';
        foot_line_right.style.background = cfg.border_color;

        const foot_corner_right = document.createElement('div');
        foot_corner_right.className = 'susp-foot-corner susp-foot-corner-r';
        foot_corner_right.style.border_color = cfg.border_color;

        tab_foot.appendChild(foot_corner_left);
        tab_foot.appendChild(foot_line_left);
        tab_foot.appendChild(foot_line_right);
        tab_foot.appendChild(foot_corner_right);
        wrap.appendChild(tab_foot);

        panel.appendChild(wrap);
        container.prepend(panel);

        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.icon_ctx = icon_canvas.getContext('2d');

        this.resize_canvas();
        window.addEventListener('resize', () => this.resize_canvas());
        this.update_border_svg(cfg);
        this.update_vignette(cfg);

        this.anim_frame = requestAnimationFrame(this.loop);
    }

    resize_canvas() {
        if (!this.canvas) return;
        const w = this.canvas.offsetWidth || 280;
        const h = this.canvas.offsetHeight || 120;
        this.canvas.width = w;
        this.canvas.height = h;
    }

    update_border_svg(cfg) {
        const svg = document.getElementById('susp-border-svg');
        if (!svg) return;
        svg.innerHTML = '';

        const W = 280;
        const H = 120;
        const c = 14;
        const tc = 28;

        svg.setAttribute('viewBox', `0 0 ${W} ${H}`);

        const make_poly_line = (pts, stroke, sw, opacity) => {
            const el = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
            el.setAttribute('points', pts.map(p => p.join(',')).join(' '));
            el.setAttribute('stroke', stroke);
            el.setAttribute('stroke-width', sw);
            el.setAttribute('fill', 'none');
            el.setAttribute('opacity', opacity);
            return el;
        };

        const outer_points = [
            [tc, 0], [W - tc, 0],
            [W, 0], [W, c],
            [W, H - c], [W, H],
            [W - c, H], [c, H],
            [0, H], [0, H - c],
            [0, c], [0, 0],
            [c, 0], [tc, 0],
        ];
        svg.appendChild(make_poly_line(outer_points, cfg.color, '1', '0.5'));

        const corner_len = 18;
        const corners = [
            [[0, corner_len], [0, 0], [corner_len, 0]],
            [[W - corner_len, 0], [W, 0], [W, corner_len]],
            [[W, H - corner_len], [W, H], [W - corner_len, H]],
            [[corner_len, H], [0, H], [0, H - corner_len]],
        ];
        corners.forEach(pts => {
            svg.appendChild(make_poly_line(pts, cfg.color, '1.5', '0.9'));
        });

        const notch_size = 5;
        [[tc, 0], [W - tc, 0]].forEach(([x]) => {
            const tick = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            tick.setAttribute('x1', x); tick.setAttribute('y1', 0);
            tick.setAttribute('x2', x); tick.setAttribute('y2', notch_size);
            tick.setAttribute('stroke', cfg.color);
            tick.setAttribute('stroke-width', '1');
            tick.setAttribute('opacity', '0.7');
            svg.appendChild(tick);
        });
    }

    apply_level_styles() {
        const cfg = this.level_config(this.suspicion_level);
        const inner = document.getElementById('susp-inner');
        if (!inner) return;
        inner.style.background = cfg.bg_color;

        ['susp-icon', 'susp-label', 'susp-text'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.style.color = cfg.color;
        });

        const icon_ele = document.getElementById('susp-icon');
        if (icon_ele) icon_ele.textContent = cfg.icon;

        const label_ele = document.getElementById('susp-label');
        if (label_ele) label_ele.textContent = this.suspicion_titles[this.suspicion_level];

        document.querySelectorAll('.susp-bar').forEach((bar, i) => {
            bar.style.background = i < cfg.bar_count ? cfg.color : cfg.color_dim;
            bar.style.opacity = i < cfg.bar_count ? '1' : '0.2';
        });

        document.querySelectorAll('.susp-foot-corner').forEach(el => {
            el.style.border_color = cfg.border_color;
        });
        document.querySelectorAll('.susp-foot-line').forEach(el => {
            el.style.background = cfg.border_color;
        });

        this.update_border_svg(cfg);
        this.update_vignette(cfg);
    }

    updateText() {
        const el = document.getElementById('susp-text');
        if (el) el.textContent = this.suspicion_text;
    }

    updateAmountBar() {
        const wrap = document.getElementById('susp-amount-wrap');
        const fill = document.getElementById('susp-amount-fill');
        const bar = document.getElementById('susp-amount-bar');
        if (!wrap || !fill || !bar) return;

        const show_amount = this.suspicion_level === 2 || this.suspicion_level === 3;
        wrap.style.display = show_amount ? 'block' : 'none';

        if (show_amount) {
            const cfg = this.level_config(this.suspicion_level);
            const pct = Math.max(0, Math.min(1, this.suspicion_amount ?? 0));
            fill.style.width = `${(pct * 100).toFixed(1)}%`;
            fill.style.background = cfg.color;
            fill.style.boxShadow = `0 0 6px ${cfg.color}`;
            bar.style.border_color = cfg.color_dim;
        }
    }

    loop(ts) {
        if (this.last_ts === null) this.last_ts = ts;
        const dt = Math.min((ts - this.last_ts) / 1000, 0.05);
        this.last_ts = ts;
        this.anim_time += dt;

        const cfg = this.level_config(this.suspicion_level);

        this.pulse_phase += dt * cfg.pulse_speed;
        this.blink_phase += dt * cfg.blink_rate;
        this.scan_offset = (this.scan_offset + cfg.scan_speed * dt) % 1;

        this.animate_icon(cfg);
        this.draw_background(dt, cfg);
        this.draw_icon_rings(cfg);
        this.animateVignette(cfg);

        this.anim_frame = requestAnimationFrame(this.loop);
    }

    animateVignette(cfg) {
        if (!this.vignette_visible) return;

        const edge = document.getElementById('susp-vignette-edge');
        const pulse = document.getElementById('susp-vignette-pulse');
        if (!edge) return;

        const breathe = (Math.sin(this.pulse_phase) + 1) / 2;
        const base_spread = 40 + cfg.ring_count * 25;
        const base_blur = 120 + cfg.ring_count * 40;
        const spread = base_spread + breathe * (12 + cfg.ring_count * 6);
        const blur = base_blur + breathe * (24 + cfg.ring_count * 10);
        edge.style.boxShadow = `inset 0 0 ${blur.toFixed(0)}px ${spread.toFixed(0)}px ${cfg.color_glow}`;

        if (cfg.blink_rate > 0) {
            const blink = (Math.sin(this.blink_phase * Math.PI * 2) + 1) / 2;
            edge.style.opacity = (0.55 + blink * 0.45).toFixed(2);
        } else {
            edge.style.opacity = '1';
        }

        if (!pulse) return;

        if (cfg.shake_icon) {
            // Uncomment for flicker effect of ones where shake_icon is true
            // const flicker = Math.random() > 0.86 ? (0.12 + Math.random() * 0.16) : 0;
            // pulse.style.opacity = flicker.toFixed(2);
        } else if (cfg.rotate_icon) {
            const heartbeat = Math.max(0, Math.sin(this.pulse_phase * 2)) ** 6;
            pulse.style.opacity = (heartbeat * 0.32).toFixed(2);
        } else {
            pulse.style.opacity = '0';
        }
    }

    animate_icon(cfg) {
        const icon_ele = document.getElementById('susp-icon');
        if (!icon_ele) return;
        const t = this.anim_time;

        icon_ele.style.transform = '';

        if (cfg.rotate_icon) {
            const deg = (t * 30) % 360;
            icon_ele.style.transform = `rotate(${deg.toFixed(1)}deg)`;
            icon_ele.style.opacity = '1';
            return;
        }

        if (cfg.shake_icon) {
            const sx = Math.sin(t * 18) * 2.5;
            const sy = Math.cos(t * 22) * 1.5;
            icon_ele.style.transform = `translate(${sx.toFixed(2)}px, ${sy.toFixed(2)}px)`;
        }

        if (cfg.blink_rate > 0) {
            const blink = (Math.sin(this.blink_phase * Math.PI * 2) + 1) / 2;
            icon_ele.style.opacity = (0.2 + blink * 0.8).toFixed(2);
        } else if (cfg.ring_count > 0) {
            const breathe = 0.85 + 0.15 * Math.sin(this.pulse_phase);
            icon_ele.style.opacity = breathe.toFixed(2);
        } else {
            icon_ele.style.opacity = '0.7';
        }

        if (cfg.pulse_speed > 0 && cfg.blink_rate === 0) {
            const base_scale = cfg.icon_scale;
            const ps = 1.0 + (base_scale - 1.0) * ((Math.sin(this.pulse_phase) + 1) / 2);
            const existing = icon_ele.style.transform;
            icon_ele.style.transform = existing ? `${existing} scale(${ps.toFixed(3)})` : `scale(${ps.toFixed(3)})`;
        }
    }

    draw_icon_rings(cfg) {
        const ctx = this.icon_ctx;
        if (!ctx) return;
        ctx.clearRect(0, 0, 52, 52);
        if (cfg.ring_count === 0) return;

        const cx = 26, cy = 26;

        for (let r = 0; r < cfg.ring_count; r++) {
            const phase = this.pulse_phase - r * (Math.PI * 0.7);
            const expand = (Math.sin(phase) + 1) / 2;
            const base_r = 14 + r * 5;
            const radius = base_r + expand * 8;
            const alpha = (1 - expand) * (0.5 - r * 0.08);
            if (alpha <= 0) continue;

            ctx.save();
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            ctx.strokeStyle = cfg.color;
            ctx.globalAlpha = Math.max(0, alpha);
            ctx.lineWidth = 1.5 - r * 0.25;
            ctx.stroke();
            ctx.restore();
        }

        if (cfg.ring_count >= 4) {
            const flicker = Math.random() > 0.6 ? 0.12 : 0;
            if (flicker > 0) {
                ctx.save();
                ctx.beginPath();
                ctx.arc(cx, cy, 20 + Math.random() * 6, 0, Math.PI * 2);
                ctx.strokeStyle = cfg.color;
                ctx.globalAlpha = flicker;
                ctx.lineWidth = 3;
                ctx.stroke();
                ctx.restore();
            }
        }
    }

    draw_background(dt, cfg) {
        const ctx = this.ctx;
        if (!ctx) return;
        const w = this.canvas.width;
        const h = this.canvas.height;
        ctx.clearRect(0, 0, w, h);
        const t = this.anim_time;

        ctx.save();
        ctx.strokeStyle = cfg.color;
        ctx.globalAlpha = 0.03;
        ctx.lineWidth = 0.5;
        const hex_size = 12;
        const hex_w = hex_size * Math.sqrt(3);
        const hex_h = hex_size * 2;
        const scroll_x = (t * 12) % (hex_w * 2);
        for (let col = -2; col < Math.ceil(w / hex_w) + 2; col++) {
            for (let row = -1; row < Math.ceil(h / (hex_h * 0.75)) + 1; row++) {
                const cx = col * hex_w - scroll_x + (row % 2) * (hex_w / 2);
                const cy = row * hex_h * 0.75;
                ctx.beginPath();
                for (let j = 0; j < 6; j++) {
                    const angle = (Math.PI / 3) * j - Math.PI / 6;
                    const px = cx + hex_size * Math.cos(angle);
                    const py = cy + hex_size * Math.sin(angle);
                    j === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
                }
                ctx.closePath();
                ctx.stroke();
            }
        }
        ctx.restore();

        for (const p of this.particles) {
            p.x -= p.speed * dt * 0.4;
            if (p.x < -0.02) p.x = 1.02;
            const flicker = 0.6 + 0.4 * Math.sin(t * 1.5 + p.phase);
            ctx.save();
            ctx.globalAlpha = p.opacity * flicker;
            ctx.fillStyle = cfg.color;
            ctx.beginPath();
            ctx.arc(p.x * w, p.y * h, p.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }

        const scan_x = (this.scan_offset * (w + 60)) - 30;
        ctx.save();
        const scan_grad = ctx.createLinearGradient(scan_x - 6, 0, scan_x + 6, 0);
        scan_grad.addColorStop(0, 'transparent');
        scan_grad.addColorStop(0.5, cfg.color.replace(',1)', ',0.06)'));
        scan_grad.addColorStop(1, 'transparent');
        ctx.fillStyle = cfg.color;
        ctx.globalAlpha = 0.04;
        ctx.fillRect(scan_x - 4, 0, 8, h);
        ctx.restore();

        if (cfg.ring_count >= 4 && Math.random() > 0.88) {
            ctx.save();
            ctx.globalAlpha = 0.05;
            ctx.fillStyle = '#ff1a1a';
            ctx.fillRect(0, Math.random() * h, w, 1 + Math.random() * 2);
            ctx.restore();
        }
    }

    reset() {
        const saved_titles = this.suspicion_titles;
        const saved_text = this.suspicion_text;

        if (this.anim_frame) cancelAnimationFrame(this.anim_frame);
        const panel = document.getElementById('suspicion_panel');
        if (panel) panel.remove();

        if (this.vignette_ele) this.vignette_ele.remove();
        const vin = document.getElementById('susp-vignette');
        if (vin) vin.remove();

        try { window.removeEventListener('resize', () => this.resize_canvas()); } catch (e) {}

        this._constructor();

        if (saved_titles) this.suspicion_titles = saved_titles;
        if (saved_text) this.suspicion_text = saved_text;

        this.panel_active = false;
    }
}

// // dev
// let suspicion_dev = new Suspicion();
// suspicion_dev.init({
//     suspicion_titles: [
//         "suspicion_title_0",
//         "suspicion_title_1",
//         "suspicion_title_2",
//         "suspicion_title_3",
//         "suspicion_title_4"
//     ],
//     vignette_effect: true,
//     position: {
//         left: "0.0px",
//         top: "0.0px",
//         scale: 1.0,
//         justify_h: "left",
//         justify_v: "bottom"
//     }
// })
// suspicion_dev.show_panel();
