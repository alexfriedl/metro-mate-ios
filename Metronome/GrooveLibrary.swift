// All grooves are original exercises written for Metro Mate
extension Groove {
    static let library: [Groove] = classics + foundations + funk + linearGrooves + hiHatWork + kickWork + shuffles + accentStudies + chops

    private static let backbeat = "----X-------X---"
    private static let eighths = "x-x-x-x-x-x-x-x-"
    private static let sixteenths = "xxxxxxxxxxxxxxxx"
    private static let silent16 = "----------------"
    private static let silent12 = "------------"

    // Simplified one-bar versions of famous grooves, names say whose feel they are modelled on
    static let classics: [Groove] = [
        Groove("funky-drummer", .classics, "Funky Drummer", level: 3, tempo: 100,
               focus: "Clyde Stubblefield style: sixteenth hats, open barks, ghosts around the backbeat",
               hiHat: "xxxxxxxoxxxxxxox", snare: "----X--g-g--X--g", kick: "x-x-------x--x--"),
        Groove("purdie-shuffle", .classics, "Purdie Shuffle", level: 3, tempo: 92,
               focus: "Bernard Purdie style half-time shuffle, ghosts on every middle triplet",
               hiHat: "x-xx-xx-xx-x", snare: "-g--g-Xg--g-", kick: "x----x-----x"),
        Groove("amen-break", .classics, "Amen Break", level: 3, tempo: 136,
               focus: "G. C. Coleman style break: ride eighths, snare pushing on the a of 2 and 4",
               hiHat: eighths, snare: "----X--X-X--X--X", kick: "x-x-------xx----"),
        Groove("billie-jean", .classics, "Billie Jean", level: 1, tempo: 117,
               focus: "Pop staple: dead straight eighths, kick on 1 and 3, nothing extra",
               hiHat: eighths, snare: backbeat, kick: "x-------x-------"),
        Groove("motown", .classics, "Motown Beat", level: 1, tempo: 120,
               focus: "Snare on every quarter note drives the whole band",
               hiHat: eighths, snare: "X---X---X---X---", kick: "x-------x-x-----"),
        Groove("bossa-nova", .classics, "Bossa Nova", level: 2, tempo: 130,
               focus: "Cross-stick clave over a steady dotted bass drum",
               hiHat: eighths, snare: "x--x--x---x--x--", kick: "x--xx--xx--xx--x"),
        Groove("train-beat", .classics, "Train Beat", level: 2, tempo: 110,
               focus: "Sixteenth snare chug with the backbeat accented, country and rockabilly",
               hiHat: silent16, snare: "ggggXgggggggXggg", kick: "x-------x-------"),
        Groove("boom-bap", .classics, "Boom Bap", level: 1, tempo: 90,
               focus: "Nineties hip hop: lazy kick on the a of 2, fat backbeat",
               hiHat: eighths, snare: backbeat, kick: "x------x-x------"),
        Groove("rosanna-feel", .classics, "Half-Time Shuffle Push", level: 3, tempo: 86,
               focus: "Purdie shuffle variation with the kick pushing into beat 3",
               hiHat: "x-xx-xx-xx-x", snare: "-g--g-X-g-g-", kick: "x----x-x---x")
    ]

    static let foundations: [Groove] = [
        Groove("rock-eighths", .foundations, "Eighth Note Rock", level: 1, tempo: 100,
               focus: "Steady eighths, kick on 1 and 3, snare on 2 and 4",
               hiHat: eighths, snare: backbeat, kick: "x-------x-------"),
        Groove("rock-push", .foundations, "Rock with Kick on &", level: 1, tempo: 100,
               focus: "Extra kick on the & of 3 pushes into beat 4",
               hiHat: eighths, snare: backbeat, kick: "x-------x-x-----"),
        Groove("quarter-ballad", .foundations, "Quarter Note Ballad", level: 1, tempo: 70,
               focus: "Space between the notes, let the backbeat breathe",
               hiHat: "x---x---x---x---", snare: backbeat, kick: "x-----x-x-------"),
        Groove("four-floor", .foundations, "Four on the Floor", level: 1, tempo: 112,
               focus: "Kick on every beat, hats on the offbeats",
               hiHat: "--x---x---x---x-", snare: backbeat, kick: "x---x---x---x---"),
        Groove("disco-open", .foundations, "Disco Open Hat", level: 2, tempo: 116,
               focus: "Open hat on every &, close it exactly on the beat",
               hiHat: "x-o-x-o-x-o-x-o-", snare: backbeat, kick: "x---x---x---x---"),
        Groove("half-time", .foundations, "Half-Time Feel", level: 2, tempo: 80,
               focus: "Snare only on beat 3, the groove feels twice as wide",
               hiHat: eighths, snare: "--------X-------", kick: "x-----x---x-----"),
        Groove("pop-push", .foundations, "Pop Syncopation", level: 2, tempo: 96,
               focus: "Kick on the & of 2 and the a of 3",
               hiHat: eighths, snare: backbeat, kick: "x-----x----x----"),
        Groove("sixteenth-rock", .foundations, "Sixteenth Hat Rock", level: 2, tempo: 88,
               focus: "Even sixteenths with one hand, keep the volume flat",
               hiHat: sixteenths, snare: backbeat, kick: "x-------x-x-----")
    ]

    static let funk: [Groove] = [
        Groove("foundation", .funk, "Sixteenth Foundation", level: 1, tempo: 84,
               focus: "Even sixteenths on the hat, backbeat on 2 and 4",
               hiHat: sixteenths, snare: backbeat, kick: "x-----x---x-----"),
        Groove("ghost-pocket", .funk, "Ghost Note Pocket", level: 1, tempo: 88,
               focus: "Quiet ghost notes around a solid backbeat",
               hiHat: eighths, snare: "--g-X--g-g-gX--g", kick: "x-----x-x-----x-"),
        Groove("ghosted-eighths", .funk, "Ghosted Eighths", level: 1, tempo: 90,
               focus: "One ghost before each backbeat, keep it barely audible",
               hiHat: eighths, snare: "---gX------gX---", kick: "x-----x---x-----"),
        Groove("open-lift", .funk, "Open Hat Lift", level: 2, tempo: 92,
               focus: "Open the hat on the & of 2 and the a of 4",
               hiHat: "xxxxxxoxxxxxxxox", snare: backbeat, kick: "x-x------xx-----"),
        Groove("kick-syncopation", .funk, "Kick Syncopation", level: 2, tempo: 86,
               focus: "Sixteenth note kicks between the hats",
               hiHat: eighths, snare: "----X--g-g--X--g", kick: "x--x-xx---x-x--x"),
        Groove("ghost-fill", .funk, "Ghost Doubles", level: 2, tempo: 84,
               focus: "Two ghosts on either side of each backbeat",
               hiHat: eighths, snare: "-gg-Xgg--gg-Xgg-", kick: "x--x------x--x--"),
        Groove("backbeat-drag", .funk, "Backbeat Drag", level: 2, tempo: 88,
               focus: "Ghosts after the backbeat make it lean back",
               hiHat: eighths, snare: "----X-gg----X-g-", kick: "x-----x---x-x---"),
        Groove("broken-sixteenths", .funk, "Broken Sixteenths", level: 3, tempo: 92,
               focus: "Ghosts under a full sixteenth hat line",
               hiHat: sixteenths, snare: "-g-gX-g--g-gX-gg", kick: "x-x---x--x---x--"),
        Groove("displaced", .funk, "Displaced Backbeat", level: 3, tempo: 90,
               focus: "Snare moves off 4 to the a of 3, the bar leans forward",
               hiHat: sixteenths, snare: "-g--X-g---gX--g-", kick: "x--x--x---x--x--"),
        Groove("late-two", .funk, "Late Two", level: 3, tempo: 86,
               focus: "Backbeat on the e of 2, ghosts keep the time solid",
               hiHat: eighths, snare: "--g--X-g-g--X-g-", kick: "x--x------xx----")
    ]

    static let linearGrooves: [Groove] = [
        linear("linear-basic", "Linear Basic", level: 2, tempo: 84,
               focus: "Kick, hat and snare take turns, nothing lands together",
               sequence: "KHGHAHKHHKGHAHGH"),
        linear("linear-one", "Linear Sixteenths", level: 2, tempo: 80,
               focus: "Never two limbs at once, every note on its own",
               sequence: "KHGHAHKGHKHGAHKG"),
        linear("linear-groups", "Linear Groups of Three", level: 3, tempo: 80,
               focus: "Kick, hat, ghost groups run across the beat",
               sequence: "KHGAHGKHGKHGAHGH"),
        linear("linear-doubles", "Linear Kick Doubles", level: 3, tempo: 84,
               focus: "Two kicks in a row, then straight back to the hands",
               sequence: "KKHGAHKKHGHKAHGH"),
        linear("linear-open", "Linear Open Hat", level: 3, tempo: 92,
               focus: "Open hats on the a of 1 and 3 between kick and snare",
               sequence: "KHGOAHKHHKGOAHGH"),
        linear("linear-shift", "Linear Shifted Backbeat", level: 3, tempo: 88,
               focus: "First backbeat lands on the e of 2",
               sequence: "KHGHHAKHGKHHAHKG")
    ]

    static let hiHatWork: [Groove] = [
        Groove("hat-downbeat-accents", .hiHat, "Downbeat Hat Accents", level: 1, tempo: 90,
               focus: "Accent the quarter notes on the hat, eighths stay soft",
               hiHat: "X-x-X-x-X-x-X-x-", snare: backbeat, kick: "x-------x-x-----"),
        Groove("hat-upbeat-accents", .hiHat, "Upbeat Hat Accents", level: 2, tempo: 90,
               focus: "Accent every & on the hat, a classic disco lift",
               hiHat: "x-X-x-X-x-X-x-X-", snare: backbeat, kick: "x-------x-x-----"),
        Groove("hat-accent-e", .hiHat, "Accent on the e", level: 2, tempo: 84,
               focus: "Sixteenth hats with the accent on every e",
               hiHat: "xXxxxXxxxXxxxXxx", snare: backbeat, kick: "x-----x---x-----"),
        Groove("hat-accent-a", .hiHat, "Accent on the a", level: 3, tempo: 84,
               focus: "Sixteenth hats with the accent on every a",
               hiHat: "xxxXxxxXxxxXxxxX", snare: backbeat, kick: "x-----x---x-----"),
        Groove("hat-open-two-four", .hiHat, "Open on the & of 2 and 4", level: 2, tempo: 100,
               focus: "Open hat right after each backbeat, close on the next beat",
               hiHat: "x-x-x-o-x-x-x-o-", snare: backbeat, kick: "x-------x-x-----"),
        Groove("hat-barks", .hiHat, "Hat Barks", level: 3, tempo: 96,
               focus: "Short open barks on the a of 1 and 3 inside sixteenths",
               hiHat: "xxxoxxxxxxxoxxxx", snare: backbeat, kick: "x-----x---x-----")
    ]

    static let kickWork: [Groove] = [
        Groove("kick-ands", .kick, "Kick on Every &", level: 1, tempo: 90,
               focus: "Kick only on the offbeats, hands stay on the grid",
               hiHat: eighths, snare: backbeat, kick: "--x---x---x---x-"),
        Groove("kick-e", .kick, "Kick on the e", level: 2, tempo: 80,
               focus: "Kick right after each beat, feel the pull",
               hiHat: eighths, snare: backbeat, kick: "-x---x---x---x--"),
        Groove("kick-a", .kick, "Kick on the a", level: 2, tempo: 80,
               focus: "Kick just before each beat, it pushes forward",
               hiHat: eighths, snare: backbeat, kick: "---x---x---x---x"),
        Groove("kick-doubles", .kick, "Double Kicks", level: 2, tempo: 88,
               focus: "Two sixteenth kicks on 1 and on 3",
               hiHat: eighths, snare: backbeat, kick: "xx------xx------"),
        Groove("kick-triples", .kick, "Kick Triplets in Sixteenths", level: 3, tempo: 80,
               focus: "Three kicks in a row leading into the backbeat",
               hiHat: eighths, snare: backbeat, kick: "x-xxx-----xxx---"),
        Groove("kick-run", .kick, "Sixteenth Kick Run", level: 3, tempo: 76,
               focus: "Busy kick line under a simple top, keep the hats even",
               hiHat: eighths, snare: backbeat, kick: "x-xx-x-xx-x--x-x")
    ]

    static let shuffles: [Groove] = [
        Groove("triplet-hats", .shuffle, "Triplet Hats", level: 1, tempo: 80,
               focus: "Three even hats per beat, backbeat on 2 and 4",
               hiHat: "xxxxxxxxxxxx", snare: "---X-----X--", kick: "x-----x-----"),
        Groove("shuffle", .shuffle, "Basic Shuffle", level: 1, tempo: 100,
               focus: "Leave out the middle triplet for the swing",
               hiHat: "x-xx-xx-xx-x", snare: "---X-----X--", kick: "x-----x-----"),
        Groove("shuffle-ghosts", .shuffle, "Shuffle with Ghosts", level: 2, tempo: 92,
               focus: "Ghosts fill the missing triplet on the snare",
               hiHat: "x-xx-xx-xx-x", snare: "-g-X-g-g-X-g", kick: "x-----x-----"),
        Groove("triplet-kick", .shuffle, "Triplet Kick Pickups", level: 2, tempo: 84,
               focus: "Kick on the last triplet leads into 2 and 4",
               hiHat: "x--x--x--x--", snare: "---X-----X--", kick: "x-x---x-x---"),
        Groove("half-shuffle", .shuffle, "Half-Time Shuffle", level: 3, tempo: 76,
               focus: "Snare on 3, ghosts on every middle triplet",
               hiHat: "x-xx-xx-xx-x", snare: "-g--g-X-g--g", kick: "x----xx----x"),
        Groove("six-eight", .shuffle, "Twelve-Eight Ballad", level: 1, tempo: 60,
               focus: "Every triplet on the hat, slow and wide",
               hiHat: "xxxxxxxxxxxx", snare: "---X-----X--", kick: "x-----x-x---")
    ]

    static let accentStudies: [Groove] = [
        Groove("accent-1", .hands, "Accent on the Beat", level: 1, tempo: 80,
               focus: "Accent every downbeat, the taps stay low and even",
               hiHat: silent16, snare: "XxxxXxxxXxxxXxxx", kick: "x---x---x---x---"),
        Groove("accent-e", .hands, "Accent on the e", level: 1, tempo: 80,
               focus: "Move the accent one sixteenth later",
               hiHat: silent16, snare: "xXxxxXxxxXxxxXxx", kick: "x---x---x---x---"),
        Groove("accent-and", .hands, "Accent on the &", level: 1, tempo: 80,
               focus: "Accent the middle of each beat",
               hiHat: silent16, snare: "xxXxxxXxxxXxxxXx", kick: "x---x---x---x---"),
        Groove("accent-a", .hands, "Accent on the a", level: 2, tempo: 80,
               focus: "Accent the last sixteenth before each beat",
               hiHat: silent16, snare: "xxxXxxxXxxxXxxxX", kick: "x---x---x---x---"),
        Groove("accent-ghost", .hands, "Accent and Ghost Contrast", level: 2, tempo: 76,
               focus: "Loud accents, ghosts as quiet as you can play them",
               hiHat: silent16, snare: "XgggXgggXgggXggg", kick: "x---x---x---x---"),
        Groove("accent-pairs", .hands, "Accent Pairs", level: 2, tempo: 76,
               focus: "Two accents in a row, then rest the volume",
               hiHat: silent16, snare: "XXxxxXXxxxXXxxxx", kick: "x---x---x---x---"),
        Groove("accent-triplets", .hands, "Triplet Accents", level: 2, tempo: 72,
               focus: "Accent the first note of each triplet",
               hiHat: silent12, snare: "XxxXxxXxxXxx", kick: "x--x--x--x--"),
        Groove("four-over-three", .hands, "Four over Three", level: 3, tempo: 66,
               focus: "Accent every fourth triplet, the accents float across the beat",
               hiHat: silent12, snare: "XxxxXxxxXxxx", kick: "x--x--x--x--")
    ]

    private static func chop(_ id: String, _ title: String, level: Int, tempo: Int, focus: String,
                             sticking: String, accents: String) -> Groove {
        // Hands play the snare, K in the sticking goes to the kick, accents mark the loud notes
        let snare = String(zip(sticking, accents).map { stick, accent in
            stick == "K" ? "-" : (accent == ">" ? "X" : "x")
        })
        let kick = String(sticking.map { $0 == "K" ? "x" : "-" })
        let silent = String(repeating: "-", count: sticking.count)
        return Groove(id, .chops, title, level: level, tempo: tempo, focus: focus,
                      hiHat: silent, snare: snare, kick: kick, sticking: sticking)
    }

    static let chops: [Groove] = [
        chop("singles", "Single Strokes", level: 1, tempo: 90,
             focus: "Even singles, both hands at the same height and volume",
             sticking: "RLRLRLRLRLRLRLRL", accents: ">---------------"),
        chop("doubles", "Double Strokes", level: 1, tempo: 80,
             focus: "Second stroke as strong as the first, let the stick rebound",
             sticking: "RRLLRRLLRRLLRRLL", accents: ">---------------"),
        chop("paradiddle", "Paradiddle", level: 1, tempo: 80,
             focus: "Accent the first note of each group, the rest stays low",
             sticking: "RLRRLRLLRLRRLRLL", accents: ">---->-->---->--"),
        chop("inverted-paradiddle", "Inverted Paradiddle", level: 2, tempo: 76,
             focus: "Double in the middle of the group, accent the lead hand",
             sticking: "RLLRLRRLRLLRLRRL", accents: ">---->-->---->--"),
        chop("paradiddle-diddle", "Paradiddle-diddle", level: 2, tempo: 72,
             focus: "Six notes per beat as triplets, accent each new group",
             sticking: "RLRRLLRLRRLL", accents: ">-->-->-->--"),
        chop("six-stroke", "Six Stroke Roll", level: 3, tempo: 66,
             focus: "Accented singles frame two soft doubles",
             sticking: "RLLRRLRLLRRL", accents: ">----->-----"),
        chop("rlk-triplets", "RLK Triplets", level: 2, tempo: 80,
             focus: "Right, left, kick in triplets, the classic gospel chop",
             sticking: "RLKRLKRLKRLK", accents: ">-->-->-->--"),
        chop("rllk", "RLLK Fours", level: 2, tempo: 84,
             focus: "Right, left, left, kick in sixteenths, accent the right hand",
             sticking: "RLLKRLLKRLLKRLLK", accents: ">--->--->--->---"),
        chop("rlrk", "RLRK Fours", level: 2, tempo: 84,
             focus: "Alternating hands into the kick, keep the kick as loud as the hands",
             sticking: "RLRKLRLKRLRKLRLK", accents: ">--->--->--->---"),
        chop("rrlk", "RRLK Fours", level: 3, tempo: 80,
             focus: "Right hand double, left, kick, a fast gospel fill shape",
             sticking: "RRLKRRLKRRLKRRLK", accents: ">--->--->--->---"),
        chop("rlkk", "RLKK Fours", level: 3, tempo: 72,
             focus: "Two kicks after the hands, smooth and even",
             sticking: "RLKKRLKKRLKKRLKK", accents: ">--->--->--->---")
    ]
}
