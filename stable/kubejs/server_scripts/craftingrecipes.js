

ServerEvents.recipes(event => {
    event.remove([
        {
            mod: "securitycraft",

            not: {
                output: [
                    'securitycraft:keypad_frame',
                    'securitycraft:keypad',
                    'securitycraft:keypad_chest',
                    'securitycraft:keypad_furnace',
                    'securitycraft:keypad_smoker',
                    'securitycraft:keypad_barrel',
                    'securitycraft:keypad_blast_furnace',
                    'securitycraft:door_indestructible_iron_item',
                    'securitycraft:keypad_door_item',
                    'securitycraft:keycard_lv1',
                    'securitycraft:keycard_lv2',
                    'securitycraft:keycard_lv3',
                    'securitycraft:keycard_lv4',
                    'securitycraft:keycard_lv5',
                    'securitycraft:limited_use_keycard'
                ]
            },
        },
        { input: "minecraft:netherrack", type: "create:crushing" },
        {
            output: [
                "flags_that_represent:flag_rig",
                "minecraft:brewing_stand",
                "mts:mtsofficialpack.explosives",
                "mts:mtsofficialpack.solidfuel",
            ],
        },
        {
            input: [
                "minecraft:blaze_powder",
                "minecraft:ender_eye",
                "minecraft:chorus_fruit",
                "minecraft:blaze_rod",

            ],
        },
    ])

    const RecipeIdForRemoval = [
        "tacz:gun/m95",
        "tacz:gun/m107",
        "tacz:gun/m95",
        "tacz:gun/m107",
        "tacz:gun/ai_awp",
        "tacz:gun/timeless50",
        "tacz:gun/deagle",
        "tacz:gun/deagle_golden",
        "tacz:gun/p320",
        "tacz:gun/hk416d",
        "tacz:gun/qbz_95",
        "tacz:gun/type_81",
        "tacz:gun/spr15hb",
        "tacz:gun/mk14",
        "tacz:gun/scar_l",
        "tacz:gun/scar_h",
        "tacz:gun/g36k",
        "tacz:gun/qbz_191",
        "tacz:gun/aa12",
        "tacz:gun/p90",
        "tacz:gun/vector45",
        "tacz:gun/ump45",
        "tacz:gun/m320",
        "tacz:gun/fn_evolys",
        "tacz:gun/m249",
        "tacz:gun/minigun", // TaCZ JS - KubeJS Plugin needed if we want to keep this !!

        //scopes

        "tacz:attachments/scope_contender",
        "tacz:attachments/scope_acog_ta31",
        "tacz:attachments/scope_elcan_4x",
        "tacz:attachments/scope_mk5hd",
        "tacz:attachments/scope_vudu",
        "tacz:attachments/scope_standard_8x",
        "tacz:attachments/scope_qmk152",
        "tacz:attachments/scope_coyote",
        "tacz:attachments/scope_hamr",
        "tacz:attachments/sight_uh1",
        "tacz:attachments/sight_exp3",
        "tacz:attachments/sight_coyote",
        "tacz:attachments/sight_okp7",
        "tacz:attachments/sight_fastfire_rifle",
        "tacz:attachments/sight_acro_rifle",
        "tacz:attachments/sight_t2",
        "tacz:attachments/sight_t1",
        "tacz:attachments/sight_552",
        "tacz:attachments/sight_deltapoint_rifle",
        "tacz:attachments/sight_pk06_rifle",
        "tacz:attachments/sight_rmr_dot",
        "tacz:attachments/sight_pk06_pistol",
        "tacz:attachments/sight_srs_02",
        "tacz:attachments/sight_sro_dot",
        "tacz:attachments/sight_deltapoint_pistol",
        "tacz:attachments/sight_acro_pistol",
        "tacz:attachments/sight_fastfire_pistol",

        // muzzle
        
        "tacz:attachments/muzzle_silencer_phantom_s1",
        "tacz:attachments/muzzle_silencer_ptilopsis",
        "tacz:attachments/muzzle_silencer_sg",
        "tacz:attachments/muzzle_silencer_mirage",
        "tacz:attachments/muzzle_silencer_knight_qd",
        "tacz:attachments/muzzle_silencer_ursus",
        "tacz:attachments/muzzle_silencer_vulture",
        "tacz:attachments/muzzle_brake_mastiff_sg",
        "tacz:attachments/muzzle_brake_cthulhu",
        "tacz:attachments/muzzle_brake_timeless50",
        "tacz:attachments/muzzle_brake_pioneer",
        "tacz:attachments/deagle_golden_long_barrel",
        "tacz:attachments/muzzle_brake_cyclone_d2",
        "tacz:attachments/muzzle_brake_trex",
        "tacz:attachments/muzzle_compensator_trident",

        // lasers
        
        "tacz:attachments/laser_nightstick",
        "tacz:attachments/laser_compact",
        "tacz:attachments/laser_lopro",

        // stock

        "tacz:attachments/stock_ak_12",
        "tacz:attachments/stock_carbon_bone_c5",
        "tacz:attachments/stock_moe",
        "tacz:attachments/stock_sba3",
        "tacz:attachments/stock_tactical_ar",
        "tacz:attachments/stock_hk_slim_line",
        "tacz:attachments/stock_militech_b5",
        "tacz:attachments/stock_m4ss",
        "tacz:attachments/stock_ripstock",
        
        // grips
        "tacz:attachments/grip_cobra",
        "tacz:attachments/grip_rk6",
        "tacz:attachments/grip_magpul_afg_2",
        "tacz:attachments/grip_rk0",
        "tacz:attachments/grip_osovets_black",
        "tacz:attachments/grip_vertical_talon",
        "tacz:attachments/grip_vertical_military",
        "tacz:attachments/grip_vertical_ranger",
        "tacz:attachments/grip_rk1_b25u",
        "tacz:attachments/grip_se_5",
        "tacz:attachments/grip_td",
    ]

    RecipeIdForRemoval.forEach(Id => {
        event.remove({ id: Id })
    })

    // const ReplaceInputList = [
    //     [{ type: "create:mechanical_crafting" }, "minecraft:blaze_rod", Item.of("tfmg:graphite_electrode")],
    // ]

    // ReplaceInputList.forEach(([Filter, Replace, Item]) => {
    //     event.replaceInput(Filter, Replace, Item)
    // })

    const ShapedRecipeList = [
        [Item.of("securitycraft:keycard_lock", 1), ["AA", "BC", "AA"], { A: "#minecraft:stone_crafting_materials", B: "create:electron_tube", C: "minecraft:tinted_glass" }],
        [Item.of("mts:mtsofficialpack.solidfuel", 1), ["A", "B", "C"], { A: "minecraft:sugar", B: "minecraft:coal", C: "minecraft:gunpowder" }],
        [Item.of("mts:mtsofficialpack.explosives", 3), [" A ", "BCB", " D "], { A: "minecraft:slime_ball", B: "minecraft:clay_ball", C: "minecraft:gunpowder", D: "minecraft:tnt" }],
        [Item.of("railways:remote_lens", 1), ["A", "B", "C"], { A: "create:transmitter", B: "create:precision_mechanism", C: "create:brass_sheet" }],
        [Item.of("minecraft:ender_chest", 1), ["AAA", "ABA", "AAA"], { A: "minecraft:obsidian", B: "minecraft:ender_pearl" }],
        [Item.of("mts:mtsofficialpack.irsensor", 1), ["AB ", "BCD", " EF"], { A: "minecraft:ender_pearl", B: "#c:glass_panes/colorless", C: "mts:mtsofficialpack.circuit", D: "mts:mtsofficialpack.copperwire", E: "minecraft:redstone", F: "mts:mtsofficialpack.metaltube" }],
        [Item.of("securitycraft:keycard_holder", 1), ["BCB", "ABA"], { A: "#c:leathers", B: "minecraft:iron_ingot", C: "minecraft:hopper" }],
        [Item.of("securitycraft:keypad_item", 1), ["BBB", "BAB", "BBB"], { A: "minecraft:heavy_weighted_pressure_plate", B: "minecraft:stone_button" }],
        [Item.of("securitycraft:display_case", 1), ["AAA", "ABC", "AAA"], { A: "minecraft:iron_ingot", B: "minecraft:item_frame", C: "#c:glass_panes/colorless" }],
        [Item.of("securitycraft:glow_display_case", 1), ["AAA", "ABC", "AAA"], { A: "minecraft:iron_ingot", B: "minecraft:glow_item_frame", C: "#c:glass_panes/colorless" }],
        [Item.of("securitycraft:universal_key_changer", 1), [" AB", " CA", "C  "], { A: "minecraft:redstone", B: "securitycraft:keycard_lock", C: "minecraft:iron_ingot" }],
        [Item.of("securitycraft:keycard_reader", 1), ["AAA", "BDC", "AAA"], { A: "#minecraft:stone_crafting_materials", B: "create:electron_tube", C: "minecraft:tinted_glass", D: "minecraft:hopper" }],
        [Item.of("securitycraft:security_camera", 1), ["BBB", "CAB", "BBD"], { A: "minecraft:redstone_block", B: "minecraft:iron_ingot", C: "minecraft:tinted_glass", D: "minecraft:stick" }],
        [Item.of("securitycraft:camera_monitor", 1), ["AAA", "ABA", "AAA"], { A: "minecraft:iron_ingot", B: "mts:mtsofficialpack.circuit" }],
        [Item.of("securitycraft:reinforced_iron_trapdoor", 1), ["AAA", "ABA", "AAA"], { A: "minecraft:iron_ingot", B: "minecraft:iron_trapdoor" }],

        // [Item.of("", 1), ["A", "B", "C"], {A: "", B: "", C: ""}],
    ]

    ShapedRecipeList.forEach(([Output, Pattern, Key]) => {
        event.shaped(Output, Pattern, Key).id("steeldominion:crafting_" + Output.id.replace(":", "_"))
    })

    const CustomRecipeList = [
        {
            "type": "create:filling", "ingredients": [
                {
                    "item": "minecraft:deepslate"
                },
                {
                    "type": "neoforge:single",
                    "amount": 250,
                    "fluid": "minecraft:lava"
                }
            ],
            "results": [
                {
                    "id": "minecraft:netherrack"
                }
            ]
        },
        {
            "type": "create:crushing",
            "ingredients": [
                {
                    "item": "minecraft:netherrack"
                }
            ],
            "processing_time": 400,
            "results": [
                {
                    "id": "create:cinder_flour"
                },
                {
                    "chance": 0.5,
                    "id": "create:cinder_flour"
                },
                {
                    "chance": 0.005,
                    "id": "minecraft:ancient_debris"
                },
            ]
        },
        {
            "type": "create:crushing",
            "ingredients": [
                {
                    "item": "minecraft:magma_block"
                }
            ],
            "processing_time": 400,
            "results": [
                {
                    "id": "minecraft:magma_cream"
                },
                {
                    "chance": 0.75,
                    "id": "minecraft:magma_cream"
                },
            ]
        },
    ]

    CustomRecipeList.forEach(Output => {
        event.custom(Output)
    })

})

RecipeViewerEvents.addInformation('item', event => {
    event.add('minecraft:brewing_stand', [
        'Brewing is disabled in the Steel Dominion Network until an alternative is introduced in a future update.'
    ])
})

RecipeViewerEvents.removeEntries('item', event => {
    event.remove('minecraft:tipped_arrow')
    event.remove('minecraft:splash_potion')
    event.remove('minecraft:potion')
    event.remove('minecraft:lingering_potion')
})
