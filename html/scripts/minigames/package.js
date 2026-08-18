class Package {
    constructor() {
        this.item_required = "";
        this.amount_required = 0;
        this.purity = 0;

        this.game_active = true;
        this.imageRenderedH = 0;
        this.imageRenderedW = 0;
        this.screenW = 0;
        this.screenH = 0;

        this.max_flask_volume = 100;
        this.flask_volume = 1.1 * this.max_flask_volume;
        this.flask_tilt = 0;
        this.flask_pos_x = 0;
        this.flask_pos_y = 0;

        this.number_of_bottles = 5;
        this.max_bottle_volume = this.max_flask_volume / this.number_of_bottles;
        this.fill_amount = new Array(this.number_of_bottles).fill(0);
        this.bottle_collect_rects = new Array(this.number_of_bottles).fill(null).map(() => ({ top: 0, left: 0, right: 0 }));

        this.bottleCtxs = [];
        this.flaskCtx = null;

        this.animFrame = null;
        this.lastTS = null;
        this.bottleBubbles = new Array(this.number_of_bottles).fill(null).map(() => []);
        this.bottleRipples = new Array(this.number_of_bottles).fill(null).map(() => ({ phase: 0, amplitude: 0 }));
        this.flask_liquid_phase = 0;
        this.flask_bubbles = [];

        this.dragging = false;
        this.dragLastX = 0;
        this.dragLastY = 0;

        this.droplet_volume = 1.0;

        this.droplets = [];
        this.droplet_spawn_accumulator = 0;
        this.droplet_spawn_interval = 0.1;

        this.collected_one_packaged_liquid = false;

        this.loop = this.loop.bind(this);
        this.onMouseDown = this.onMouseDown.bind(this);
        this.onMouseMove = this.onMouseMove.bind(this);
        this.onMouseUp   = this.onMouseUp.bind(this);
    }

    init(data, crafting_speed, world_location) {
        this.item_required = data.item_required;
        this.amount_required = data.amount_required;
        this.quality = data.quality;
        this.droplet_volume = Math.sqrt(crafting_speed) * this.droplet_volume;
        this.world_location = world_location;

        this.buildUI();
        this.bind_key_events();
    }

    buildUI() {
        document.getElementById('main_container').innerHTML = `
            <div id="package_game">
                <div id="package_image_container">
                    <canvas id="droplet_canvas"></canvas>
                    <canvas id="flask_liquid_canvas"></canvas>
                    <img id="flask_fillable" src="images/flask-fillable.png">
                    <div id="bottles_container">
                        ${(() => {
                            let bottlesHTML = '';
                            for (let i = 1; i <= this.number_of_bottles; i++) {
                                bottlesHTML += `
                                <div class="bottle" id="bottle_${i}">
                                <img class="bottle_fillable_hollow" ${i === 1 ? 'id="some_bottle"' : ''} src="images/bottle-fillable-hollow.png">
                                    <canvas class="package_fillable_liquid_canvas" id="package_fillable_liquid_canvas_${i}"></canvas>
                                    <img class="bottle_fillable_liquid_bottom" src="images/bottle-fillable-liquid-bottom.png" style="display:none">
                                    <img class="bottle_fillable_liquid_top" src="images/bottle-fillable-liquid-top.png" style="display:none">
                                    <img class="bottle_fillable_solid" src="images/bottle-fillable-solid.png">
                                    <img class="bottle_fillable_cap" src="images/bottle-fillable-cap.png" style="display:none">
                                </div>`;
                            }
                            return bottlesHTML;
                        })()}
                    </div>
                </div>
            </div>
        `;

        const mainCanvas = document.getElementById('package_game').getBoundingClientRect();
        this.screenH = mainCanvas.height;
        this.screenW = mainCanvas.width;

        const dropletCanvas = document.getElementById('droplet_canvas');
        dropletCanvas.width  = dropletCanvas.clientWidth;
        dropletCanvas.height = dropletCanvas.clientHeight;
        this.dropletCtx = dropletCanvas.getContext('2d');

        const flaskCanvas = document.getElementById('flask_liquid_canvas');
        flaskCanvas.width  = flaskCanvas.clientWidth;
        flaskCanvas.height = flaskCanvas.clientHeight;
        this.flaskCtx = flaskCanvas.getContext('2d');

        this.bottleCtxs = [];
        for (let i = 1; i <= this.number_of_bottles; i++) {
            const bc = document.getElementById(`package_fillable_liquid_canvas_${i}`);
            bc.width  = bc.clientWidth;
            bc.height = bc.clientHeight;
            this.bottleCtxs.push(bc.getContext('2d'));
        }

        const referenceBottleImg = document.getElementById('some_bottle');
        referenceBottleImg.onload = () => {
            this.setupImageValues();
            this.setupFlask();
            this.computeBottleRects();
        };

        document.addEventListener('mousedown', this.onMouseDown);
        document.addEventListener('mousemove', this.onMouseMove);
        document.addEventListener('mouseup',   this.onMouseUp);

        this.animFrame = requestAnimationFrame(this.loop);
    }

    bind_key_events() {
        this.key_handler = (e) => {
            if (!this.game_active) return;
            if (e.key === 'Escape' || e.key === ' ') {
                this.game_active = false;
                this.game_end();
            }
        };
        document.addEventListener('keydown', this.key_handler);
    }

    computeBottleRects() {
        for (let i = 0; i < this.number_of_bottles; i++) {
            const bottleEl = document.getElementById(`bottle_${i + 1}`);
            if (!bottleEl) continue;

            const solidImg = bottleEl.querySelector('.bottle_fillable_solid');
            if (!solidImg) continue;

            const rect = solidImg.getBoundingClientRect();
            this.bottle_collect_rects[i] = {
                top: rect.top + (0.84 - 0.45 * this.fill_amount[i] / this.max_bottle_volume) * this.imageRenderedH,
                left: rect.left + 0.43 * this.imageRenderedW,
                right: rect.right - 0.43 * this.imageRenderedW,
            };
        }
    }

    onMouseDown(e) {
        this.dragging  = true;
        this.dragLastX = e.clientX;
        this.dragLastY = e.clientY;
    }

    onMouseMove(e) {
        if (!this.dragging) return;
        const dx = e.clientX - this.dragLastX;
        const dy = e.clientY - this.dragLastY;

        this.flask_pos_x += dx;
        this.flask_pos_y += dy;

        this.flask_tilt += dy * 0.01;

        this.dragLastX = e.clientX;
        this.dragLastY = e.clientY;
    }

    onMouseUp() {
        this.dragging = false;
    }

    setupImageValues() {
        const referenceBottleImg = document.getElementById('some_bottle');
        if (!referenceBottleImg) return;

        const elW = referenceBottleImg.clientWidth;
        const elH = referenceBottleImg.clientHeight;
        const natW = referenceBottleImg.naturalWidth;
        const natH = referenceBottleImg.naturalHeight || elH;
        const scale = Math.min(elW / natW, elH / natH);

        this.imageRenderedH = natH * scale;
        this.imageRenderedW = natW * scale;
    }

    setupFlask() {
        const flaskFillableImg = document.getElementById('flask_fillable');
        if (!flaskFillableImg) return;

        flaskFillableImg.style.width = this.imageRenderedH;
        flaskFillableImg.style.height = "auto";
    }

    unbindEvents() {
        document.removeEventListener('mousedown', this.onMouseDown);
        document.removeEventListener('mousemove', this.onMouseMove);
        document.removeEventListener('mouseup',   this.onMouseUp);
        
        if (this.key_handler) {
            document.removeEventListener('keydown', this.key_handler);
        }
    }

    loop(ts) {
        if (this.lastTS === null) this.lastTS = ts;
        const dt = Math.min((ts - this.lastTS) / 1000, 0.05);
        this.lastTS = ts;

        this.updateFlow(dt);
        this.updateDroplets(dt);
        this.updateRealismSystems(dt);

        this.drawFlask();
        this.drawFlaskPolygon();
        this.drawDroplets();
        this.drawBottlesLiquid();

        this.animFrame = requestAnimationFrame(this.loop);
    }

    updateRealismSystems(dt) {
        this.flask_liquid_phase += dt * 4;

        if (this.flask_volume > 0 && Math.random() < 0.25 && this.flask_bubbles.length < 25) {
            this.flask_bubbles.push({
                x: (Math.random() - 0.5) * 0.5 * this.imageRenderedW,
                y: this.imageRenderedH * 0.99,
                speed: 15 + Math.random() * 25,
                r: 1 + Math.random() * 2.5,
                wobbleSpeed: 2 + Math.random() * 3,
                wobblePhase: Math.random() * Math.PI * 2
            });
        }

        for (let i = this.flask_bubbles.length - 1; i >= 0; i--) {
            let b = this.flask_bubbles[i];
            b.y -= b.speed * dt;
            b.wobblePhase += b.wobbleSpeed * dt;
            
            let surfaceY = this.imageRenderedH * (1 - this.flask_volume / this.max_flask_volume) * 0.9;
            if (b.y < surfaceY) {
                this.flask_bubbles.splice(i, 1);
            }
        }

        for (let b = 0; b < this.number_of_bottles; b++) {
            const rip = this.bottleRipples[b];
            if (rip.amplitude > 0) {
                rip.phase += dt * 25;
                rip.amplitude *= 0.93;
                if (rip.amplitude < 0.2) rip.amplitude = 0;
            }

            if (this.fill_amount[b] > 0 && Math.random() < 0.15 && this.bottleBubbles[b].length < 15) {
                this.bottleBubbles[b].push({
                    x: 0.0 * this.imageRenderedW + Math.random() * 0.2 * this.imageRenderedW,
                    y: (this.fill_amount[b] / this.max_bottle_volume) * 0.7 * this.imageRenderedH * Math.random(),
                    speed: 20 + Math.random() * 30,
                    r: 0.8 + Math.random() * 2
                });
            }
            const bList = this.bottleBubbles[b];
            for (let i = bList.length - 1; i >= 0; i--) {
                bList[i].y -= bList[i].speed * dt;
                if (bList[i].y < 0) bList.splice(i, 1);
            }
        }
    }

    updateFlow(dt) {
        if (this.flask_volume <= 0) return;

        const W = this.imageRenderedW, H = this.imageRenderedH;
        if (W === 0 || H === 0) return;

        const tilt    = this.flask_tilt;
        const worldCX = this.flask_pos_x + W * 0.5;
        const worldCY = this.flask_pos_y + H * 0.5;

        const localPoly = this.getFlaskPolygonLocal();
        const worldPoly = localPoly.map(([lx, ly]) =>
            this.rotatePoint(this.flask_pos_x + lx, this.flask_pos_y + ly, worldCX, worldCY, tilt)
        );

        const polyWorldYs = worldPoly.map(p => p[1]);
        const polyBottom = Math.max(...polyWorldYs);
        const polyTop = Math.min(...polyWorldYs);
        const totalHeight = polyBottom - polyTop;

        const frac = Math.max(0, Math.min(1, this.flask_volume / this.max_flask_volume));
        const liquidTopY = this.findLiquidSurfaceY(worldPoly, frac * 0.9);
        const escapeLiquidY = worldPoly[1][1];

        if (liquidTopY <= escapeLiquidY) {
            this.droplet_spawn_accumulator += dt;
            if (this.droplet_spawn_accumulator >= this.droplet_spawn_interval) {
                this.droplet_spawn_accumulator -= this.droplet_spawn_interval;
                
                this.flask_volume = Math.max(0, this.flask_volume - this.droplet_volume);
                this.spawnDroplet(worldPoly[1]);
            }
        } else {
            this.droplet_spawn_accumulator = 0;
        }
    }

    spawnDroplet(spawnPoint) {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        if (W === 0 || H === 0) return;

        this.droplets.push({
            x:     0.02 * this.imageRenderedW + spawnPoint[0],
            y:     spawnPoint[1],
            vx:    (Math.random() - 0.5) * 18,
            vy:    30 + Math.random() * 20,
            r:     10 + Math.random() * 2,
            alpha: 0.85,
            volume: this.droplet_volume,
        });
    }

    pointInPolygon(px, py, poly) {
        let inside = false;
        for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
            const xi = poly[i][0], yi = poly[i][1];
            const xj = poly[j][0], yj = poly[j][1];
            if (((yi > py) !== (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
                inside = !inside;
            }
        }
        return inside;
    }

    updateDroplets(dt) {
        const gravity = 900;

        for (let i = this.droplets.length - 1; i >= 0; i--) {
            const d = this.droplets[i];
            d.vy += gravity * dt;
            d.x  += d.vx  * dt;
            d.y  += d.vy  * dt;

            if (d.y > this.screenH) {
                this.droplets.splice(i, 1);
                continue;
            }

            let caught = false;
            for (let b = 0; b < this.number_of_bottles; b++) {
                const rect = this.bottle_collect_rects[b];
                if (!rect) continue;

                if (this.fill_amount[b] >= this.max_bottle_volume) {
                    continue;
                }

                if (d.x >= rect.left && d.x <= rect.right && d.y >= rect.top) {
                    this.fill_amount[b] = Math.min(
                        this.max_bottle_volume,
                        this.fill_amount[b] + d.volume
                    );
                    if (this.fill_amount[b] >= this.max_bottle_volume) {
                        this.collectPackagedLiquid();
                    }

                    this.computeBottleRects(); // Readjust hitbox
                    this.droplets.splice(i, 1);
                    caught = true;
                    break;
                }
            }

            if (caught) continue;
        }
    }

    drawFlask() {
        const flaskFillableImg = document.getElementById('flask_fillable');
        if (!flaskFillableImg) return;

        const W = this.imageRenderedW || 0;
        const H = this.imageRenderedH || 0;
        const cx = this.flask_pos_x + W * 0.5;
        const cy = this.flask_pos_y + H * 0.5;

        flaskFillableImg.style.left            = `${this.flask_pos_x}px`;
        flaskFillableImg.style.top             = `${this.flask_pos_y}px`;
        flaskFillableImg.style.transformOrigin = `${cx - this.flask_pos_x}px ${cy - this.flask_pos_y}px`;
        flaskFillableImg.style.transform       = `rotate(${this.flask_tilt}rad)`;
    }

    getFlaskPolygonLocal() {
        const W = this.imageRenderedW;
        const H = this.imageRenderedH;
        return [
            [0.4  * W, 0.1  * H],
            [0.62 * W, 0.1  * H],
            [0.62 * W, 0.3  * H],
            [0.85 * W, 1.02 * H],
            [0.16 * W, 1.02 * H],
            [0.4  * W, 0.3  * H],
        ];
    }

    rotatePoint(px, py, cx, cy, angle) {
        const cos = Math.cos(angle);
        const sin = Math.sin(angle);
        const dx = px - cx;
        const dy = py - cy;
        return [
            cx + dx * cos - dy * sin,
            cy + dx * sin + dy * cos,
        ];
    }

    polygonArea(poly) {
        let area = 0;
        for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
            area += (poly[j][0] + poly[i][0]) * (poly[j][1] - poly[i][1]);
        }
        return Math.abs(area) / 2;
    }

    clipPolygonBelowY(poly, clipY) {
        const out = [];
        const n = poly.length;
        for (let i = 0; i < n; i++) {
            const curr = poly[i];
            const prev = poly[(i - 1 + n) % n];
            const currIn = curr[1] >= clipY;
            const prevIn = prev[1] >= clipY;

            if (currIn !== prevIn) {
                const t = (clipY - prev[1]) / (curr[1] - prev[1]);
                out.push([prev[0] + t * (curr[0] - prev[0]), clipY]);
            }
            if (currIn) out.push(curr);
        }
        return out;
    }

    findLiquidSurfaceY(worldPoly, volumeFrac) {
        const ys = worldPoly.map(p => p[1]);
        let lo = Math.min(...ys), hi = Math.max(...ys);

        if (volumeFrac <= 0) return hi;
        if (volumeFrac >= 1) return lo;

        const targetArea = volumeFrac * this.polygonArea(worldPoly);

        for (let i = 0; i < 20; i++) {
            const mid = (lo + hi) / 2;
            const clipped = this.clipPolygonBelowY(worldPoly, mid);
            const area = clipped.length >= 3 ? this.polygonArea(clipped) : 0;
            if (area > targetArea) lo = mid; else hi = mid;
        }
        return (lo + hi) / 2;
    }

    drawFlaskPolygon() {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        if (W === 0 || H === 0) return;

        const ctx = this.flaskCtx;
        if (!ctx) return;

        const canvas = ctx.canvas;

        canvas.style.left            = `${this.flask_pos_x}px`;
        canvas.style.top             = `${this.flask_pos_y}px`;
        canvas.style.transformOrigin = `${W * 0.5}px ${H * 0.5}px`;
        canvas.style.transform       = `rotate(${this.flask_tilt}rad)`;

        const tilt    = this.flask_tilt;
        const worldCX = this.flask_pos_x + W * 0.5;
        const worldCY = this.flask_pos_y + H * 0.5;

        const localPoly = this.getFlaskPolygonLocal();

        const worldPoly = localPoly.map(([lx, ly]) =>
            this.rotatePoint(this.flask_pos_x + lx, this.flask_pos_y + ly, worldCX, worldCY, tilt)
        );

        const polyWorldYs = worldPoly.map(p => p[1]);
        const polyBottom  = Math.max(...polyWorldYs);
        const polyTop     = Math.min(...polyWorldYs);
        const totalHeight = polyBottom - polyTop;

        const frac = Math.max(0, Math.min(1, this.flask_volume / this.max_flask_volume));

        const toLocalCanvas = (wx, wy) => {
            const [rx, ry] = this.rotatePoint(wx, wy, worldCX, worldCY, -tilt);
            return [rx - this.flask_pos_x, ry - this.flask_pos_y];
        };

        const localPolyCanvas = worldPoly.map(([wx, wy]) => toLocalCanvas(wx, wy));

        ctx.clearRect(0, 0, canvas.width, canvas.height);

        ctx.save();

        ctx.beginPath();
        ctx.moveTo(localPolyCanvas[0][0], localPolyCanvas[0][1]);
        for (let i = 1; i < localPolyCanvas.length; i++)
            ctx.lineTo(localPolyCanvas[i][0], localPolyCanvas[i][1]);
        ctx.closePath();
        ctx.fillStyle = 'rgba(44, 160, 190, 0.2)';
        ctx.fill();

        this.drawPolygon(ctx, localPolyCanvas, null, 'rgba(0,0,0,1)');

        if (frac > 0) {
            const safeLiquidTopY = this.findLiquidSurfaceY(worldPoly, frac * 0.9);

            ctx.beginPath();
            ctx.moveTo(localPolyCanvas[0][0], localPolyCanvas[0][1]);
            for (let i = 1; i < localPolyCanvas.length; i++)
                ctx.lineTo(localPolyCanvas[i][0], localPolyCanvas[i][1]);
            ctx.closePath();
            ctx.clip();

            const span = (worldCX + W) * 2;
            const leftX = this.flask_pos_x - span;
            const rightX = this.flask_pos_x + span;
            const segments = 25;
            const step = (rightX - leftX) / segments;

            const gradStart = toLocalCanvas(worldCX, safeLiquidTopY);
            const gradEnd = toLocalCanvas(worldCX, polyBottom);
            let liquidGrad = ctx.createLinearGradient(gradStart[0], gradStart[1], gradEnd[0], gradEnd[1]);
            liquidGrad.addColorStop(0, 'rgba(100, 220, 240, 0.9)'); 
            liquidGrad.addColorStop(0.15, 'rgba(68, 190, 214, 0.85)');
            liquidGrad.addColorStop(1, 'rgba(25, 110, 135, 0.95)');
            ctx.fillStyle = liquidGrad;

            ctx.beginPath();
            let startLocal = toLocalCanvas(leftX, polyBottom + span);
            ctx.moveTo(startLocal[0], startLocal[1]);

            for (let i = 0; i <= segments; i++) {
                let wx = leftX + i * step;
                
                let wave1 = Math.sin(this.flask_liquid_phase + i * 0.3) * 4;
                let wave2 = Math.cos(this.flask_liquid_phase * 1.3 + i * 0.5) * 3;
                
                let amplitudeMultiplier = Math.min(1, frac * 2);
                let wy = safeLiquidTopY + (wave1 + wave2) * amplitudeMultiplier;

                let localPt = toLocalCanvas(wx, wy);
                ctx.lineTo(localPt[0], localPt[1]);
            }

            let brLocal = toLocalCanvas(rightX, polyBottom + span);
            ctx.lineTo(brLocal[0], brLocal[1]);
            ctx.closePath();
            ctx.fill();

            ctx.fillStyle = 'rgba(255, 255, 255, 0.35)';
            for (const b of this.flask_bubbles) {
                let bWorldX = worldCX + b.x + Math.sin(b.wobblePhase) * 6;
                let bWorldY = worldCY - (this.imageRenderedH * 0.5) + b.y;

                let [lx, ly] = toLocalCanvas(bWorldX, bWorldY);
                ctx.beginPath();
                ctx.arc(lx, ly, b.r, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        ctx.restore();
    }

    drawDroplets() {
        const ctx = this.dropletCtx;
        if (!ctx) return;
        ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

        for (const d of this.droplets) {
            ctx.save();
            ctx.globalAlpha = d.alpha;
            ctx.fillStyle = 'rgba(68, 190, 214, 0.85)';
            ctx.beginPath();
            ctx.arc(d.x, d.y, d.r, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }
    }

    drawBottlesLiquid() {
        for (let i = 0; i < this.number_of_bottles; i++) {
            const ctx = this.bottleCtxs[i];
            if (!ctx) continue;

            const canvas = ctx.canvas;
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            const frac = this.fill_amount[i] / this.max_bottle_volume;

            const bottleEl = document.getElementById(`bottle_${i + 1}`);
            if (!bottleEl) continue;

            const capImg    = bottleEl.querySelector('.bottle_fillable_cap');
            const topImg    = bottleEl.querySelector('.bottle_fillable_liquid_top');
            const bottomImg = bottleEl.querySelector('.bottle_fillable_liquid_bottom');

            if (frac <= 0.05) {
                if (capImg)    capImg.style.display = 'none';
                if (topImg)    topImg.style.display = 'none';
                if (bottomImg) bottomImg.style.display = 'none';
                continue;
            }

            if (bottomImg) bottomImg.style.display = '';
            if (topImg)    topImg.style.display    = '';
            if (capImg)    capImg.style.display     = frac > 0.99 ? '' : 'none';

            const shift = frac * 0.9 * 0.49 * this.imageRenderedH;
            topImg.style.transform = `translateY(-${shift}px)`;

            const canvasRect = canvas.getBoundingClientRect();
            const canvasCenterH = canvasRect.left + canvasRect.width / 2;
            const canvasCenterV = canvasRect.top + canvasRect.height / 2;

            const drawX = canvasCenterH - canvasRect.left - 0.16 * this.imageRenderedW;
            const drawW = 0.32 * this.imageRenderedW;
            const drawH = frac * 0.4419 * this.imageRenderedW;
            const drawY = canvasCenterV - canvasRect.top + 0.3303 * this.imageRenderedH - drawH;

            ctx.save();

            let bottleGrad = ctx.createLinearGradient(drawX, drawY, drawX + drawW, drawY);
            bottleGrad.addColorStop(0, 'rgba(41, 153, 178, 0.45)');   // Left shadow edge
            bottleGrad.addColorStop(0.5, 'rgba(78, 214, 240, 0.35)'); // Core refraction glow
            bottleGrad.addColorStop(1, 'rgba(32, 126, 147, 0.50)');   // Right curve shadow
            ctx.fillStyle = bottleGrad;

            const rip = this.bottleRipples[i];
            ctx.beginPath();
            ctx.moveTo(drawX, drawY + drawH);
            ctx.lineTo(drawX, drawY);

            let segments = 20;
            for (let j = 0; j <= segments; j++) {
                let sx = drawX + (drawW * (j / segments));
                let sy = drawY + Math.sin(rip.phase + (j * 0.8)) * rip.amplitude * Math.sin((j / segments) * Math.PI);
                ctx.lineTo(sx, sy);
            }

            ctx.lineTo(drawX + drawW, drawY + drawH);
            ctx.closePath();
            ctx.fill();

            const bList = this.bottleBubbles[i];
            bList.forEach(bubble => {
                let bx = drawX + (bubble.x * (drawW / (0.2 * this.imageRenderedW)));
                let by = drawY + drawH - (bubble.y * (drawH / (0.7 * this.imageRenderedH)));

                if (by > drawY) {
                    ctx.beginPath();
                    ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
                    ctx.arc(bx, by, bubble.r, 0, Math.PI * 2);
                    ctx.fill();
                }
            });

            ctx.restore();
        }
    }

    drawPolygon(ctx, poly, fillStyle, strokeStyle) {
        ctx.beginPath();
        ctx.moveTo(poly[0][0], poly[0][1]);
        for (let i = 1; i < poly.length; i++) {
            ctx.lineTo(poly[i][0], poly[i][1]);
        }
        ctx.closePath();
        if (fillStyle) {
            ctx.fillStyle = fillStyle;
            ctx.fill();
        }
        if (strokeStyle) {
            ctx.strokeStyle = strokeStyle;
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }
    }

    collectPackagedLiquid() {
        this.collected_one_packaged_liquid = true;
        const world_location = this.world_location;
        fetch(`https://${GetParentResourceName()}/collect_packaged_liquid`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ quality: this.quality, world_location }),
        });

        const allFull    = this.fill_amount.every(a => a >= this.max_bottle_volume);
        const canFillAny = this.fill_amount.some(a => a < this.max_bottle_volume) &&
                           this.flask_volume >= 1;

        if (allFull || !canFillAny) {
            this.game_active = false;
            setTimeout(this.game_end.bind(this), 500);
        }
    }

    game_end() {
        this.unbindEvents();
        document.getElementById('main_container').innerHTML = '';
        cancelAnimationFrame(this.animFrame);

        if (this.collected_one_packaged_liquid) {
            fetch(`https://${GetParentResourceName()}/minigame_cancel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    item_required: "",
                    amount_required: 0
                }),
            });
        } else {
            fetch(`https://${GetParentResourceName()}/minigame_cancel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    item_required: this.item_required,
                    amount_required: this.amount_required
                }),
            });
        }
    }
}

// // dev
// let package_minigame = new Package();
// package_minigame.init({
//     item_required: "",
//     amount_required: 0,
//     quality: ""
// });
