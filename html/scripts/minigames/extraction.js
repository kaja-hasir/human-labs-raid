class Extraction {
    constructor() {
        this.recipe = null;
        this.game_active = true;

        this.MIN_ANGLE = 0;
        this.MAX_ANGLE = Math.PI * 2 * 4;
        this.MAX_SPEED = Math.PI * 2 * 1.5;
        this.TANK_MAX = 80;
        this.targetValveAngle = 0;

        this.valveAngle = 0;
        this.isDragging = false;
        this.lastMouseAngle = null;
        this.currentTurnAngle = 0; 
        this.valveCenter = null;
        this.debugDot = null;

        this.qualityTime = 0;
        this.quality_speed = 1.0;
        this.currentQuality = 0.5;
        this.quality_threshold = 0.55;
        this.qualityHistory = [];

        this.tankFill = 0;
        this.goodGas = 0;
        this.totalGas = 0;

        this.bubbles = [];

        this.party = null;

        this.lastTS = null;
        this.animFrame = null;

        this.chartCtx = null;
        this.tankCtx = null;

        this.applyDrag = this.applyDrag.bind(this);
        this.onMouseUp = this.onMouseUp.bind(this);
        this.onTouchMove = this.onTouchMove.bind(this);
        this.loop = this.loop.bind(this);
    }

    init(data, crafting_speed, world_location) {
        this.data = data;
        this.TANK_MAX = (1 / crafting_speed) * this.TANK_MAX;
        this.MAX_SPEED = crafting_speed * this.MAX_SPEED;
        this.quality_speed = Math.sqrt(crafting_speed) * this.quality_speed;
        this.world_location = world_location;
        this.build_ui();
        this.bind_key_events();
    }

    build_ui() {
        document.getElementById('main_container').innerHTML = `
            <div id="extract_game">
                <image id="extract_panel_img" src=images/gas-extraction-panel.png>
                <image id="extract_needle_img" src=images/gas-extraction-panel-gauge-needle.png>
                <image id="extract_valve_img" src=images/gas-extraction-panel-valve.png>
                <div class="extract_panel"><canvas id="extract_chart-canvas"></canvas></div>
                <canvas id="extract_tank-canvas"></canvas>
                <canvas id="extract_smoke-canvas"></canvas>
                <div id="extract_smoke-pos"></div>
            </div>
        `;

        const chartCanvas = document.getElementById('extract_chart-canvas');
        chartCanvas.width = chartCanvas.clientWidth;
        chartCanvas.height = chartCanvas.clientHeight;
        this.chartCtx = chartCanvas.getContext('2d');

        const tankCanvas = document.getElementById('extract_tank-canvas');
        tankCanvas.width = tankCanvas.clientWidth;
        tankCanvas.height = tankCanvas.clientHeight;
        this.tankCtx = tankCanvas.getContext('2d');
        
        const smokeCanvas = document.getElementById('extract_smoke-canvas');
        smokeCanvas.width = smokeCanvas.clientWidth;
        smokeCanvas.height = smokeCanvas.clientHeight;
        this.smokeCtx = smokeCanvas.getContext('2d');
        this.smokePos = document.getElementById('extract_smoke-pos');

        const valveImage = document.getElementById('extract_valve_img');
        valveImage.onload = () => { this.setup_image_variables() };

        this.bind_canvas_events();
        this.animFrame = requestAnimationFrame(this.loop);
    }

    setup_image_variables() {
        const gameViewRect = document.getElementById('extract_game').getBoundingClientRect();

        const el = document.getElementById('extract_valve_img');
        const rect = el.getBoundingClientRect();

        const natW = el.naturalWidth, natH = el.naturalHeight || rect.height;
        const scale = Math.min(rect.width / natW, rect.height / natH);
        
        const H = natH * scale;
        const W = natW * scale;
        
        this.valveCenter = {
            x: rect.left + W * 0.4987,
            y: gameViewRect.height - rect.height * 0.2128 // top is 0 because padding-top, gameViewRect changes size depending on image
        };
    }

    bind_key_events() {
        this.key_handler = (event) => {
            if (this.game_active && event.key === 'Escape') {
                this.game_active = false;
                this.game_end();
            }
        };
        document.addEventListener('keydown', this.key_handler);
    }

    bind_canvas_events() {
        const valve = document.getElementById('extract_valve_img');

        const startDrag = (e) => {
            this.isDragging = true;
            this.lastMouseAngle = this.mouseAngleFromEvent(e);
            this.currentTurnAngle = 0;
        };

        valve.addEventListener('mousedown', startDrag);
        valve.addEventListener('touchstart', (e) => {
            startDrag(e);
            e.preventDefault();
        }, { passive: false });

        window.addEventListener('mousemove', this.applyDrag);
        window.addEventListener('touchmove', this.onTouchMove, { passive: false });
        window.addEventListener('mouseup', this.onMouseUp);
        window.addEventListener('touchend', this.onMouseUp);
    }

    mouseAngleFromEvent(e) {
        if (!this.valveCenter) return 0;
        
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;

        const px = clientX - this.valveCenter.x;
        const py = clientY - this.valveCenter.y;
        return Math.atan2(py, px);
    }

    unbind_canvas_events() {
        window.removeEventListener('mousemove', this.applyDrag);
        window.removeEventListener('touchmove', this.onTouchMove);
        window.removeEventListener('mouseup', this.onMouseUp);
        window.removeEventListener('touchend', this.onMouseUp);
    }

    applyDrag(e) {
        const x = event.clientX;
        const y = event.clientY;
        
        if (!this.isDragging) return;
        
        const targetAngle = this.mouseAngleFromEvent(e);
        let delta = targetAngle - this.lastMouseAngle;
        
        if (delta > Math.PI) delta -= Math.PI * 2;
        if (delta < -Math.PI) delta += Math.PI * 2;
        
        const deltaDegrees = delta * (180 / Math.PI);
        this.currentTurnAngle += deltaDegrees;
        
        const calculatedTarget = this.targetValveAngle + delta;
        this.targetValveAngle = Math.max(this.MIN_ANGLE, Math.min(this.MAX_ANGLE, calculatedTarget));
        
        this.lastMouseAngle = targetAngle;
    }

    onTouchMove(e) {
        this.applyDrag(e);
        e.preventDefault();
    }

    onMouseUp() {
        this.isDragging = false;
        this.lastMouseAngle = null;
    }

    getOpening() {
        return Math.max(0, Math.min(1, this.valveAngle / this.MAX_ANGLE));
    }

    getQuality(t) {
        return Math.max(0, Math.min(1,
            0.5 + Math.sin(t * 0.55) * 0.32 + Math.sin(t * 1.4 + 1.1) * 0.18 +
            Math.sin(t * 0.28 + 2.4) * 0.28 + Math.sin(t * 6.9) * Math.cos(t * 3.3) * 0.07
        ));
    }

    loop(ts) {
        if (this.lastTS === null) this.lastTS = ts;
        const dt = Math.min((ts - this.lastTS) / 1000, 0.05);
        this.lastTS = ts;

        if (this.valveAngle !== this.targetValveAngle) {
            const angleDifference = this.targetValveAngle - this.valveAngle;
            const maxStep = this.MAX_SPEED * dt;

            if (Math.abs(angleDifference) <= maxStep) {
                this.valveAngle = this.targetValveAngle;
            } else {
                this.valveAngle += Math.sign(angleDifference) * maxStep;
            }
        }

        this.qualityTime += dt * this.quality_speed;
        this.currentQuality = this.getQuality(this.qualityTime);
        this.qualityHistory.push(this.currentQuality);
        if (this.qualityHistory.length > 200) this.qualityHistory.shift();

        const opening = this.getOpening();
        if (opening > 0.01) {
            const effectiveQ = opening < 0.3 ? Math.min(1, this.currentQuality + 0.22) : this.currentQuality;
            const flow = opening * 2.2 * dt;
            if (effectiveQ > this.quality_threshold) this.goodGas += flow;
            this.totalGas += flow;
            this.tankFill = Math.min(this.TANK_MAX, this.tankFill + flow * 5);

            if (this.tankFill >= this.TANK_MAX) {
                const purity = this.totalGas > 0 ? this.goodGas / this.totalGas : 0;
                this.tankFill = 0;
                this.goodGas = 0;
                this.totalGas = 0;
                this.collect_gas(purity * 100);
            }
        }

        this.drawChart();
        this.drawTank();
        this.drawSmoke();
        this.updateImages();

        this.animFrame = requestAnimationFrame(this.loop);
    }

    updateImages() {
        const opening = this.getOpening();

        const valveDeg = this.valveAngle * (180 / Math.PI);
        document.getElementById('extract_valve_img').style.transform = `rotate(${valveDeg}deg)`;

        const NEEDLE_MIN_DEG = 280;
        const NEEDLE_MAX_DEG = 0;
        const needleDeg = NEEDLE_MIN_DEG + opening * (NEEDLE_MAX_DEG - NEEDLE_MIN_DEG);
        document.getElementById('extract_needle_img').style.transform = `rotate(${needleDeg}deg)`;
    }

    drawChart() {
        const ctx = this.chartCtx;
        if (!ctx) return;
        const w = ctx.canvas.width, h = ctx.canvas.height;
        ctx.clearRect(0, 0, w, h);

        ctx.strokeStyle = 'rgba(255,255,255,0.06)';
        ctx.lineWidth = 1;
        [0.35, 0.5, 0.65].forEach(l => {
            const y = h - l * h;
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
        });

        const pts = this.qualityHistory.slice(-w);
        if (pts.length < 2) return;
        const step = w / (pts.length - 1);

        const q = this.currentQuality;
        ctx.beginPath();
        pts.forEach((q, i) => {
            const x = i * step, y = h - q * (h - 4) - 2;
            i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
        });
        ctx.strokeStyle = q > 0.65 ? '#97C459' : q > 0.4 ? '#FAC775' : '#F09595';
        ctx.lineWidth = 1.5;
        ctx.stroke();

        const cy = h - q * (h - 4) - 2;
        ctx.beginPath(); ctx.arc(w - 3, cy, 3, 0, Math.PI * 2);
        ctx.fillStyle = q > 0.65 ? '#97C459' : q > 0.4 ? '#FAC775' : '#F09595';
        ctx.fill();
    }

    drawTank() {
        const ctx = this.tankCtx;
        if (!ctx) return;
        const w = ctx.canvas.width, h = ctx.canvas.height;
        ctx.clearRect(0, 0, w, h);

        const opening = this.getOpening();
        const frac = Math.min(1, this.tankFill / this.TANK_MAX);
        const fillHeight = frac * h;
        const fillTop = h - fillHeight;

        ctx.fillStyle = 'rgba(0, 229, 255, 0.4)';
        ctx.fillRect(0, fillTop, w, fillHeight);

        const maxBubbles = Math.floor(opening * frac * 50); 

        if (this.bubbles.length < maxBubbles && Math.random() < 0.6) {
            this.bubbles.push({
                x: Math.random() * w,
                y: 0,
                baseSize: Math.random() * 2 + 1,
                sizePulse: Math.random() * Math.PI,
                speedY: -Math.random() * 0.5 - 0.5,
                wobbleSpeed: Math.random() * 0.05 + 0.02,
                wobbleRange: Math.random() * 1 + 1,
                angle: Math.random() * Math.PI * 2,
                color: this.currentQuality > this.quality_threshold || Math.random() < this.currentQuality ? 'rgba(0, 229, 255, 0.8)' : 'rgba(0, 100, 100, 0.8)'
            });
        }
        
        for (let i = this.bubbles.length - 1; i >= 0; i--) {
            const b = this.bubbles[i];

            b.y -= b.speedY;
            b.angle += b.wobbleSpeed;
            const currentX = b.x + Math.sin(b.angle) * b.wobbleRange;

            b.sizePulse += 0.05;
            const currentSize = Math.max(0.5, b.baseSize + Math.sin(b.sizePulse) * 1.5);

            if (b.y > h || b.y < 0) {
                this.bubbles.splice(i, 1);
                continue;
            }

            ctx.fillStyle = b.color;
            ctx.beginPath();
            ctx.arc(currentX, b.y, currentSize, 0, Math.PI * 2);
            ctx.fill();
        }

        ctx.shadowBlur = 0;
        ctx.shadowOffsetY = 0;
        ctx.shadowColor = 'transparent';
    }
    
    drawSmoke() {
        const ctx = this.smokeCtx;
        if (!ctx) return;

        if (this.party == null) {
            this.party = SmokeMachine(ctx, [255, 255, 255]);
            this.party.start();
        }
    }

    collect_gas(purity) {
        this.bubbles = [];

        const options = {
            minLifetime: 10,
            maxLifetime: 1000,
            minVx: -0.1,
            maxVx: 8,
            minVy: -1,
            maxVy: 0.5,
            minScale: 0,
            maxScale: 1
        };
        const posRect = this.smokePos.getBoundingClientRect();

        this.party.changeColor([
            150 + 50 * (1 - (purity / 100)),
            226 - 26 * (1 - (purity / 100)),
            255 - 55 * (1 - (purity / 100))
        ]);
        this.party.addSmoke(posRect.left, posRect.top, 1500, options);
        const world_location = this.world_location;

        cancelAnimationFrame(this.animFrame);
        fetch(`https://${GetParentResourceName()}/collect_gas`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ purity, world_location })
        })
        .then(response => response.json())
        .then(result => {
            if (!result.success) {
                this.game_end();
            }
        })
        .catch(() => {
            this.game_end();
        });
    }

    game_end() {
        cancelAnimationFrame(this.animFrame);
        document.removeEventListener('keydown', this.key_handler);
        this.unbind_canvas_events();
        document.getElementById('main_container').innerHTML = '';

        fetch(`https://${GetParentResourceName()}/minigame_cancel`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: ""
        });
    }
}

// // dev
// let extraction_minigame = new Extraction();
// extraction_minigame.init({});
