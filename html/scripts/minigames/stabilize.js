class Stabilize {
    constructor() {
        this.item_required = "";
        this.amount_required = 0;
        this.purity = 0;

        this.game_active = true;
        this.crafting_complete = false;
        this.imageRenderedH = 0;
        this.imageRenderedW = 0;
        this.screenW = 0;
        this.screenH = 0;

        this.pistonPos = 0;
        this.pistonTarget = 0;
        this.isDraggingPiston = false;
        this.pistonDragStartY = null;
        this.pistonDragStartPos = null;
        this.maxPistonOpenAfterSmash = 0;

        this.valveOpen = false;

        this.maxGasOrLiquid = 100.0;
        this.containerGas = this.maxGasOrLiquid;
        this.chamberGas = 0.0;
        this.liquidCollected = 0.0;
        this.gas_flow_rate = 15.0;
        this.maxChamberVolume = 40.0;
        this.maxChamberGasAfterSmash = 0.0;
        this.piston_speed = 0.3;

        this.smashing = false;
        this.bubbles_gas_container = [];
        this.bubbles_pipe_before_valve = [];
        this.bubbles_pipe_after_valve = [];
        this.bubbles_compressor = [];
        this.bubbles_collector = [];
        this.party = null;

        this.animFrame = null;
        this.lastTS = null;
        this.smokeParticles = [];

        this.onPistonMouseMove = this.onPistonMouseMove.bind(this);
        this.onPistonMouseUp = this.onPistonMouseUp.bind(this);
        this.onPistonTouchMove = this.onPistonTouchMove.bind(this);
        this.onPistonTouchEnd = this.onPistonTouchEnd.bind(this);
        this.loop = this.loop.bind(this);
    }

    init(data, crafting_speed, world_location) {
        this.item_required = data.item_required;
        this.amount_required = data.amount_required;
        this.quality = data.quality;
        this.gas_flow_rate = crafting_speed * this.gas_flow_rate;
        this.piston_speed = crafting_speed * this.piston_speed;
        this.world_location = world_location;

        this.build_ui();
        this.bind_key_events();
    }

    build_ui() {
        document.getElementById('main_container').innerHTML = `
            <div id="stabilize_game">
                <div id="stabilize_image_container">
                    <img id="stabilize_panel_img"  src="images/compress-panel.png">
                    <img id="stabilize_piston_top_img"       src="images/compress-panel-top-piston.png">
                    <img id="stabilize_piston_bottom_img"    src="images/compress-panel-bottom-piston.png">
                    <img id="stabilize_valve_open_img"       src="images/compress-panel-valve-open.png"   style="display:none">
                    <img id="stabilize_valve_closed_img"     src="images/compress-panel-valve-closed.png">
                </div>
                <div id="stabilize_piston_hitbox"></div>
                <div id="stabilize_valve_hitbox"></div>
                <canvas id="stabilize_bubble-canvas"></canvas>
                <canvas id="stabilize_smoke-canvas"></canvas>
                <div id="stabilize_smoke-pos"></div>
            </div>
        `;

        const bubbleCanvas = document.getElementById('stabilize_bubble-canvas');
        bubbleCanvas.width  = bubbleCanvas.clientWidth;
        bubbleCanvas.height = bubbleCanvas.clientHeight;
        this.bubbleCtx = bubbleCanvas.getContext('2d');

        const smokeCanvas = document.getElementById('stabilize_smoke-canvas');
        smokeCanvas.width  = smokeCanvas.clientWidth;
        smokeCanvas.height = smokeCanvas.clientHeight;
        this.smokeCtx = smokeCanvas.getContext('2d');
        this.smokePos = document.getElementById('stabilize_smoke-pos');

        this.bind_piston_events();
        this.bind_valve_events();

        const topImg = document.getElementById('stabilize_piston_top_img');
        topImg.onload = () => {
            this.setupImageValues();
            this.setupSmoke();
        };

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

    bind_valve_events() {
        const hitbox = document.getElementById('stabilize_valve_hitbox');
        hitbox.addEventListener('click', () => this.toggleValve());
        hitbox.addEventListener('touchend', (e) => {
            e.preventDefault();
            this.toggleValve();
        }, { passive: false });
    }

    setupImageValues() {
        const topImg = document.getElementById('stabilize_piston_top_img');
        if (!topImg) return;

        const el = topImg;
        const elW = el.clientWidth, elH = el.clientHeight;
        const natW = el.naturalWidth, natH = el.naturalHeight || elH;
        const scale = Math.min(elW / natW, elH / natH);
        
        this.imageRenderedH = natH * scale;
        this.imageRenderedW = natW * scale;
        this.screenW = elW;
        this.screenH = elH;
    }

    setupSmoke() {
        const ctx = this.smokeCtx;
        if (!ctx) return;

        if (this.party == null) {
            this.party = SmokeMachine(ctx, [185, 255, 255]);
            this.party.start();
        }
        
        this.smokePos.style.left = `${this.screenW / 2 + 0.02 * this.imageRenderedW}px`;
        this.smokePos.style.top = `${this.screenH / 2 - 0.026 * this.imageRenderedH}px`;
    }

    toggleValve() {
        this.valveOpen = !this.valveOpen;
        document.getElementById('stabilize_valve_open_img').style.display   = this.valveOpen ? ''     : 'none';
        document.getElementById('stabilize_valve_closed_img').style.display = this.valveOpen ? 'none' : '';
    }

    bind_piston_events() {
        const topHitbox = document.getElementById('stabilize_piston_hitbox');

        topHitbox.addEventListener('mousedown', (e) => {
            this.isDraggingPiston   = true;
            this.pistonDragStartY   = e.clientY;
            this.pistonDragStartPos = this.pistonPos;
        });

        topHitbox.addEventListener('touchstart', (e) => {
            this.isDraggingPiston   = true;
            this.pistonDragStartY   = e.touches[0].clientY;
            this.pistonDragStartPos = this.pistonPos;
            e.preventDefault();
        }, { passive: false });

        window.addEventListener('mousemove', this.onPistonMouseMove);
        window.addEventListener('touchmove', this.onPistonTouchMove, { passive: false });
        window.addEventListener('mouseup',   this.onPistonMouseUp);
        window.addEventListener('touchend',  this.onPistonTouchEnd);
    }

    unbind_piston_events() {
        window.removeEventListener('mousemove', this.onPistonMouseMove);
        window.removeEventListener('touchmove', this.onPistonTouchMove);
        window.removeEventListener('mouseup',   this.onPistonMouseUp);
        window.removeEventListener('touchend',  this.onPistonTouchEnd);
    }

    onPistonMouseMove(e) { this.movePiston(e.clientY); }
    onPistonTouchMove(e) { this.movePiston(e.touches[0].clientY); e.preventDefault(); }
    onPistonMouseUp()    { this.releasePiston(); }
    onPistonTouchEnd()   { this.releasePiston(); }

    movePiston(clientY) {
        if (!this.isDraggingPiston || this.smashing) return;
        const dy = clientY - this.pistonDragStartY;
        const dragPixelRange = 0.068 * this.imageRenderedW;

        this.pistonTarget = Math.max(0, Math.min(1, this.pistonDragStartPos + dy / dragPixelRange));
        this.maxPistonOpenAfterSmash = Math.max(this.maxPistonOpenAfterSmash, 1 - this.pistonTarget);
    }

    releasePiston() {
        if (!this.isDraggingPiston) return;
        this.isDraggingPiston = false;
    }

    triggerSmash() {
        this.spawnSmoke(this.maxChamberGasAfterSmash / this.maxChamberVolume);

        this.liquidCollected += this.chamberGas;
        this.chamberGas = 0;
        this.smashing = true;
        this.pistonTarget = 1;
        this.maxPistonOpenAfterSmash = 0;
        this.maxChamberGasAfterSmash = 0.0;

        const snapDuration = 40;
        const start = performance.now();
        const startPos = this.pistonPos;

        const animate = (now) => {
            const t = Math.min(1, (now - start) / snapDuration);
            this.pistonPos = startPos + (1 - startPos) * (t * t);
            this.updatePistonVisuals();

            if (t < 1) {
                requestAnimationFrame(animate);
            } else {
                this.pistonPos = 1;
                this.smashing  = false;
                this.pistonTarget = 1;
                this.updatePistonVisuals();
            }
        };
        requestAnimationFrame(animate);
    }

    updatePistonVisuals() {
        const topImg = document.getElementById('stabilize_piston_top_img');
        const bottomImg = document.getElementById('stabilize_piston_bottom_img');
        if (!topImg || !bottomImg) return;

        const maxPx = this.imageRenderedH * 0.113;
        const px = this.pistonPos * maxPx;

        topImg.style.transform    = `translateY(${px}px)`;
        bottomImg.style.transform = `translateY(${-px}px)`;
    }

    loop(ts) {
        if (this.lastTS === null) this.lastTS = ts;
        const dt = Math.min((ts - this.lastTS) / 1000, 0.05);
        this.lastTS = ts;

        if (!this.smashing) {
            const diff = this.pistonTarget - this.pistonPos;

            if (Math.abs(diff) > 0.0001) {
                let maxSpeed;
                const closing = diff > 0;

                if (!closing || this.chamberGas < 0.001 || this.pistonPos >= 0.8) {
                    maxSpeed = Infinity;
                } else {
                    const frac_gas_filled = this.chamberGas / this.maxChamberVolume;
                    maxSpeed = this.piston_speed / (frac_gas_filled * (1 + this.pistonPos));
                }

                const step = closing ? Math.min(diff, maxSpeed * dt) : diff;
                this.pistonPos = Math.max(0, Math.min(1, this.pistonPos + step));
                this.updatePistonVisuals();
            }
            
            let smash_position = (1 - this.maxPistonOpenAfterSmash)
                + Math.max(0.65, this.pistonPos) * this.maxPistonOpenAfterSmash;
            if (this.pistonPos >= smash_position && this.chamberGas > 0.001) {
                this.triggerSmash();
            }
        }

        if (this.valveOpen) {
            const maxVol = this.maxChamberVolume * (1 - this.pistonPos);
            const space  = Math.max(0, maxVol - this.chamberGas);
            const flowIn = Math.min(space, this.containerGas, this.gas_flow_rate * dt);
            
            this.chamberGas   += flowIn;
            this.containerGas -= flowIn;
            
            this.maxChamberGasAfterSmash = Math.max(this.maxChamberGasAfterSmash, this.chamberGas);
            
            if (this.game_active && this.liquidCollected > 0.999 * this.maxGasOrLiquid) {
                this.collect_liquid();
            }
        }

        const overflow = this.chamberGas - this.maxChamberVolume * (1 - this.pistonPos);
        if (overflow > 0.001) {
            this.chamberGas      -= overflow;
            this.liquidCollected += overflow;
        }

        this.drawBubbles();

        this.animFrame = requestAnimationFrame(this.loop);
    }
    
    spawnSmoke(fraction_amount) {
        if (!this.party) return;
        const options = {
            minLifetime: 30,
            maxLifetime: 300 + 2700 * fraction_amount,
            minVx: -2 - 5 * fraction_amount * fraction_amount,
            maxVx: 2 + 5 * fraction_amount * fraction_amount,
            minVy: 0,
            maxVy: 0.1,
            minScale: 0,
            maxScale: 1
        };
        const posRect = this.smokePos.getBoundingClientRect();
        this.party.addSmoke(posRect.left, posRect.top, 500 * fraction_amount * fraction_amount, options);
    }

    pointInPolygon(px, py, poly) {
        let inside = false;
        for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
            const [xi, yi] = poly[i], [xj, yj] = poly[j];
            const intersect = ((yi > py) !== (yj > py)) &&
            (px < (xj - xi) * (py - yi) / (yj - yi) + xi);
            if (intersect) inside = !inside;
        }
        return inside;
    }

    randomPointInPoly(poly, maxTries = 50) {
        const xs = poly.map(p => p[0]), ys = poly.map(p => p[1]);
        const minX = Math.min(...xs), maxX = Math.max(...xs);
        const minY = Math.min(...ys), maxY = Math.max(...ys);
        for (let i = 0; i < maxTries; i++) {
            const x = minX + Math.random() * (maxX - minX);
            const y = minY + Math.random() * (maxY - minY);
            if (pointInPolygon(x, y, poly)) return [x, y];
        }
        return null;
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

    drawBubblesInPoly(ctx, opts) {
        const {
            pool,
            polygon,
            maxBubbles,
            spawnChance,
            spawnX = null,
            makeVelocity,
            fillTop = 0.5,
            drawWater = false,
            cullFillTopMul = 1,
        } = opts;
        const xs = polygon.map(p => p[0]);
        const ys = polygon.map(p => p[1]);
        const minX = Math.min(...xs), maxX = Math.max(...xs);
        const polyTop    = Math.min(...ys);
        const polyBottom = Math.max(...ys);
        const polyHeight = polyBottom - polyTop;
        if (drawWater) {
            ctx.save();
            ctx.beginPath();
            ctx.moveTo(polygon[0][0], polygon[0][1]);
            for (let i = 1; i < polygon.length; i++) ctx.lineTo(polygon[i][0], polygon[i][1]);
            ctx.closePath();
            ctx.clip();
            ctx.fillStyle = 'rgba(0, 229, 255, 0.15)';
            ctx.fillRect(minX, fillTop ?? polyTop, maxX - minX, polyBottom - (fillTop ?? polyTop));
            ctx.restore();
        }
        if (pool.length < maxBubbles && Math.random() < spawnChance) {
            const bx = spawnX !== null ? spawnX : minX + Math.random() * (maxX - minX);
            const by = polyTop + Math.random() * polyHeight;
            if (this.pointInPolygon(bx, by, polygon)) {
                pool.push({
                    x: bx,
                    y: by,
                    baseSize: Math.random() * 3 + 1,
                    sizePulse: Math.random() * Math.PI,
                    wobbleSpeed: Math.random() * 0.05 + 0.02,
                    wobbleRange: Math.random() * 8 + 3,
                    angle: Math.random() * Math.PI * 2,
                    speedX: 0,
                    speedY: 0,
                    overflowShrink: null,
                    ...makeVelocity(),
                });
            }
        }
        const overflow = pool.length - maxBubbles;
        if (overflow > 0) {
            for (let i = 0; i < overflow; i++) {
                if (pool[i].overflowShrink === null) pool[i].overflowShrink = pool[i].baseSize;
            }
        }
        ctx.shadowColor = 'rgba(0, 229, 255, 0.5)';
        ctx.shadowBlur = 4;
        ctx.fillStyle = 'rgba(0, 229, 255, 0.7)';
        const cullY = fillTop !== null ? cullFillTopMul * fillTop : -Infinity;
        for (let i = pool.length - 1; i >= 0; i--) {
            const b = pool[i];
            b.x += b.speedX;
            b.y -= b.speedY;
            b.angle += b.wobbleSpeed;
            b.sizePulse += 0.05;
            const currentX = b.x + Math.sin(b.angle) * b.wobbleRange;
            if (!this.pointInPolygon(currentX, b.y, polygon) || b.y < cullY) {
                pool.splice(i, 1);
                continue;
            }
            if (b.overflowShrink !== null) {
                b.overflowShrink -= 0.05;
                if (b.overflowShrink <= 0) {
                    pool.splice(i, 1);
                    continue;
                }
                const shrinkRatio = b.overflowShrink / b.baseSize;
                ctx.globalAlpha = shrinkRatio;
                const currentSize = Math.max(0.5, b.overflowShrink + Math.sin(b.sizePulse) * 1.5 * shrinkRatio);
                ctx.beginPath();
                ctx.arc(currentX, b.y, currentSize, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalAlpha = 1;
            } else {
                const currentSize = Math.max(0.5, b.baseSize + Math.sin(b.sizePulse) * 1.5);
                ctx.beginPath();
                ctx.arc(currentX, b.y, currentSize, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        ctx.shadowBlur  = 0;
        ctx.shadowColor = 'transparent';
        ctx.restore();
    }

    drawBubblesGasContainer(ctx) {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        const cx = this.screenW / 2, cy = this.screenH / 2;
        if (W == 0 || H == 0 || cx == 0 || cy == 0) return;

        const polygon = [
            [cx - 0.379 * W, cy + 0.014 * H],
            [cx - 0.367 * W, cy + 0.014 * H],
            [cx - 0.367 * W, cy + 0.03  * H],
            [cx - 0.354 * W, cy + 0.038 * H],
            [cx - 0.347 * W, cy + 0.047 * H],
            [cx - 0.343 * W, cy + 0.06  * H],
            [cx - 0.343 * W, cy + 0.374 * H],
            [cx - 0.347 * W, cy + 0.387 * H],
            [cx - 0.354 * W, cy + 0.394 * H],
            [cx - 0.372 * W, cy + 0.402 * H],
            [cx - 0.39  * W, cy + 0.395 * H],
            [cx - 0.397 * W, cy + 0.391 * H],
            [cx - 0.402 * W, cy + 0.383 * H],
            [cx - 0.404 * W, cy + 0.376 * H],
            [cx - 0.404 * W, cy + 0.057 * H],
            [cx - 0.399 * W, cy + 0.046 * H],
            [cx - 0.39  * W, cy + 0.037 * H],
            [cx - 0.38  * W, cy + 0.031 * H],
        ];

        const ys = polygon.map(p => p[1]);
        const fillTop  = Math.max(...ys) - 1.0 * (Math.max(...ys) - Math.min(...ys));

        this.drawBubblesInPoly(ctx, {
            pool: this.bubbles_gas_container,
            polygon,
            maxBubbles: 200 * this.containerGas / this.maxGasOrLiquid,
            spawnChance: 0.8,
            fillTop,
            makeVelocity: () => ({
                speedY: (Math.random() - 0.5) * 3.0,
                wobbleRange: Math.random() * 80 + 3,
            }),
        });
    }

    drawBubblesPipeBeforeValve(ctx) {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        const cx = this.screenW / 2,   cy = this.screenH / 2;
        if (W == 0 || H == 0 || cx == 0 || cy == 0) return;

        const polygon = [
            [cx - 0.353 * W, cy - 0.018 * H],
            [cx - 0.33  * W, cy - 0.018 * H],
            [cx - 0.295 * W, cy - 0.027 * H],
            [cx - 0.295 * W, cy - 0.015 * H],
            [cx - 0.325 * W, cy - 0.004 * H],
            [cx - 0.353 * W, cy - 0.004 * H],
        ];

        const ys = polygon.map(p => p[1]);
        const fillTop = Math.max(...ys) - 1.0 * (Math.max(...ys) - Math.min(...ys));

        if (this.valveOpen) {
            this.drawBubblesInPoly(ctx, {
                pool: this.bubbles_pipe_before_valve,
                polygon,
                maxBubbles: 60 * (20 * Math.min(0.05, this.containerGas / this.maxGasOrLiquid)),
                spawnChance: 0.3 * (1.1 - this.chamberGas / this.maxChamberVolume),
                spawnX: polygon[0][0],
                fillTop,
                makeVelocity: () => ({
                    speedX: Math.random() * 2 + 1,
                    speedY: (Math.random() - 0.5) * 0.4,
                    wobbleRange: Math.random() * 2 + 1,
                }),
            });
        } else {
            this.drawBubblesInPoly(ctx, {
                pool: this.bubbles_pipe_before_valve,
                polygon,
                maxBubbles: 20 * (20 * Math.min(0.05, this.containerGas / this.maxGasOrLiquid)),
                spawnChance: 0,
                spawnX: polygon[0][0],
                fillTop,
                makeVelocity: () => ({
                    speedX: Math.random() * 1 + 1,
                    speedY: (Math.random() - 0.5) * 0.4,
                    wobbleRange: Math.random() * 0.5 + 1,
                }),
            });
        }
    }

    drawBubblesPipeAfterValve(ctx) {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        const cx = this.screenW / 2, cy = this.screenH / 2;
        if (W == 0 || H == 0 || cx == 0 || cy == 0) return;

        const polygon = [
            [cx - 0.256 * W, cy - 0.028 * H],
            [cx - 0.021 * W, cy - 0.028 * H],
            [cx - 0.021 * W, cy - 0.014 * H],
            [cx - 0.256 * W, cy - 0.014 * H],
        ];

        const ys = polygon.map(p => p[1]);
        const fillTop = Math.max(...ys) - 1.0 * (Math.max(...ys) - Math.min(...ys));

        if (this.valveOpen) {
            this.drawBubblesInPoly(ctx, {
                pool: this.bubbles_pipe_after_valve,
                polygon,
                maxBubbles: 60 * (20 * Math.min(0.05, this.containerGas / this.maxGasOrLiquid)),
                spawnChance: 0.3 * (1.1 - this.chamberGas / this.maxChamberVolume),
                spawnX: polygon[0][0],
                fillTop,
                makeVelocity: () => ({
                    speedX: Math.random() * 3 + 2,
                    speedY: (Math.random() - 0.5) * 0.4,
                    wobbleRange: Math.random() * 2 + 1,
                }),
            });
        } else {
            this.drawBubblesInPoly(ctx, {
                pool: this.bubbles_pipe_after_valve,
                polygon,
                maxBubbles: 60 * (20 * Math.min(0.05, this.containerGas / this.maxGasOrLiquid)),
                spawnChance: 0,
                spawnX: polygon[0][0],
                fillTop,
                makeVelocity: () => ({
                    speedX: Math.random() * 3 + 2,
                    speedY: (Math.random() - 0.5) * 0.4,
                    wobbleRange: Math.random() * 2 + 1,
                }),
            });
        }
    }

    drawBubblesCompressor(ctx) {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        const cx = this.screenW / 2, cy = this.screenH / 2;
        if (W == 0 || H == 0 || cx == 0 || cy == 0) return;

        const polygon = [
            [cx - 0.019 * W, cy + H * (-0.025 - 0.105 * (1 - this.pistonPos))],
            [cx + 0.062 * W, cy + H * (-0.025 - 0.105 * (1 - this.pistonPos))],
            [cx + 0.062 * W, cy + H * (-0.025 + 0.105 * (1 - this.pistonPos))],
            [cx - 0.019 * W, cy + H * (-0.025 + 0.105 * (1 - this.pistonPos))],
        ];

        const ys = polygon.map(p => p[1]);
        const fillTop = Math.max(...ys) - 1.0 * (Math.max(...ys) - Math.min(...ys));

        this.drawBubblesInPoly(ctx, {
            pool: this.bubbles_compressor,
            polygon,
            maxBubbles: 100 * Math.max(0, this.chamberGas / (this.maxChamberVolume * (1 - this.pistonPos)) - 0.2),
            spawnChance: 0.8,
            fillTop,
            makeVelocity: () => ({
                speedY: (Math.random() - 0.5) * 1.0,
                wobbleRange: Math.random() * 8 + 3,
            }),
        });
    }

    drawBubblesLiquid(ctx) {
        const W = this.imageRenderedW, H = this.imageRenderedH;
        const cx = this.screenW / 2, cy = this.screenH / 2;
        if (W == 0 || H == 0 || cx == 0 || cy == 0) return;

        const polygon = [
            [cx + 0.339 * W, cy + 0.133 * H],
            [cx + 0.385 * W, cy + 0.133 * H],
            [cx + 0.385 * W, cy + 0.15  * H],
            [cx + 0.431 * W, cy + 0.395 * H],
            [cx + 0.428 * W, cy + 0.403 * H],
            [cx + 0.294 * W, cy + 0.401 * H],
            [cx + 0.291 * W, cy + 0.395 * H],
            [cx + 0.339 * W, cy + 0.15  * H],
        ];

        this.drawPolygon(ctx, polygon, null, 'rgba(0,229,255,0.01)');

        const ys = polygon.map(p => p[1]);
        const polyBottom = Math.max(...ys);
        const polyHeight = polyBottom - Math.min(...ys);
        const frac = this.liquidCollected / this.maxGasOrLiquid;
        const fillTop = polyBottom - frac * polyHeight;

        this.drawBubblesInPoly(ctx, {
            pool: this.bubbles_collector,
            polygon,
            maxBubbles: 20,
            spawnChance: 0.6,
            fillTop,
            drawWater: true,
            cullFillTopMul: 0.95,
            makeVelocity: () => ({
                speedY: Math.random() * 0.5 + 0.5,
                wobbleRange: Math.random() * 1 + 1,
            }),
        });

        this.drawPolygon(ctx, polygon, null, 'rgba(0, 229, 255, 0.3)');
    }

    drawBubbles() {
        const ctx = this.bubbleCtx;
        if (!ctx) return;
        const w = ctx.canvas.width, h = ctx.canvas.height;
        ctx.clearRect(0, 0, w, h);

        this.drawBubblesGasContainer(ctx);
        this.drawBubblesPipeBeforeValve(ctx);
        this.drawBubblesPipeAfterValve(ctx);
        this.drawBubblesCompressor(ctx);
        this.drawBubblesLiquid(ctx);
    }

    collect_liquid() {
        const world_location = this.world_location;
        fetch(`https://${GetParentResourceName()}/collect_compressed_gas`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ quality: this.quality, world_location }),
        });

        this.game_active = false;
        this.crafting_complete = true;
        setTimeout(this.game_end.bind(this), 800);
    }

    game_end() {
        this.bubbles_gas_container = [];
        this.bubbles_pipe_before_valve = [];
        this.bubbles_pipe_after_valve = [];
        this.bubbles_compressor = [];
        this.bubbles_collector = [];

        document.removeEventListener('keydown', this.key_handler);
        this.unbind_piston_events();
        document.getElementById('main_container').innerHTML = '';
        cancelAnimationFrame(this.animFrame);

        if (this.crafting_complete) {
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
// let stabilize_minigame = new Stabilize();
// stabilize_minigame.init({});
