let suspicion = new Suspicion();
let suspicion_setup = false;

window.addEventListener('load', async function() {
    try {
        const response = await fetch(`https://${GetParentResourceName()}/nui_ready`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json'},
            body: JSON.stringify({})
        });
    } catch {
        console.log("Failed to fetch");
    }
});

window.addEventListener('message', function (event) {
    if (event.data.action === "start_minigame") {
        start_minigame(event.data.game_type, event.data.data, event.data.crafting_speed, event.data.location);
    } else if (event.data.action === "setup_suspicion_level") {
        suspicion.init(event.data.data);
        suspicion_setup = true;
    } else if (event.data.action === "show_suspicion_panel") {
        suspicion.show_panel();
    } else if (event.data.action === "suspicion_level") {
        // if (!suspicion_setup) {
        //     console.warn("Suspicion is not setup, so reverting to default text for suspicion panel");
        // }
        suspicion.set_level(event.data.suspicion_level, event.data.suspicion_amount, event.data.suspicion_text);
    } else if (event.data.action === "reset_suspicion_panel") {
        suspicion.reset();
    }
});

function start_minigame(game_type, data, crafting_speed, location) {
    switch (game_type) {
        case 'extract':
            let extraction_minigame = new Extraction();
            extraction_minigame.init(data, crafting_speed, location);
            break;
        case 'stabilize':
            let stabilize_minigame = new Stabilize();
            stabilize_minigame.init(data, crafting_speed, location);
            break;
        case 'package':
            let package_minigame = new Package();
            package_minigame.init(data, crafting_speed, location);
            break;
        default: break;
    }
}
