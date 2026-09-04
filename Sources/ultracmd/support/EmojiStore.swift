import Foundation

/// Built-in emoji & symbol search (issue #12). A curated database of common
/// emoji with search-friendly names and keywords; queried by the same fuzzy
/// matcher as everything else. Selecting an entry copies it to the clipboard.
enum EmojiStore {

    struct Entry {
        let emoji: String
        let name: String
        let keywords: [String]
        var searchText: String { "\(name) \(keywords.joined(separator: " "))" }
    }

    static let entries: [Entry] = parse(raw)

    private static func parse(_ raw: String) -> [Entry] {
        raw.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|", omittingEmptySubsequences: false)
            guard parts.count >= 2 else { return nil }
            let emoji = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let name = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let keywords = parts.count > 2
                ? parts[2].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                : []
            return Entry(emoji: emoji, name: name, keywords: keywords)
        }
    }

    /// Top fuzzy matches for a query, pre-warmed for the scorer.
    static func search(_ query: String, limit: Int = 8) -> [Entry] {
        let queryLower = query.lowercased()
        guard queryLower.count >= 2 else { return [] }
        var scored: [(Entry, Double)] = []
        for entry in entries {
            let text = entry.searchText.lowercased()
            guard let match = FuzzySearch.match(queryLower: queryLower, textLower: text) else { continue }
            // Prefer entries whose *name* starts with the query.
            var score = match.score
            if entry.name.lowercased().hasPrefix(queryLower) { score += 40 }
            scored.append((entry, score))
        }
        scored.sort { $0.1 > $1.1 }
        return scored.prefix(limit).map(\.0)
    }

    private static let raw = """
😀|grinning face|happy,smile,joy
😃|smiling face with open mouth|happy,smile,joy
😄|smiling face with open mouth and smiling eyes|happy,smile,joy,laugh
😁|grinning face with smiling eyes|happy,grin,smile
😆|grinning squinting face|laugh,funny,haha,lol
😅|grinning face with sweat|nervous,phew,relief
🤣|rolling on the floor laughing|rofl,lol,laugh
😂|face with tears of joy|lol,crying,laugh,tears
🙂|slightly smiling face|smile,happy
🙃|upside-down face|silly,flip
😉|winking face|wink,flirt
😊|smiling face with smiling eyes|happy,blush,sweet
😇|smiling face with halo|angel,innocent,holy
🥰|smiling face with hearts|love,adore,valentine
😍|smiling face with heart-eyes|love,crush,valentine
🤩|star-struck|wow,amazing,star
😘|face blowing a kiss|kiss,love,valentine
😗|kissing face|kiss
😚|kissing face with closed eyes|kiss
😙|kissing face with smiling eyes|kiss
🥲|smiling face with tear|touched,bittersweet
😋|face savoring food|yummy,delicious,tongue
😛|face with tongue|silly,tongue
😜|winking face with tongue|crazy,silly,wink
🤪|zany face|goofy,crazy,wild
😝|squinting face with tongue|silly,nyah
🤑|money-mouth face|rich,money,cash
🤗|hugging face|hug,comfort
🤭|face with hand over mouth|oops,giggle,shy
🤫|shushing face|quiet,secret,shh
🤔|thinking face|think,hmm,consider
🤐|zipper-mouth face|secret,quiet,sealed
🤨|face with raised eyebrow|skeptical,sus,really
😐|neutral face|meh,neutral,blank
😑|expressionless face|blank,meh
😶|face without mouth|silent,mute,blank
😏|smirking face|smirk,smug,sly
😒|unamused face|annoyed,meh,unimpressed
🙄|face with rolling eyes|eyeroll,annoyed,whatever
😬|grimacing face|awkward,oops,cringe
🤥|lying face|lie,pinocchio,fib
😌|relieved face|relaxed,calm,peace
😔|pensive face|sad,down,pensive
😪|sleepy face|tired,sleepy,yawn
🤤|drooling face|drool,want,yum
😴|sleeping face|sleep,tired,zzz
😷|face with medical mask|sick,mask,ill,covid
🤒|face with thermometer|sick,fever,ill
🤕|face with head-bandage|hurt,injured,bandage
🤢|nauseated face|sick,puke,disgust
🤮|face vomiting|puke,sick,vomit
🤧|sneezing face|sneeze,achoo,sick
🥵|hot face|heat,sweat,hot
🥶|cold face|freezing,cold,ice
🥴|woozy face|dizzy,drunk,woozy
😵|face with crossed-out eyes|dead,dizzy,knocked out
🤯|exploding head|mind blown,shocked,boom
🤠|cowboy hat face|cowboy,western,yeehaw
🥳|partying face|party,celebrate,birthday
😎|smiling face with sunglasses|cool,chill,sunglasses
🤓|nerd face|nerd,geek,smart
🧐|face with monocle|inspect,detective,fancy
😕|confused face|confused,huh,puzzled
😟|worried face|worried,nervous,sad
🙁|slightly frowning face|sad,frown,upset
😮|face with open mouth|wow,surprise,open
😯|hushed face|whoa,surprise
😲|astonished face|shocked,astonished,wow
😳|flushed face|blush,embarrassed,shy
🥺|pleading face|please,puppy,beg
😦|frowning face with open mouth|sad,aww
😧|anguished face|anguish,distress
😨|fearful face|scared,fear,afraid
😰|anxious face with sweat|nervous,anxious,stress
😥|sad but relieved face|sad,phew,relief
😢|crying face|sad,cry,tear
😭|loudly crying face|sob,cry,sad,bawling
😱|face screaming in fear|scream,horror,shock
😖|confounded face|frustrated,confounded
😣|persevering face|struggle,persevere
😞|disappointed face|sad,disappointed,down
😓|downcast face with sweat|sad,stress,sweat
😩|weary face|tired,weary,ugh
😫|tired face|tired,exhausted,sleepy
🥱|yawning face|yawn,bored,tired
😤|face with steam from nose|determined,huff,triumph
😡|enraged face|angry,mad,rage
😠|angry face|angry,mad,grr
🤬|face with symbols on mouth|cursing,swear,angry
😈|smiling face with horns|devil,evil,trick
👿|angry face with horns|devil,angry,evil
💀|skull|dead,skull,death
☠️|skull and crossbones|poison,danger,dead
💩|pile of poo|poop,funny,crap
🤡|clown face|clown,creepy,funny
👹|ogre|monster,demon
👺|goblin|monster,mask
👻|ghost|spooky,halloween,boo
👽|alien|ufo,space,et
🤖|robot|bot,ai,android
😺|grinning cat|cat,happy,smile
😸|grinning cat with smiling eyes|cat,smile
😹|cat with tears of joy|cat,laugh,lol
😻|smiling cat with heart-eyes|cat,love
😼|cat with wry smile|cat,smirk
😽|kissing cat|cat,kiss
🙀|weary cat|cat,shock,whoa
😿|crying cat|cat,sad,cry
😾|pouting cat|cat,annoyed,mad
🙈|see-no-evil monkey|monkey,ignore,shy
🙉|hear-no-evil monkey|monkey,ignore
🙊|speak-no-evil monkey|monkey,quiet,oops
💋|kiss mark|kiss,lipstick,love
💌|love letter|letter,romance,mail
💘|heart with arrow|cupid,love,valentine
💝|heart with ribbon|gift,love,valentine
💖|glowing heart|love,sparkle,glow
💗|growing heart|love,grow
💓|beating heart|love,beat,pulse
💞|revolving hearts|love,couple
💕|two hearts|love,cute,couple
💟|heart decoration|love,heart
❣️|heart exclamation|love,exclaim
💔|broken heart|heartbreak,sad,breakup
❤️|red heart|love,valentine,heart
🩷|pink heart|love,cute,heart
🧡|orange heart|love,heart
💛|yellow heart|love,heart,friendship
💚|green heart|love,heart,eco
💙|blue heart|love,heart,friendship
🩵|light blue heart|love,heart
💜|purple heart|love,heart
🤎|brown heart|love,heart,coffee
🖤|black heart|love,dark,heart
🩶|grey heart|love,heart,gray
🤍|white heart|love,pure,heart
💯|hundred points|100,perfect,score
💢|anger symbol|angry,mad,anime
💥|collision|boom,explode,clash
💫|dizzy|star,spiral,dizzy
💦|sweat droplets|water,splash,sweat
🕳️|hole|hole,empty
💣|bomb|boom,explode
💬|speech balloon|chat,talk,comment
👁️‍🗨️|eye in speech bubble|witness,saw,comment
🗨️|left speech bubble|chat,comment
🗯️|right anger bubble|shout,angry,anime
💭|thought balloon|think,dream,idea
💤|zzz|sleep,tired,bored
👋|waving hand|wave,hello,bye
🤚|raised back of hand|hand,stop
🖐️|hand with fingers splayed|hand,five,hi
✋|raised hand|stop,high five,hand
🖖|vulcan salute|spock,star trek,live long
👌|OK hand|ok,perfect,approve
🤌|pinched fingers|italian,chef kiss,what
🤏|pinching hand|small,tiny,little
✌️|victory hand|peace,victory,two
🤞|crossed fingers|luck,hope,fingers
🫰|hand with index finger and thumb crossed|money,heart,love
🤟|love-you gesture|ily,love,rock
🤘|sign of the horns|rock,metal,punk
🤙|call me hand|shaka,call,surf
👈|backhand index pointing left|left,point
👉|backhand index pointing right|right,point
👆|backhand index pointing up|up,point
🖕|middle finger|rude,gesture
👇|backhand index pointing down|down,point,here
☝️|index pointing up|up,one,point
👍|thumbs up|approve,like,yes,up
👎|thumbs down|dislike,no,down,bad
✊|raised fist|fist,power,solid
👊|oncoming fist|punch,fist,bump
🤛|left-facing fist|fist,bump
🤜|right-facing fist|fist,bump
👏|clapping hands|applause,clap,bravo
🙌|raising hands|hooray,praise,yay
👐|open hands|open,hug,jazz
🤲|palms up together|pray,offer,beg
🤝|handshake|deal,agreement,partnership
🙏|folded hands|pray,thanks,please,namaste
✍️|writing hand|write,note,sign
💅|nail polish|nails,manicure,fab
🤳|selfie|selfie,camera,phone
💪|flexed biceps|strong,muscle,gym
🦾|mechanical arm|robot,prosthetic,strong
🧠|brain|smart,think,mind
👀|eyes|look,see,watch
👁️|eye|look,see,watch
👄|mouth|lips,kiss,mouth
🦷|tooth|teeth,dentist
👅|tongue|taste,lick,silly
👂|ear|listen,hear,ear
👃|nose|smell,sniff
👶|baby|infant,newborn,child
🧒|child|kid,young
👦|boy|kid,male,child
👧|girl|kid,female,child
🧑|person|adult,human
👨|man|male,guy,dad
👩|woman|female,lady,mom
🧓|older person|elder,senior
👴|old man|grandpa,elder
👵|old woman|grandma,elder
🙍|person frowning|frown,upset
🙎|person pouting|pout,annoyed
🙅|person gesturing no|no,refuse,deny
🙆|person gesturing OK|ok,yes,dance
💁|person tipping hand|sassy,info,whatever
🙋|person raising hand|me,pick,question
🧏|deaf person|deaf,hearing
🙇|person bowing|sorry,bow,respect
🤦|person facepalming|facepalm,smh,ugh
🤷|person shrugging|shrug,idk,whatever
👮|police officer|cop,police
🕵️|detective|spy,sleuth
💂|guard|guard,uk
🥷|ninja|stealth,assassin
👷|construction worker|build,hard hat
🫅|person with crown|royal,king,queen
🤴|prince|royal,king
👸|princess|royal,queen
👳|person wearing turban|turban
🤵|person in tuxedo|groom,formal,wedding
👰|person with veil|bride,wedding
🤰|pregnant woman|pregnant,baby
🤱|breast-feeding|nurse,baby,feed
👼|baby angel|angel,baby,cute
🎅|Santa Claus|santa,christmas,xmas
🤶|Mrs. Claus|santa,christmas
🦸|superhero|hero,cape,power
🦹|supervillain|villain,evil
🧙|mage|wizard,magic,witch
🧚|fairy|magic,wings,sparkle
🧛|vampire|dracula,halloween,fangs
🧜|merperson|mermaid,merman,sea
🧝|elf|fantasy,lotr,pointy ears
🧞|genie|wish,magic,lamp
🧟|zombie|undead,halloween,brain
🧧|red envelope|money,gift,lucky
💃|woman dancing|dance,party, salsa
🕺|man dancing|dance,party,disco
👯|people with bunny ears|bunny,dance,twins
🧑‍🤝‍🧑|people holding hands|friends,couple,together
👫|woman and man holding hands|couple,date,love
👬|men holding hands|couple,gay,friends
👭|women holding hands|couple,lesbian,friends
👨‍👩‍👦|family|family,parents,child
🧑‍💻|technologist|developer,coder,programmer
🧑‍🍳|cook|chef,kitchen,cooking
🧑‍🎓|student|study,college,school
🧑‍🎤|singer|music,rockstar,mic
🧑‍🏫|teacher|teach,school,class
🧑‍🏭|factory worker|worker,industry
🧑‍🚀|astronaut|space,rocket,nasa
🧑‍⚕️|health worker|doctor,nurse,medic
🧑‍⚖️|judge|court,law,justice
🧑‍✈️|pilot|plane,aviator,fly
🏃|person running|run,jog,exercise
🚶|person walking|walk,stroll
🧗|person climbing|climb,mountain,rock
⛹️|person bouncing ball|basketball,sports
🏋️|person lifting weights|gym,workout,lift
🚴|person cycling|bike,cycling,sport
🚵|person mountain biking|mtb,bike,trail
🤸|person cartwheeling|gymnastics,flip
🤼|people wrestling|wrestle,fight
🤽|person playing water polo|water,polo
🤾|person playing handball|handball
🤹|person juggling|juggle,circus
🧘|person in lotus position|yoga,meditate,zen
🛀|person taking bath|bath,relax,tub
🛌|person in bed|sleep,bed,rest
🍫|chocolate|candy,sweet,dessert
🍕|pizza|food,italian,slice
🍔|hamburger|burger,fast food,beef
🍟|french fries|fries,potato,fast food
🌭|hot dog|sausage,frankfurter
🥨|pretzel|bakery,snack
🧀|cheese|dairy,wedge
🥚|egg|breakfast,protein
🍳|cooking|fried egg,breakfast,cook
🥞|pancakes|breakfast,syrup,flapjack
🧇|waffle|breakfast,brussels
🥓|bacon|pork,breakfast
🍗|poultry leg|chicken,drumstick,meat
🍖|meat on bone|meat,pork,ham
🌮|taco|mexican,food
🌯|burrito|mexican,wrap
🥙|stuffed flatbread|gyro,pita,wrap
🥪|sandwich|lunch,sub,sandwich
🍿|popcorn|movie,cinema,snack
🧂|salt|seasoning,salt
🥫|canned food|can,tin
🍱|bento box|japanese,lunch,box
🍚|cooked rice|rice,bowl,asian
🍛|curry rice|curry,indian,rice
🍜|steaming bowl|ramen,noodles,soup
🍣|sushi|japanese,fish,raw
🐟|fish|seafood,swim
🐠|tropical fish|fish,ocean,colorful
🐡|blowfish|fish,puffer,ocean
🦐|shrimp|seafood,prawn
🦑|squid|seafood,calamari
🦀|crab|seafood,crustacean
🦞|lobster|seafood,crustacean
🍤|fried shrimp|tempura,seafood,ebi
🍙|rice ball|onigiri,japanese
🍘|rice cracker|senbei,japanese,snack
🍥|fish cake with swirl|naruto,japanese
🥮|moon cake|mid-autumn,pastry
🍢|oden|japanese,skewer
🍡|dango|japanese,sweet,dessert
🍧|shaved ice|dessert,ice,hawaiian
🍨|ice cream|dessert,soft serve
🍦|soft ice cream|dessert,cone,vanilla
🥧|pie|dessert,apple,pie
🧁|cupcake|dessert,bakery,sweet
🎂|birthday cake|birthday,celebrate,cake
🍰|shortcake|cake,dessert,strawberry
🧃|beverage box|juice,drink,box
🥤|cup with straw|soda,drink,fast food
🧋|bubble tea|boba,milk tea,tapioca
☕|hot beverage|coffee,tea,latte,espresso
🫖|teapot|tea,pot,brew
🍵|teacup|green tea,japanese,matcha
🍺|beer|drink,alcohol,pint
🍻|beers|cheers,beer,party
🥂|clinking glasses|cheers,champagne,toast
🍷|wine glass|wine,drink,alcohol
🥃|tumbler glass|whiskey,bourbon,scotch
🍸|cocktail glass|martini,cocktail,bar
🍹|tropical drink|cocktail,piña colada
🍾|bottle with popping cork|champagne,celebrate,new year
🥛|glass of milk|milk,dairy,drink
💧|droplet|water,drop,drip
🌊|water wave|wave,ocean,sea
🎃|jack-o-lantern|halloween,pumpkin,spooky
🎄|Christmas tree|christmas,xmas,holiday
🎆|fireworks|fireworks,celebrate,festival
🎇|sparkler|firework,new year
🧨|firecracker|dynamite,boom
✨|sparkles|shine,sparkle,magic,clean
🎈|balloon|party,birthday,celebrate
🎉|party popper|party,celebrate,congrats
🎊|confetti ball|party,celebrate
🎋|tanabata tree|japanese,festival,wish
🎍|Japanese bamboo|new year,japanese
🎎|Japanese dolls|japanese,daruma
🎏|carp streamer|japanese,koinobori
🎐|wind chime|japanese,furin,summer
🎑|moon viewing ceremony|japanese,tsukimi
🎀|ribbon|bow,cute,girl
🎁|gift|present,birthday,box
🎗️|reminder ribbon|awareness,ribbon
🎟️|admission tickets|ticket,event
🎫|ticket|movie,concert,event
🏆|trophy|win,award,first place
🥇|1st place medal|gold,first,winner
🥈|2nd place medal|silver,second
🥉|3rd place medal|bronze,third
⚽|soccer ball|football,sport,soccer
⚾|baseball|sport,ball
🥎|softball|sport,ball
🏀|basketball|sport,hoops
🏐|volleyball|sport,ball
🏈|american football|sport,football,nfl
🎾|tennis|sport,racket,ball
🎳|bowling|sport,strike,pins
🏏|cricket game|sport,bat
🏒|hockey|sport,ice,puck
🏓|ping pong|table tennis,paddle
🏸|badminton|sport,shuttlecock
🥊|boxing glove|boxing,fight
🥋|martial arts uniform|karate,judo,taekwondo
🥌|curling stone|curling,winter
⛳|flag in hole|golf,sport
🎣|fishing pole|fish,angling
🤿|diving mask|diving,scuba,snorkel
🎽|running shirt|marathon,running
🎿|skis|ski,winter,snow
🛷|sled|sleigh,winter,snow
🎯|direct hit|target,bullseye,goal
🪀|yo-yo|toy,yoyo
🪁|kite|fly,wind,toy
🎮|video game controller|game,gaming,controller
🕹️|joystick|game,arcade,retro
🎲|dice|game,random,roll
🧩|puzzle piece|puzzle,solve,piece
🎨|artist palette|art,paint,design
🧵|thread|sewing,needle,craft
🧶|yarn|knit,wool,craft
🎼|musical score|music,notes,score
🎤|microphone|sing,karaoke,mic
🎧|headphone|music,audio,listen
📻|radio|music,broadcast,retro
🎷|saxophone|jazz,music,sax
🎸|guitar|music,rock,acoustic
🎹|musical keyboard|piano,music,keys
🎺|trumpet|music,brass,jazz
🎻|violin|music,strings,classical
🥁|drum|music,percussion,beat
🎬|clapper board|movie,film,action
📱|mobile phone|phone,iphone,smartphone
📲|mobile phone with arrow|phone,download,share
☎️|telephone|phone,call,old
📞|telephone receiver|phone,call
📟|pager|beeper,retro
📠|fax machine|fax,retro,office
🔋|battery|power,charge,energy
🪫|low battery|empty,charge,low
🔌|electric plug|power,plug,electric
💻|laptop|computer,macbook,dev
🖥️|desktop computer|computer,imac,monitor
🖨️|printer|print,office,paper
⌨️|keyboard|typing,keys,mechanical
🖱️|computer mouse|mouse,click,pointer
💽|computer disk|floppy,retro,storage
💾|floppy disk|save,retro,storage
💿|optical disk|cd,disc,music
📀|dvd|disc,movie
🧮|abacus|math,count,calculator
🎥|movie camera|film,video,record
📷|camera|photo,picture,shoot
📸|camera with flash|photo,picture
📹|video camera|video,record,camcorder
📼|videocassette|vhs,retro,tape
🔍|magnifying glass tilted right|search,find,zoom
🔎|magnifying glass tilted left|search,find,inspect
🕯️|candle|light,wax,cozy
💡|light bulb|idea,tip,innovate
🔦|flashlight|light,torch,dark
🏮|red paper lantern|lantern,japanese,china
🪔|diya lamp|diwali,light,oil
📔|notebook with decorative cover|journal,diary,note
📕|closed book|book,read,red
📖|open book|book,read,library
📗|green book|book,read
📘|blue book|book,read
📙|orange book|book,read
📚|books|library,study,read
📓|notebook|notes,journal,school
📒|ledger|notes,accounting
📃|page with curl|document,paper,page
📜|scroll|paper,history,old
📄|page facing up|document,paper,file
📰|newspaper|news,press,media
🗞️|rolled-up newspaper|news,press
📑|bookmark tabs|tabs,document,mark
🔖|bookmark|save,mark,favorite
🏷️|label|tag,price,discount
💰|money bag|money,cash,rich
🪙|coin|money,gold,cash
💵|dollar banknote|money,cash,dollar
💴|yen banknote|money,yen,japan
💶|euro banknote|money,euro
💷|pound banknote|money,pound,gbp
💸|money with wings|money,transfer,spend
💳|credit card|payment,card,bank
🧾|receipt|invoice,bill,accounting
✉️|envelope|mail,email,letter
📧|e-mail|email,mail,inbox
📨|incoming envelope|email,inbox,receive
📩|envelope with arrow|email,send,outbox
📤|outbox tray|send,upload,email
📥|inbox tray|receive,inbox,email
📦|package|box,parcel,ship
📫|closed mailbox with lowered flag|mailbox,mail
📮|postbox|mail,letter,send
🗳️|ballot box|vote,election
✏️|pencil|write,edit,pencil
✒️|black nib|pen,write,fountain
🖋️|fountain pen|write,pen,elegant
🖊️|pen|write,ballpoint
🖌️|paintbrush|paint,art,brush
🖍️|crayon|draw,color,kids
📝|memo|note,write,memo
💼|briefcase|work,business,job
📁|folder|directory,file,folder
📂|open folder|directory,file,open
🗂️|card index dividers|organize,files
📅|calendar|date,calendar,schedule
📆|tear-off calendar|date,calendar,daily
🗒️|spiral notepad|note,write,pad
🗓️|spiral calendar|date,calendar,month
📇|card index|contacts,rolodex
📈|chart increasing|growth,chart,up,stats
📉|chart decreasing|decline,chart,down
📊|bar chart|chart,data,stats,graph
📋|clipboard|copy,paste,board
📌|pushpin|pin,mark,attach
📍|round pushpin|location,pin,here,maps
📎|paperclip|attach,clip,fasten
🖇️|linked paperclips|attachment,link
📏|straight ruler|measure,ruler,school
📐|triangular ruler|measure,set square
✂️|scissors|cut,clip,scissors
🗃️|card file box|archive,storage
🗄️|file cabinet|files,storage,office
🗑️|wastebasket|trash,delete,bin
🔒|locked|lock,secure,private
🔓|unlocked|unlock,open,security
🔐|locked with key|lock,secure,key
🔑|key|key,password,access
🗝️|old key|key,vintage,door
🔨|hammer|build,tool,fix
🪓|axe|chop,wood,tool
⛏️|pick|mine,dig,tool
🔫|water pistol|gun,toy,squirt
🪃|boomerang|throw,return,australia
🏹|bow and arrow|archery,cupid,arrow
🛡️|shield|protect,security,guard
🔧|wrench|tool,fix,settings
🔩|nut and bolt|hardware,tool,fasten
⚙️|gear|settings,config,preferences
🗜️|clamp|tool,press,compress
⚖️|balance scale|justice,law,weigh
🦯|white cane|blind,accessibility
🔗|link|chain,url,link
⛓️|chains|chain,locked
🧰|toolbox|tools,fix,repair
🧲|magnet|magnet,attract,science
⚗️|alembic|chemistry,experiment,lab
🧪|test tube|science,lab,experiment
🧫|petri dish|science,lab,bacteria
🧬|dna|genetics,science,biology
🔬|microscope|science,lab,examine
🔭|telescope|astronomy,space,observe
📡|satellite antenna|signal,satellite,space
💉|syringe|shot,vaccine,medicine
🩸|drop of blood|blood,medical,donate
💊|pill|medicine,drug,health
🩹|adhesive bandage|bandaid,heal,ouch
🩺|stethoscope|doctor,medical,health
🚪|door|door,enter,exit
🛗|elevator|lift,elevator
🪞|mirror|mirror,reflect
🪟|window|window,glass
🛏️|bed|sleep,bedroom,rest
🛋️|couch and lamp|sofa,lounge,furniture
🪑|chair|seat,furniture,chair
🚽|toilet|bathroom,wc,flush
🚿|shower|bath,water,clean
🛁|bathtub|bath,relax,tub
🧴|lotion bottle|lotion,moisturizer,skincare
🧷|safety pin|pin,diaper,fasten
🧹|broom|sweep,clean,witch
🧺|basket|laundry,shopping,picnic
🧻|roll of paper|toilet paper,tp
🧼|soap|soap,wash,clean
🧽|sponge|sponge,clean,absorb
🧯|fire extinguisher|fire,safety,extinguish
🛒|shopping cart|cart,shop,grocery
🚬|cigaret|smoke,cigaret
⚰️|coffin|death,funeral,coffin
⚱️|urn|ashes,funeral
🗿|moai|stone,statue,easter island
🪧|placard|sign,protest,placard
🏧|ATM sign|atm,bank,cash
🚮|litter in bin sign|trash,litter
♿|wheelchair symbol|accessibility,wheelchair
🚹|men's room|men,toilet
🚺|women's room|women,toilet
🚻|restroom|toilet,bathroom
🚼|baby symbol|baby,diaper
🚾|water closet|toilet,wc
🛂|passport control|passport,border
🛃|customs|customs,border
🛄|baggage claim|luggage,airport
🛅|left luggage|locker,storage
⚠️|warning|warning,caution,danger
🚸|children crossing|children,school,crossing
⛔|no entry|stop,forbidden,no
🚫|prohibited|no,forbidden,banned
🚳|no bicycles|no,bike,banned
🚭|no smoking|no,smoke,banned
🚯|no littering|no,litter,banned
🚱|non-potable water|no,water,drink
🚷|no pedestrians|no,walk,banned
📵|no mobile phones|no,phone,banned
🔞|18|adults only,18,nsfw
☢️|radioactive|radioactive,danger,nuclear
☣️|biohazard|biohazard,danger,toxic
⬆️|up arrow|up,arrow,north
↗️|up-right arrow|diagonal,arrow,northeast
➡️|right arrow|right,arrow,east
↘️|down-right arrow|diagonal,arrow,southeast
⬇️|down arrow|down,arrow,south
↙️|down-left arrow|diagonal,arrow,southwest
⬅️|left arrow|left,arrow,west
↖️|up-left arrow|diagonal,arrow,northwest
↕️|up-down arrow|vertical,arrow
↔️|left-right arrow|horizontal,arrow
↩️|right arrow curving left|return,undo,reply
↪️|left arrow curving right|forward,share
⤴️|right arrow curving up|up,forward
⤵️|right arrow curving down|down,forward
🔃|clockwise vertical arrows|refresh,reload,cycle
🔄|counterclockwise arrows|refresh,reload,rotate
🔙|BACK arrow|back,previous
🔚|END arrow|end,last
🔛|ON! arrow|on,start
🔜|SOON arrow|soon,later
🔝|TOP arrow|top,up,best
🕉️|om|hindu,sacred,om
✡️|star of David|judaism,jewish,star
☸️|wheel of dharma|buddhism,dharma
☯️|yin yang|balance,tao,taiji
✝️|latin cross|christian,cross
☦️|orthodox cross|orthodox,christian
☪️|star and crescent|islam,muslim
☮️|peace symbol|peace,hippie
🕎|menorah|judaism,hanukkah
🔯|six pointed star with middle dot|star,fortune
♻️|recycling symbol|recycle,eco,green
🔱|trident emblem|trident,poseidon
📛|name badge|badge,name,id
🔥|fire|hot,fire,lit,flame
✴️|eight pointed star|sparkle,star
🌟|glowing star|star,shine,favorite
🌠|shooting star|wish,star,falling
🌬️|wind|wind,blow,air
⛄|snowman|winter,snow,cold
🌍|globe showing Europe-Africa|world,earth,globe
🌎|globe showing Americas|world,earth,globe
🌏|globe showing Asia-Australia|world,earth,globe
🌐|globe with meridians|internet,web,global
🌵|cactus|desert,plant,succulent
🌲|evergreen tree|tree,forest,pine
🌳|deciduous tree|tree,forest,oak
🌴|palm tree|palm,tropical,beach
🌱|seedling|plant,grow,sprout
🌿|herb|plant,leaf,green
☘️|shamrock|irish,clover,lucky
🍀|four leaf clover|luck,irish,clover
🍁|maple leaf|canada,fall,autumn
🍂|fallen leaves|autumn,fall,leaves
🍃|leaf fluttering in wind|leaf,wind,spring
🍇|grapes|fruit,grape,wine
🍈|melon|fruit,melon
🍉|watermelon|fruit,summer,melon
🍊|tangerine|orange,fruit,citrus
🍋|lemon|fruit,citrus,sour
🍌|banana|fruit,yellow,monkey
🍍|pineapple|fruit,tropical
🥭|mango|fruit,tropical
🍎|red apple|apple,fruit,red
🍏|green apple|apple,fruit,green
🍐|pear|fruit,pear
🍑|peach|fruit,peach
🍒|cherries|fruit,cherry,red
🍓|strawberry|fruit,berry,red
🫐|blueberries|berry,fruit,blue
🥝|kiwi fruit|kiwi,fruit,green
🍅|tomato|tomato,vegetable,red
🥥|coconut|coconut,tropical
🥑|avocado|avocado,toast,green
🍆|eggplant|eggplant,vegetable,purple
🥔|potato|potato,vegetable,spud
🥕|carrot|carrot,vegetable,rabbit
🌽|ear of corn|corn,vegetable,yellow
🌶️|hot pepper|spicy,pepper,chili
🥒|cucumber|cucumber,vegetable,green
🥬|leafy green|lettuce,kale,salad
🧄|garlic|garlic,cooking
🧅|onion|onion,cooking
🍄|mushroom|mushroom,fungi,toadstool
🥜|peanuts|peanut,nut,snack
🌰|chestnut|nut,chestnut,autumn
🍞|bread|bread,loaf,bake
🥐|croissant|croissant,french,bakery
🥖|baguette bread|baguette,french,bread
🫓|flatbread|naan,tortilla,pita
🥯|bagel|bagel,breakfast,bakery
🧈|butter|butter,cooking,dairy
🧀|cheese wedge|cheese,dairy
🍳|egg cooking|egg,fried,breakfast
🦴|bone|bone,dog,skeleton
🥗|green salad|salad,healthy,greens
🥘|paella|paella,pan,seafood
🫕|fondue|fondue,cheese,pot
🍝|spaghetti|pasta,italian,noodles
🍜|noodle soup|ramen,pho,noodles
🍲|pot of food|stew,soup,pot
🍚|rice|rice,bowl
🐤|baby chick|chick,bird,yellow
🦆|duck|duck,bird
🦅|eagle|eagle,bird,usa
🦉|owl|owl,bird,wise
🦇|bat|bat,halloween,night
🐺|wolf|wolf,howl,moon
🐗|boar|boar,pig,wild
🐴|horse|horse,ride,gallop
🦄|unicorn|unicorn,magic,rainbow
🐝|honeybee|bee,honey,pollinate
🪱|worm|worm,bug,dirt
🦋|butterfly|butterfly,insect,pretty
🐌|snail|snail,slow,shell
🐞|lady beetle|ladybug,beetle,lucky
🐜|ant|ant,insect,bug
🪰|fly|fly,bug,pest
🪲|beetle|beetle,bug
🦗|cricket|cricket,bug,chirp
🕷️|spider|spider,arachnid,web
🦂|scorpion|scorpion,arachnid
🐢|turtle|turtle,slow,shell
🐍|snake|snake,serpent,python
🦎|lizard|lizard,reptile,gecko
🦖|t-rex|dinosaur,trex,rex
🦕|sauropod|dinosaur,long neck
🐙|octopus|octopus,sea,tentacle
🎣|fishing|fishing,rod
🐘|elephant|elephant,ivory
🦛|hippopotamus|hippo,river
🦏|rhinoceros|rhino,horn
🐪|camel|camel,desert,hump
🦒|giraffe|giraffe,tall,neck
🦘|kangaroo|kangaroo,australia,jump
🐄|cow|cow,milk,farm
🐎|horse racing|horse,race,giddyup
🐖|pig|pig,farm,bacon
🐏|ram|ram,sheep,horn
🐑|sheep|sheep,wool,flock
🦙|llama|llama,alpaca,wool
🐐|goat|goat,farm
🦌|deer|deer,buck,fawn
🐕|dog|dog,puppy,pet,woof
🐩|poodle|poodle,dog
🦮|guide dog|guide,service,dog
🐈|cat|cat,kitty,pet,meow
🐈‍⬛|black cat|cat,black,lucky
🐓|rooster|rooster,chicken,farm
🦃|turkey|turkey,thanksgiving
🦚|peacock|peacock,bird,colorful
🦜|parrot|parrot,bird,talk
🦢|swan|swan,bird,elegant
🦩|flamingo|flamingo,pink,bird
🕊️|dove|dove,peace,bird
🐰|rabbit|rabbit,bunny,easter
🦝|raccoon|raccoon,trash,panda
🦨|skunk|skunk,smelly
🦡|badger|badger,honey
🦫|beaver|beaver,dam,wood
🦦|otter|otter,river,playful
🦥|sloth|sloth,slow,lazy
🐁|mouse|mouse,rodent
🐀|rat|rat,rodent
🦔|hedgehog|hedgehog,spikes
🐻|bear|bear,grizzly
🐨|koala|koala,australia,cute
🐼|panda|panda,bear,china
🐅|tiger|tiger,big cat
🦁|lion|lion,king,jungle
🐮|cow face|cow,moo,farm
🐷|pig face|pig,oink
🐸|frog face|frog,green,ribbit
🐵|monkey face|monkey,ape,banana
🎃|pumpkin|pumpkin,halloween
☕|coffee|coffee,latte,espresso
🚀|rocket|rocket,launch,space,ship
🛸|flying saucer|ufo,alien,saucer
🛎️|bellhop bell|bell,service,hotel
🧳|luggage|luggage,travel,bag
⌛|hourglass|time,wait,hourglass
⏳|hourglass flowing sand|time,wait,patience
⌚|watch|watch,time,wrist
⏰|alarm clock|alarm,morning,wake
⏱️|stopwatch|stopwatch,timer,track
⏲️|timer clock|timer,kitchen,cook
🕰️|mantelpiece clock|clock,time,vintage
🌡️|thermometer|temperature,weather,fever
⛱️|umbrella on ground|beach,shade,umbrella
🎎|japanese dolls|doll,daruma
🎒|backpack|school,bag,pack
🎓|graduation cap|graduate,school,degree
🎙️|studio microphone|podcast,record,mic
🏭|factory|factory,industry
🐝|bee|bee,honey
🏠|house|house,home,building
🏡|house with garden|home,garden,house
🏢|office building|office,work,building
🏥|hospital|hospital,medical,doctor
🏦|bank|bank,money,finance
🏨|hotel|hotel,stay,travel
🏫|school|school,education,class
🏬|department store|shop,store,mall
💒|wedding|wedding,marriage,chapel
🏛️|classical building|museum,greek,history
⛪|church|church,christian,cathedral
🕌|mosque|mosque,islam,minaret
🕍|synagogue|synagogue,jewish
🛕|hindu temple|temple,hindu
🕋|kaaba|mecca,islam,pilgrimage
⛲|fountain|fountain,water,park
⛺|tent|tent,camp,outdoors
🌁|foggy|fog,weather,misty
🌃|night with stars|night,stars,city
🏙️|cityscape|city,skyline,urban
🌄|sunrise over mountains|sunrise,morning,dawn
🌅|sunrise|sunrise,dawn,morning
🌆|cityscape at dusk|dusk,evening,city
🌇|sunset|sunset,dusk,evening
⛈️|thunderstorm|storm,thunder,rain
🌤️|sun behind small cloud|partly cloudy,weather
🌥️|sun behind large cloud|cloudy,weather
🌦️|sun behind rain cloud|sunshower,weather
🌧️|cloud with rain|rain,weather,wet
🌨️|cloud with snow|snow,weather,cold
🌩️|cloud with lightning|lightning,storm
🌪️|tornado|tornado,whirlwind
🌫️|fog|fog,mist,haze
🌬️|wind face|wind,blow,air
🌀|cyclone|swirl,hurricane,spiral
🌈|rainbow|rainbow,pride,colorful
🌂|closed umbrella|umbrella,rain
☂️|umbrella|umbrella,rain,shelter
☔|umbrella with rain drops|umbrella,rainy
☔|umbrella|rain
⚡|high voltage|lightning,bolt,electric
❄️|snowflake|snow,winter,cold,unique
☃️|snowman with snow|snowman,winter
🌊|wave|wave,ocean,surf
🌕|full moon|moon,full,night
🌗|waning gibbous moon|moon,waning
🌖|waxing gibbous moon|moon,waxing
🌙|crescent moon|moon,night,sleep
🌚|new moon face|moon,dark
🌝|full moon face|moon,smile
🌞|sun with face|sun,summer,hot
☀️|sun|sun,sunny,summer,weather
👨‍💻|technologist|developer,coding
🦿|mechanical leg|prosthetic,robot
⭐|star|star,favorite,rating
⚡|zap|lightning,energy,fast
🔥|flame|fire,lit,hot
🕐|one o'clock|time,one,clock
💹|chart increasing with yen|chart,yen,up
❤️‍🔥|heart on fire|love,passion,burn
❤️‍🩹|mending heart|heal,recover,love
🎞️|film frames|film,movie,retro
🏘️|houses|houses,village
🎖️|military medal|medal,honor
🏅|sports medal|medal,award
🎵|musical note|music,note,song
🎶|musical notes|music,song,notes
🎙|microphone|mic,sing
🔕|bell with slash|mute,silent,off
🔔|bell|bell,notify,alert
🔊|speaker high volume|volume,loud,sound
🔉|speaker medium volume|volume,sound
🔈|speaker low volume|volume,quiet
🔇|muted speaker|mute,silent,off
📢|loudspeaker|announce,pa
📣|cheering megaphone|cheer,announce
"""
}
