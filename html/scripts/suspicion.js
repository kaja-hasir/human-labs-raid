class Suspicion {
    constructor() {
        this._constructor();
    }

    _constructor() {
        this.panel_active = false;
        this.loop = this.loop.bind(this);
        this.lastTS = null;
        this.animTime = 0;

        this._blinkPhase = 0;
        this._pulsePhase = 0;
        this._scanOffset = 0;
        this._particles = [];
        this._transitionAlpha = 0;

        this.suspicion_level = 0;
        this.suspicion_amount = 0;
        this.suspicion_titles = ['Undetected', 'Restricted Area', 'Suspicious Activity', 'Spotted', 'Alarmed'];
        this.suspicion_text = '';
    }

    init(data) {
        this.suspicion_titles = data.suspicion_titles ?? this.suspicion_titles;
    }

    show_panel() {
        if (this.panel_active) return;
        this._particles = this._createParticles();
        this.build_ui();
        this.panel_active = true;
    }

    set_level(level, amount, text) {
        this.suspicion_level = level;
        this.suspicion_amount = amount;
        this.suspicion_text = text;
        this._transitionAlpha = 1.0;
        this._applyLevelStyles();
        this._updateText();
        this._updateAmountBar();
    }

    _levelConfig(level) {
        const configs = [
            {
                label: 'Undetected',
                color: 'rgba(138,184,160,1)',
                colorDim: 'rgba(58,90,72,1)',
                colorGlow: 'rgba(138,184,160,0.12)',
                bgColor: 'rgba(4,12,8,0.78)',
                borderColor: 'rgba(138,184,160,0.28)',
                icon: '◈',
                barCount: 0,
                scanSpeed: 0.12,
                ringCount: 0,
                pulseSpeed: 0,
                iconScale: 1.0,
                blinkRate: 0,
                rotateIcon: false,
                shakeIcon: false,
            },
            {
                label: 'Restricted Area',
                color: 'rgba(245,197,24,1)',
                colorDim: 'rgba(122,96,8,1)',
                colorGlow: 'rgba(245,197,24,0.18)',
                bgColor: 'rgba(14,10,0,0.86)',
                borderColor: 'rgba(245,197,24,0.38)',
                icon: '⚠',
                barCount: 1,
                scanSpeed: 0.22,
                ringCount: 1,
                pulseSpeed: 1.2,
                iconScale: 1.05,
                blinkRate: 0,
                rotateIcon: false,
                shakeIcon: false,
            },
            {
                label: 'Suspicious Activity',
                color: 'rgba(255,140,26,1)',
                colorDim: 'rgba(122,58,0,1)',
                colorGlow: 'rgba(255,140,26,0.22)',
                bgColor: 'rgba(18,6,0,0.90)',
                borderColor: 'rgba(255,140,26,0.48)',
                icon: '◉',
                barCount: 2,
                scanSpeed: 0.5,
                ringCount: 2,
                pulseSpeed: 2.0,
                iconScale: 1.12,
                blinkRate: 2.2,
                rotateIcon: false,
                shakeIcon: false,
            },
            {
                label: 'Target Spotted',
                color: 'rgba(255,56,56,1)',
                colorDim: 'rgba(122,0,0,1)',
                colorGlow: 'rgba(255,56,56,0.28)',
                bgColor: 'rgba(20,0,0,0.93)',
                borderColor: 'rgba(255,56,56,0.6)',
                icon: '◎',
                barCount: 3,
                scanSpeed: 0.85,
                ringCount: 3,
                pulseSpeed: 3.2,
                iconScale: 1.2,
                blinkRate: 3.2,
                rotateIcon: false,
                shakeIcon: true,
            },
            {
                label: 'Full Alarm',
                color: 'rgba(255,26,26,1)',
                colorDim: 'rgba(106,0,0,1)',
                colorGlow: 'rgba(255,26,26,0.35)',
                bgColor: 'rgba(26,0,0,0.96)',
                borderColor: 'rgba(255,26,26,0.75)',
                icon: '☢',
                barCount: 4,
                scanSpeed: 1.4,
                ringCount: 4,
                pulseSpeed: 5.0,
                iconScale: 1.3,
                blinkRate: 0,
                rotateIcon: true,
                shakeIcon: false,
            },
        ];
        return configs[Math.max(0, Math.min(4, level))];
    }

    _createParticles() {
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

    build_ui() {
        const cfg = this._levelConfig(this.suspicion_level);
        const container = document.getElementById('suspicion_level_container');

        const panel = document.createElement('div');
        panel.id = 'suspicion_panel';

        const wrap = document.createElement('div');
        wrap.id = 'susp-panel-wrap';

        const inner = document.createElement('div');
        inner.id = 'susp-inner';
        inner.style.background = cfg.bgColor;

        const canvas = document.createElement('canvas');
        canvas.id = 'susp-canvas';
        inner.appendChild(canvas);

        const borderSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        borderSvg.id = 'susp-border-svg';
        borderSvg.setAttribute('preserveAspectRatio', 'none');
        inner.appendChild(borderSvg);

        const iconWrap = document.createElement('div');
        iconWrap.id = 'susp-icon-wrap';

        const iconCanvas = document.createElement('canvas');
        iconCanvas.id = 'susp-icon-canvas';
        iconCanvas.width = 52;
        iconCanvas.height = 52;
        iconWrap.appendChild(iconCanvas);

        const icon = document.createElement('span');
        icon.id = 'susp-icon';
        icon.style.color = cfg.color;
        icon.style.transformOrigin = 'center center';
        icon.textContent = cfg.icon;
        iconWrap.appendChild(icon);

        inner.appendChild(iconWrap);

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

        const amountWrap = document.createElement('div');
        amountWrap.id = 'susp-amount-wrap';
        amountWrap.style.width = '100%';
        amountWrap.style.padding = '2px 8px';
        amountWrap.style.boxSizing = 'border-box';
        amountWrap.style.display = (this.suspicion_level === 2 || this.suspicion_level === 3) ? 'block' : 'none';

        const amountBar = document.createElement('div');
        amountBar.id = 'susp-amount-bar';
        amountBar.style.height = '3px';
        amountBar.style.width = '100%';
        amountBar.style.background = 'rgba(0,0,0,0.5)';
        amountBar.style.border = `1px solid ${cfg.colorDim}`;
        amountBar.style.borderRadius = '1px';
        amountBar.style.overflow = 'hidden';
        amountBar.style.position = 'relative';

        const amountFill = document.createElement('div');
        amountFill.id = 'susp-amount-fill';
        amountFill.style.height = '100%';
        amountFill.style.width = `${(Math.max(0, Math.min(1, this.suspicion_amount ?? 0)) * 100).toFixed(1)}%`;
        amountFill.style.background = cfg.color;
        amountFill.style.boxShadow = `0 0 6px ${cfg.color}`;
        amountFill.style.borderRadius = '1px';
        amountFill.style.transition = 'width 0.25s ease';

        amountBar.appendChild(amountFill);
        amountWrap.appendChild(amountBar);
        inner.appendChild(amountWrap);

        const tabBottom = document.createElement('div');
        tabBottom.id = 'susp-tab-bottom';
        for (let i = 0; i < 4; i++) {
            const bar = document.createElement('div');
            bar.className = 'susp-bar';
            bar.style.background = i < cfg.barCount ? cfg.color : cfg.colorDim;
            bar.style.opacity = i < cfg.barCount ? '1' : '0.2';
            tabBottom.appendChild(bar);
        }
        inner.appendChild(tabBottom);

        wrap.appendChild(inner);

        const tabFoot = document.createElement('div');
        tabFoot.id = 'susp-tab-foot';

        const footCornerL = document.createElement('div');
        footCornerL.className = 'susp-foot-corner susp-foot-corner-l';
        footCornerL.style.borderColor = cfg.borderColor;

        const footLineL = document.createElement('div');
        footLineL.className = 'susp-foot-line';
        footLineL.style.background = cfg.borderColor;

        const footLineR = document.createElement('div');
        footLineR.className = 'susp-foot-line';
        footLineR.style.background = cfg.borderColor;

        const footCornerR = document.createElement('div');
        footCornerR.className = 'susp-foot-corner susp-foot-corner-r';
        footCornerR.style.borderColor = cfg.borderColor;

        tabFoot.appendChild(footCornerL);
        tabFoot.appendChild(footLineL);
        tabFoot.appendChild(footLineR);
        tabFoot.appendChild(footCornerR);
        wrap.appendChild(tabFoot);

        panel.appendChild(wrap);
        container.prepend(panel);

        this._canvas = canvas;
        this._ctx = canvas.getContext('2d');
        this._iconCanvas = iconCanvas;
        this._iconCtx = iconCanvas.getContext('2d');

        this._resizeCanvas();
        window.addEventListener('resize', () => this._resizeCanvas());
        this._updateBorderSvg(cfg);

        this.animFrame = requestAnimationFrame(this.loop);
    }

    _resizeCanvas() {
        if (!this._canvas) return;
        const w = this._canvas.offsetWidth || 280;
        const h = this._canvas.offsetHeight || 120;
        this._canvas.width = w;
        this._canvas.height = h;
    }

    _updateBorderSvg(cfg) {
        const svg = document.getElementById('susp-border-svg');
        if (!svg) return;
        svg.innerHTML = '';

        const W = 280;
        const H = 120;
        const c = 14;
        const tc = 28;

        svg.setAttribute('viewBox', `0 0 ${W} ${H}`);

        const makePolyline = (pts, stroke, sw, opacity) => {
            const el = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
            el.setAttribute('points', pts.map(p => p.join(',')).join(' '));
            el.setAttribute('stroke', stroke);
            el.setAttribute('stroke-width', sw);
            el.setAttribute('fill', 'none');
            el.setAttribute('opacity', opacity);
            return el;
        };

        const outerPts = [
            [tc, 0], [W - tc, 0],
            [W, 0], [W, c],
            [W, H - c], [W, H],
            [W - c, H], [c, H],
            [0, H], [0, H - c],
            [0, c], [0, 0],
            [c, 0], [tc, 0],
        ];
        svg.appendChild(makePolyline(outerPts, cfg.color, '1', '0.5'));

        const cornerLen = 18;
        const corners = [
            [[0, cornerLen], [0, 0], [cornerLen, 0]],
            [[W - cornerLen, 0], [W, 0], [W, cornerLen]],
            [[W, H - cornerLen], [W, H], [W - cornerLen, H]],
            [[cornerLen, H], [0, H], [0, H - cornerLen]],
        ];
        corners.forEach(pts => {
            svg.appendChild(makePolyline(pts, cfg.color, '1.5', '0.9'));
        });

        const notchSize = 5;
        [[tc, 0], [W - tc, 0]].forEach(([x]) => {
            const tick = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            tick.setAttribute('x1', x); tick.setAttribute('y1', 0);
            tick.setAttribute('x2', x); tick.setAttribute('y2', notchSize);
            tick.setAttribute('stroke', cfg.color);
            tick.setAttribute('stroke-width', '1');
            tick.setAttribute('opacity', '0.7');
            svg.appendChild(tick);
        });

        this._svgCfgColor = cfg.color;
    }

    _applyLevelStyles() {
        const cfg = this._levelConfig(this.suspicion_level);
        const inner = document.getElementById('susp-inner');
        if (!inner) return;
        inner.style.background = cfg.bgColor;

        ['susp-icon', 'susp-label', 'susp-text'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.style.color = cfg.color;
        });

        const iconEl = document.getElementById('susp-icon');
        if (iconEl) iconEl.textContent = cfg.icon;

        const labelEl = document.getElementById('susp-label');
        if (labelEl) labelEl.textContent = this.suspicion_titles[this.suspicion_level];

        document.querySelectorAll('.susp-bar').forEach((bar, i) => {
            bar.style.background = i < cfg.barCount ? cfg.color : cfg.colorDim;
            bar.style.opacity = i < cfg.barCount ? '1' : '0.2';
        });

        document.querySelectorAll('.susp-foot-corner').forEach(el => {
            el.style.borderColor = cfg.borderColor;
        });
        document.querySelectorAll('.susp-foot-line').forEach(el => {
            el.style.background = cfg.borderColor;
        });

        this._updateBorderSvg(cfg);
    }

    _updateText() {
        const el = document.getElementById('susp-text');
        if (el) el.textContent = this.suspicion_text;
    }

    _updateAmountBar() {
        const wrap = document.getElementById('susp-amount-wrap');
        const fill = document.getElementById('susp-amount-fill');
        const bar = document.getElementById('susp-amount-bar');
        if (!wrap || !fill || !bar) return;

        const showAmount = this.suspicion_level === 2 || this.suspicion_level === 3;
        wrap.style.display = showAmount ? 'block' : 'none';

        if (showAmount) {
            const cfg = this._levelConfig(this.suspicion_level);
            const pct = Math.max(0, Math.min(1, this.suspicion_amount ?? 0));
            fill.style.width = `${(pct * 100).toFixed(1)}%`;
            fill.style.background = cfg.color;
            fill.style.boxShadow = `0 0 6px ${cfg.color}`;
            bar.style.borderColor = cfg.colorDim;
        }
    }

    loop(ts) {
        if (this.lastTS === null) this.lastTS = ts;
        const dt = Math.min((ts - this.lastTS) / 1000, 0.05);
        this.lastTS = ts;
        this.animTime += dt;

        const cfg = this._levelConfig(this.suspicion_level);

        this._pulsePhase += dt * cfg.pulseSpeed;
        this._blinkPhase += dt * cfg.blinkRate;
        this._scanOffset = (this._scanOffset + cfg.scanSpeed * dt) % 1;

        this._animateIcon(cfg);
        this._drawBackground(dt, cfg);
        this._drawIconRings(cfg);

        this.animFrame = requestAnimationFrame(this.loop);
    }

    _animateIcon(cfg) {
        const iconEl = document.getElementById('susp-icon');
        if (!iconEl) return;
        const t = this.animTime;

        iconEl.style.transform = '';

        if (cfg.rotateIcon) {
            const deg = (t * 30) % 360;
            iconEl.style.transform = `rotate(${deg.toFixed(1)}deg)`;
            iconEl.style.opacity = '1';
            return;
        }

        if (cfg.shakeIcon) {
            const sx = Math.sin(t * 18) * 2.5;
            const sy = Math.cos(t * 22) * 1.5;
            iconEl.style.transform = `translate(${sx.toFixed(2)}px, ${sy.toFixed(2)}px)`;
        }

        if (cfg.blinkRate > 0) {
            const blink = (Math.sin(this._blinkPhase * Math.PI * 2) + 1) / 2;
            iconEl.style.opacity = (0.2 + blink * 0.8).toFixed(2);
        } else if (cfg.ringCount > 0) {
            const breathe = 0.85 + 0.15 * Math.sin(this._pulsePhase);
            iconEl.style.opacity = breathe.toFixed(2);
        } else {
            iconEl.style.opacity = '0.7';
        }

        if (cfg.pulseSpeed > 0 && cfg.blinkRate === 0) {
            const baseScale = cfg.iconScale;
            const ps = 1.0 + (baseScale - 1.0) * ((Math.sin(this._pulsePhase) + 1) / 2);
            const existing = iconEl.style.transform;
            iconEl.style.transform = existing ? `${existing} scale(${ps.toFixed(3)})` : `scale(${ps.toFixed(3)})`;
        }
    }

    _drawIconRings(cfg) {
        const ctx = this._iconCtx;
        if (!ctx) return;
        ctx.clearRect(0, 0, 52, 52);
        if (cfg.ringCount === 0) return;

        const cx = 26, cy = 26;

        for (let r = 0; r < cfg.ringCount; r++) {
            const phase = this._pulsePhase - r * (Math.PI * 0.7);
            const expand = (Math.sin(phase) + 1) / 2;
            const baseR = 14 + r * 5;
            const radius = baseR + expand * 8;
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

        if (cfg.ringCount >= 4) {
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

    _drawBackground(dt, cfg) {
        const ctx = this._ctx;
        if (!ctx) return;
        const w = this._canvas.width;
        const h = this._canvas.height;
        ctx.clearRect(0, 0, w, h);
        const t = this.animTime;

        ctx.save();
        ctx.strokeStyle = cfg.color;
        ctx.globalAlpha = 0.03;
        ctx.lineWidth = 0.5;
        const hexSize = 12;
        const hexW = hexSize * Math.sqrt(3);
        const hexH = hexSize * 2;
        const scrollX = (t * 12) % (hexW * 2);
        for (let col = -2; col < Math.ceil(w / hexW) + 2; col++) {
            for (let row = -1; row < Math.ceil(h / (hexH * 0.75)) + 1; row++) {
                const cx = col * hexW - scrollX + (row % 2) * (hexW / 2);
                const cy = row * hexH * 0.75;
                ctx.beginPath();
                for (let j = 0; j < 6; j++) {
                    const angle = (Math.PI / 3) * j - Math.PI / 6;
                    const px = cx + hexSize * Math.cos(angle);
                    const py = cy + hexSize * Math.sin(angle);
                    j === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
                }
                ctx.closePath();
                ctx.stroke();
            }
        }
        ctx.restore();

        for (const p of this._particles) {
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

        const scanX = (this._scanOffset * (w + 60)) - 30;
        ctx.save();
        const scanGrad = ctx.createLinearGradient(scanX - 6, 0, scanX + 6, 0);
        scanGrad.addColorStop(0, 'transparent');
        scanGrad.addColorStop(0.5, cfg.color.replace(',1)', ',0.06)'));
        scanGrad.addColorStop(1, 'transparent');
        ctx.fillStyle = cfg.color;
        ctx.globalAlpha = 0.04;
        ctx.fillRect(scanX - 4, 0, 8, h);
        ctx.restore();

        if (cfg.ringCount >= 4 && Math.random() > 0.88) {
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

        if (this.animFrame) cancelAnimationFrame(this.animFrame);
        const panel = document.getElementById('suspicion_panel');
        if (panel) panel.remove();

        try { window.removeEventListener('resize', () => this._resizeCanvas()); } catch (e) {}

        this._constructor();

        if (saved_titles) this.suspicion_titles = saved_titles;
        if (saved_text) this.suspicion_text = saved_text;

        this.panel_active = false;
    }
}
