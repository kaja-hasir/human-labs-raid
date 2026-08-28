Locale = {}

if Config.language == 'de' then
    Locale.npc = {
        entry = {
            waver_ask = "Guten Tag",
            waver_talk = "Bitte bis zur Schranke vorfahren",
            waver_name = "Human Labs Wächter",
            entry_attendant_ask = "Frage nach einem Zugang",
            entry_attendant_name = "Human Labs Wächter",
            permit_explain = "Wenn Sie eine Lieferung für Human Labs haben, bitte zeigen Sie ihren Zugang",
            show_permit = "Zeige Zugang",
            approved_entry = "Ihr Zugang ist gültig, Sie dürfen eintreten",
            declined_entry = "Sie stehen NICHT auf der Liste und haben keine Zugangskarte, bitte wenden Sie"
        },
        scientist = {
            knock_down_scientist = "Überwältige den Wissenschaftler leise",
            steal_lab_coat = "Klaue den Laborkittel",
            drop_lab_coat = "Ziehe deine alten Klamotten an"
        },
        cat = {
            pet = "Streicheln",
            pet_with_name = "Agentin KJ streicheln",
            inspect_collar = "Halsband anschauen",
            collar_message_title = "Halsband",
            collar_message = "\"Agentin KJ\""
        }
    }
    Locale.suspicion = {
        suspicion_title_0 = "Unentdeckt",
        suspicion_title_1 = "Sperrgebiet",
        suspicion_title_2 = "Verdächtige Aktivität",
        suspicion_title_3 = "Entdeckt",
        suspicion_title_4 = "Alarmiert",

        suspicious_shooting = "Schusswaffengebrauch",
        suspicious_driveby = "Drive by",
        suspicious_reloading = "Waffe Nachladen",
        suspicious_aiming = "Waffe Gezielt",
        suspicious_weapon_drawn = "Waffe Gezogen",
        suspicious_melee = "Nahkampf",
        suspicious_cover = "In Deckung",
        suspicious_movement = "Auffällige Bewegung",
        suspicious_sneaking = "Schleichen",
        suspicious_vehicle_honking = "Hupen",
        suspicious_vehicle_speeding = "Rasen",

        suspicious_lab_entry = "Nur für Befugte",
        suspicious_knock_down = "Wissenschaftler umgenietet",
        changing_clothes = "Umziehen",
        spotted_by_scientist = "Von Wissenschaftler verdächtigt",
        in_lab = "Labor Sperrgebiet",
        reentry_disabled_until = "Deaktiviert bis %02d:%02d",
        reentry_required_police = "Deaktiviert: %d/%d Polizisten",
        reentry_time_range = "Nur zwischen %s möglich"
    }
    Locale.crafting = {
        extract = "Extrahiere Vorläufer",
        extract_disabled = "Extraktion nicht möglich",
        unable_to_carry_more_title = "Crafting",
        unable_to_carry_more_message = "Du kannst nicht mehr tragen",
        stabilize_low_quality = "Stabilisiere Vorläufer (Kontaminiert)",
        stabilize_medium_quality = "Stabilisiere Vorläufer (Moderate Quality)",
        stabilize_high_quality = "Stabilisiere Vorläufer (Hohe Quality)",
        stabilize_perfect_quality = "Stabilisiere Vorläufer (Hervorragende Quality)",
        package_low_quality = "Verpacke stabilien Vorläufer (Kontaminiert)",
        package_medium_quality = "Verpacke stabilien Vorläufer (Moderate Quality)",
        package_high_quality = "Verpacke stabilien Vorläufer (Hohe Quality)",
        package_perfect_quality = "Verpacke stabilien Vorläufer (Hervorragende Quality)",
        crafting_requirements = "Du benötigst zum herstellen %d von %s"
    }
    Locale.elevator = {
        go_up = "Etage -1",
        go_down = "Etage -3"
    }
    Locale.scuba = {
        wear_diving_gear = "Scuba Ausrüstung anziehen",
        wear_diving_gear_unable = "Sauerstoffflaschen leer. Probiere es mit %d PX41 Gasflaschen",
        drop_diving_gear = "Scuba Ausrüstung ablegen"
    }
    Locale.transporter = {
        rob_driver = "Bedrohe den Fahrer um seine Zugangskarte",
        search_transporter = "Durchsuche das Fahrzeug",
        searching_transporter = "Fahrzeug durchsuchen",
        robbing_transporter = "Bedrohung des Fahrers"
    }
else
    Locale.npc = {
        entry = {
            waver_ask = "Good day",
            waver_talk = "Please proceed to the barrier",
            waver_name = "Human Labs Guard",
            entry_attendant_ask = "Ask guard about permits",
            entry_attendant_name = "Human Labs Guard",
            permit_explain = "If you have a delivery for human labs, please show me your permit",
            show_permit = "Show permit",
            approved_entry = "The permit is valid, you are approved and can enter",
            declined_entry = "The permit is NOT valid, please turn around"
        },
        scientist = {
            knock_down_scientist = "Silently knock down scientist",
            steal_lab_coat = "Steal lab coat",
            drop_lab_coat = "Put on your old clothes"
        },
        cat = {
            pet = "Pet cat",
            pet_with_name = "Pet agent KJ",
            inspect_collar = "Inspect collar",
            collar_message_title = "Collar",
            collar_message = "\"Agent KJ\""
        }
    }
    Locale.suspicion = {
        suspicion_title_0 = "Undetected",
        suspicion_title_1 = "Restricted Area",
        suspicion_title_2 = "Suspicious Activity",
        suspicion_title_3 = "Spotted",
        suspicion_title_4 = "Alarmed",

        suspicious_shooting = "Weapon Fired",
        suspicious_driveby = "Drive-by Shooting",
        suspicious_reloading = "Reloading Weapon",
        suspicious_aiming = "Aiming Weapon",
        suspicious_weapon_drawn = "Weapon Drawn",
        suspicious_melee = "Melee Combat",
        suspicious_cover = "Taking Cover",
        suspicious_movement = "Erratic Movement",
        suspicious_sneaking = "Sneaking Around",
        suspicious_vehicle_honking = "Honking",
        suspicious_vehicle_speeding = "Speeding",

        suspicious_lab_entry = "Only for Chemworkers",
        suspicious_knock_down = "Chemworkers knock down",
        changing_clothes = "Changing clothes",
        spotted_by_scientist = "Chemworker is supicious",
        in_lab = "In restricted laboratory",
        reentry_disabled_until = "Disabled until %02d:%02d",
        reentry_required_police = "Disabled: %d/%d police",
        reentry_time_range = "Only between %s possible"
    }
    Locale.crafting = {
        extract = "Extract precursor",
        extract_disabled = "Extraction not possible",
        unable_to_carry_more_title = "Crafting",
        unable_to_carry_more_message = "You cannot carry more",
        stabilize_low_quality = "Stabilize precursor (Low Quality)",
        stabilize_medium_quality = "Stabilize precursor (Medium Quality)",
        stabilize_high_quality = "Stabilize precursor (High Quality)",
        stabilize_perfect_quality = "Stabilize precursor (Perfect Quality)",
        package_low_quality = "Package stable precursor (Low Quality)",
        package_medium_quality = "Package stable precursor (Medium Quality)",
        package_high_quality = "Package stable precursor (High Quality)",
        package_perfect_quality = "Package stable precursor (Perfect Quality)",
        crafting_requirements = "You require %d of %s"
    }
    Locale.elevator = {
        go_up = "Floor -1",
        go_down = "Floor -3"
    }
    Locale.scuba = {
        wear_diving_gear = "Put on scuba gear",
        wear_diving_gear_unable = "Oxygen tanks empty. Try %d PX41 gas instead",
        drop_diving_gear = "Drop scuba gear"
    }
    Locale.transporter = {
        rob_driver = "Rob Driver for their lab permit",
        search_transporter = "Search vehicle",
        searching_transporter = "Searching vehicle",
        robbing_transporter = "Threatening driver"
    }
end
