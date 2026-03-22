-- V5: Seed 10 Knowledge Nodes — Domain: NATURE
-- Shared values for all rows: domain='NATURE', age_group='all', is_published=TRUE
-- 6 session phases per node: hook, guess_prompt, journey_steps (JSONB), reveal_text, teach_back_prompt, payoff_insight

INSERT INTO knowledge_nodes (id, title, hook, domain, age_group, difficulty, curiosity_score, is_published,
                              guess_prompt, journey_steps, reveal_text, teach_back_prompt, payoff_insight)
VALUES
-- IDs: 11111111-0000-0000-0000-00000000000{1..10}
('11111111-0000-0000-0000-000000000001',
 'Photosynthesis: How Plants Make Food from Light',
 'Plants sit in sunlight all day — but they''re not just sunbathing. They''re running a chemical factory that feeds almost every living thing on Earth.',
 'NATURE', 'all', 2, 8, TRUE,
 'Before we dive in: how do you think a plant turns sunlight into food? Take a guess!',
 '[
   {"step": 1, "text": "Chlorophyll molecules in the leaf absorb red and blue light, reflecting green — that''s why leaves look green to us."},
   {"step": 2, "text": "The absorbed light energy splits water molecules (H₂O), releasing oxygen as a byproduct — the oxygen we breathe."},
   {"step": 3, "text": "The plant uses that energy to combine CO₂ from the air with hydrogen atoms, building glucose (C₆H₁₂O₆)."},
   {"step": 4, "text": "This glucose fuels every cell in the plant — and every animal that eats the plant inherits that stored sunlight."}
 ]',
 'Did your guess match? Most people think plants absorb sunlight like a solar panel directly powering movement — but the real magic is a chemical reaction that *builds* molecules, not just moves energy.',
 'Imagine explaining this to a curious 8-year-old: "Plants eat sunlight. How does light become a cookie?" Walk through it step by step.',
 'Every calorie you''ve ever eaten traces back to a plant capturing sunlight. You are, quite literally, made of stored light.'),

('11111111-0000-0000-0000-000000000002',
 'Monarch Butterflies: A 4,500 km Journey with No GPS',
 'A butterfly weighing less than a paperclip navigates thousands of kilometers to a forest it has never visited — guided by mechanisms scientists are still unraveling.',
 'NATURE', 'all', 3, 9, TRUE,
 'How do you think a butterfly — with a brain the size of a pinhead — knows where to fly for winter?',
 '[
   {"step": 1, "text": "Monarchs use a time-compensated sun compass: their internal clock adjusts their angle to the sun throughout the day to maintain a south-southwest heading."},
   {"step": 2, "text": "They also detect the Earth''s magnetic field using light-sensitive proteins in their antennae, acting like a biological compass."},
   {"step": 3, "text": "Remarkably, each migration takes 3–4 generations — meaning the butterfly that arrives in Mexico was never there before, yet finds the exact same trees."},
   {"step": 4, "text": "Scientists believe the navigation information is encoded in their genes, passed down despite no individual completing the full round trip."}
 ]',
 'Most guesses involve smell or following others. The reality — a sun-clock plus magnetic sensing plus inherited genetic maps — is far more extraordinary.',
 'Explain to a friend: "Why is the monarch migration considered a mystery even though we know the mechanism?" Think about what we still don''t fully understand.',
 'The monarchs that winter in Mexico carry a genetic memory of a place no living ancestor has visited. Nature solves GPS with DNA.'),

('11111111-0000-0000-0000-000000000003',
 'Bioluminescence: Why the Deep Ocean Glows',
 'Below 200 meters, sunlight vanishes — yet 76% of deep-sea creatures make their own light. The dark ocean is full of living lanterns.',
 'NATURE', 'all', 2, 9, TRUE,
 'If you lived in total darkness, what would you use light for? Guess how deep-sea creatures use their glow.',
 '[
   {"step": 1, "text": "Bioluminescence is produced by a chemical reaction: luciferin oxidizes with the help of luciferase enzyme, releasing energy as photons (light) instead of heat."},
   {"step": 2, "text": "Predators like the anglerfish dangle a glowing lure to attract prey — the light acts as a fishing rod in the dark."},
   {"step": 3, "text": "Some squid and fish use counterillumination — producing light on their belly to match faint surface light, becoming invisible to predators looking up."},
   {"step": 4, "text": "Communication also happens via light: firefly squid flash patterns to find mates, and some jellyfish emit bursts to startle predators."}
 ]',
 'Most people guess "to see." The real answers — hunting, camouflage, and communication — show that light in the dark is a multi-tool, not just a flashlight.',
 'Explain bioluminescence to someone who''s never heard of it. How would you describe the chemistry without using the word "chemical reaction"?',
 'The deep ocean is the largest inhabited space on Earth, and most of its creatures are invisible to us — blinking in languages we''re only beginning to decode.'),

('11111111-0000-0000-0000-000000000004',
 'The Wood Wide Web: How Trees Talk Through Fungi',
 'Beneath every forest floor runs a network older than the internet — fungi threads that let trees share food, send warnings, and even care for their young.',
 'NATURE', 'all', 3, 10, TRUE,
 'Do you think trees in a forest compete with each other, or cooperate? What''s your instinct?',
 '[
   {"step": 1, "text": "Mycorrhizal fungi attach to tree roots and extend thread-thin hyphae through the soil — a single teaspoon of forest soil contains kilometers of these threads."},
   {"step": 2, "text": "Through this network, trees exchange carbon, water, and nutrients. A shaded sapling can receive carbon from a tall neighbor that has surplus from photosynthesis."},
   {"step": 3, "text": "When a tree is attacked by insects, it sends chemical distress signals through the network, prompting neighboring trees to pre-emptively boost their own defenses."},
   {"step": 4, "text": "The fungi aren''t altruistic — they take up to 30% of the tree''s sugar as payment. It''s a mutualistic trade network, not a charity."}
 ]',
 'Most people assume competition. The reality is a sophisticated underground market — trees trading resources through fungal brokers, with mutual benefit and real costs.',
 'If you had to explain the mycelial network to someone using only a human economy analogy, what would the fungi be? The trees? The nutrients?',
 'Forests are not collections of individual trees — they are superorganisms connected by underground networks that predate human civilization by hundreds of millions of years.'),

('11111111-0000-0000-0000-000000000005',
 'Tardigrades: The Indestructible Animal',
 'There is a microscopic animal that can survive outer space, boiling water, extreme radiation, and 30 years without food. It''s probably living on your roof right now.',
 'NATURE', 'all', 2, 10, TRUE,
 'What do you think is the toughest environment on Earth for life? Could any animal survive in space?',
 '[
   {"step": 1, "text": "Tardigrades (water bears) are 0.1–1.5 mm long and live in moss, soil, and gutters worldwide. Under a microscope, they look like tiny 8-legged bears."},
   {"step": 2, "text": "When conditions become extreme, they enter cryptobiosis: they expel 97% of their body water, retract their limbs, and become a dehydrated barrel called a tun."},
   {"step": 3, "text": "In the tun state, their metabolism drops to 0.01% of normal. They''ve survived vacuum of space, -272°C, 150°C, 6,000 Gy of radiation (humans die at 5 Gy), and pressure 6× deeper than the Mariana Trench."},
   {"step": 4, "text": "They revive when water returns, sometimes after 30+ years. Scientists are studying their DNA repair proteins and trehalose sugar for medical and space-travel applications."}
 ]',
 'Most people guess extremophile bacteria. The fact that an animal — with legs, a digestive system, and a nervous system — achieves this survival is genuinely astonishing.',
 'Explain to a friend what "cryptobiosis" is without using that word. How would you describe what a tardigrade does to survive?',
 'Tardigrades have survived all five mass extinctions. Whatever ends human civilization, these microscopic bears will likely still be crawling through the moss of whatever comes next.'),

('11111111-0000-0000-0000-000000000006',
 'Pistol Shrimp: The Animal That Shoots Hotter Than the Sun',
 'A shrimp the size of your thumb snaps its claw so fast it creates a bubble hotter than the surface of the sun — and uses it to stun prey.',
 'NATURE', 'all', 3, 10, TRUE,
 'How do you think a 5 cm shrimp could possibly stun or kill its prey without a sharp claw or venom?',
 '[
   {"step": 1, "text": "The pistol shrimp has one oversized claw that snaps shut in 0.7 milliseconds — among the fastest movements in the animal kingdom."},
   {"step": 2, "text": "This snap creates a cavitation bubble: a pocket of near-vacuum that collapses almost instantly, producing a shockwave, a loud crack, and a flash of light."},
   {"step": 3, "text": "At the moment of collapse, the bubble reaches ~8,000°C — hotter than the surface of the sun (5,500°C). The light emitted is called sonoluminescence."},
   {"step": 4, "text": "The shockwave stuns or kills small prey instantly. Colonies of pistol shrimp are so loud they interfere with naval sonar and submarine communications."}
 ]',
 'Venom and sharp claws are the usual guesses. A shrimp weaponizing bubble physics to generate temperatures hotter than the sun is the kind of answer that makes you question reality.',
 'Walk someone through why a collapsing bubble creates heat. What''s actually happening at the physics level — where does the energy come from?',
 'The ocean is full of creatures that discovered physics solutions to biological problems millions of years before humans wrote their first equations.'),

('11111111-0000-0000-0000-000000000007',
 'Elephants: Giants with Grief, Joy, and 60-Year Memories',
 'Elephants mourn their dead, recognize themselves in mirrors, comfort grieving herd members, and remember individual humans decades after a single meeting.',
 'NATURE', 'all', 2, 8, TRUE,
 'Do you believe animals can feel grief? What behaviors would convince you an animal truly mourns someone?',
 '[
   {"step": 1, "text": "Elephants have the largest brain of any land animal, with a highly developed hippocampus and temporal lobe — the same regions associated with memory and emotion in humans."},
   {"step": 2, "text": "They pass the mirror self-recognition test (one of very few animals to do so), indicating self-awareness — a prerequisite for empathy."},
   {"step": 3, "text": "When a herd member dies, elephants return to the bones for years, touching them with their trunks and standing in silence. This behavior has no survival advantage."},
   {"step": 4, "text": "Matriarchs store 60+ years of knowledge about water sources, migration routes, and dangerous individuals — their death can collapse the survival of the entire herd."}
 ]',
 'Many people initially resist attributing grief to animals as "anthropomorphizing." But elephant behavior meets the same behavioral criteria we use to define mourning in humans.',
 'How would you explain elephant social intelligence to someone who believes only humans have complex emotions? What evidence would you use?',
 'The oldest elephant in a herd is not just a member — she is a living library. When she dies, decades of survival knowledge disappear with her.'),

('11111111-0000-0000-0000-000000000008',
 'Coral Bleaching: Why Reefs Turn White and Die',
 'Coral reefs cover 1% of the ocean floor but support 25% of all marine species. They''re dying — and the mechanism is more intimate than most people realize.',
 'NATURE', 'all', 2, 8, TRUE,
 'Why do you think coral turns white? Is it dying, or just stressed? What''s your guess?',
 '[
   {"step": 1, "text": "Coral polyps are animals, but they get up to 90% of their energy from symbiotic algae called zooxanthellae that live inside their cells and photosynthesize."},
   {"step": 2, "text": "When water temperature rises by just 1–2°C for several weeks, the algae produce toxic reactive oxygen. The coral expels them as a stress response — revealing white calcium carbonate skeleton."},
   {"step": 3, "text": "Without zooxanthellae, the coral starves. If temperatures drop in time (4–6 weeks), algae can return and the coral recovers. Beyond that window, the coral dies."},
   {"step": 4, "text": "Since 1998, mass bleaching events have hit every major reef system. The Great Barrier Reef has bleached 5 times since 2016. Recovery takes 10–15 years — but events are now happening faster than recovery allows."}
 ]',
 'Most people think bleaching is like paint fading. The reality — a coral evicting its food source as a last resort — makes the white color a visible distress signal with a countdown.',
 'Explain to someone why losing zooxanthellae is like a human''s digestive system evicting all gut bacteria at once. What are the consequences?',
 'Coral reefs are sometimes called the rainforests of the sea — yet we have mapped the moon''s surface more thoroughly than we have documented what lives in them.'),

('11111111-0000-0000-0000-000000000009',
 'Birdsong: How Birds Learn Music Like Children Learn Language',
 'Baby birds are born knowing nothing of their species'' song. They have a critical learning window, a babbling phase, and even regional dialects — just like human language.',
 'NATURE', 'all', 2, 7, TRUE,
 'Do you think birds are born knowing their song, or do they have to learn it? How do you think they learn?',
 '[
   {"step": 1, "text": "Birds are born with only a rough template of their species'' song hardwired in the brain — a genetic ''seed.'' The full song must be learned by listening."},
   {"step": 2, "text": "Juvenile birds go through subsong — a rambling, quiet vocalization like human babbling — as they practice matching what they heard from adult tutors."},
   {"step": 3, "text": "There is a critical period: if a bird doesn''t hear its species'' song in the first weeks of life, it will never learn it correctly — similar to how children who aren''t exposed to language early develop language difficulties."},
   {"step": 4, "text": "Different populations develop regional dialects — chaffinches in Scotland sing measurably differently from chaffinches in England. These dialects persist and evolve over generations."}
 ]',
 'Many guess "instinct." The reality — a critical window, a babbling phase, and cultural dialects — means birdsong is a form of cultural transmission, not just genetic programming.',
 'How would you explain to someone skeptical of animal intelligence why birdsong learning is more like culture than instinct?',
 'When a bird sings at dawn, it may be performing a song passed down through hundreds of generations of learning — a cultural tradition older than any human musical tradition.'),

('11111111-0000-0000-0000-000000000010',
 'The Nitrogen Cycle: The Invisible Process That Feeds the World',
 'Your body is 3% nitrogen. That nitrogen was recently in the air — invisible, inert, and utterly useless until bacteria performed a chemical miracle to make it edible.',
 'NATURE', 'all', 3, 7, TRUE,
 'Nitrogen makes up 78% of the air we breathe — but we can''t use it. How do you think it gets from air into living things?',
 '[
   {"step": 1, "text": "Atmospheric nitrogen (N₂) is held together by one of the strongest bonds in chemistry. ''Fixing'' it — breaking that bond to make usable compounds — requires enormous energy."},
   {"step": 2, "text": "Nitrogen-fixing bacteria (e.g., Rhizobium in legume roots) do this using an enzyme called nitrogenase, converting N₂ into ammonia (NH₃) that plants can absorb."},
   {"step": 3, "text": "Plants build proteins from this nitrogen. Animals eat plants. When organisms die, decomposers break down their proteins, releasing nitrogen back to soil as ammonium, then nitrates."},
   {"step": 4, "text": "Denitrifying bacteria complete the cycle by converting nitrates back to N₂ gas. Without them, nitrogen would accumulate in soil and poison ecosystems."}
 ]',
 'Most people guess rain or lightning (lightning does fix small amounts of nitrogen). The real answer — bacteria running industrial chemistry in root nodules — is far more elegant.',
 'Walk someone through why farmers plant legumes between crop seasons. Connect it back to the nitrogen cycle step by step.',
 'Half of the nitrogen atoms in your body right now passed through a bacterium living in a plant root. You are, in part, made of bacterial chemistry.');
