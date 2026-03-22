-- V8: Seed 6 Knowledge Nodes — Domain: CREATIVE
-- Shared values for all rows: domain='CREATIVE', age_group='all', is_published=TRUE
-- IDs: 44444444-0000-0000-0000-00000000000{1..6}

INSERT INTO knowledge_nodes (id, title, hook, domain, age_group, difficulty, curiosity_score, is_published,
                              guess_prompt, journey_steps, reveal_text, teach_back_prompt, payoff_insight)
VALUES

('44444444-0000-0000-0000-000000000001',
 'Jazz Improvisation: How Musicians Compose in Real Time',
 'Jazz musicians improvise solos — composing original melodies on the spot, in real time, in front of an audience, while listening to and responding to four other musicians doing the same thing.',
 'CREATIVE', 'all', 2, 9, TRUE,
 'What do you think goes through a jazz musician''s mind while improvising? Is it random, or is there structure underneath?',
 '[
   {"step": 1, "text": "Jazz improvisation is not random — it operates within a harmonic structure. The chord progression is the shared ''road map'' all musicians agree on in advance. Improvisation means creating a melody that fits those chords while departing freely from the original tune."},
   {"step": 2, "text": "Musicians build a vocabulary of phrases (''licks'') through years of practice — patterns that work over specific chord types. Improvisation is partly assembling and adapting these phrases in real time, like sentences constructed from a deeply internalized vocabulary."},
   {"step": 3, "text": "The higher level is conversation: jazz soloists listen to what other musicians are playing and respond — quoting a phrase the drummer just played, building tension against the bass line, or deliberately breaking the pattern to create surprise."},
   {"step": 4, "text": "Expert improvisers enter a state psychologists call ''flow'' — conscious deliberation drops away and musical decision-making becomes automatic. Brain imaging studies show decreased activity in the prefrontal cortex (self-monitoring) during improvisation, similar to patterns seen in experienced meditators."}
 ]',
 'Most people imagine improvisation as either pure spontaneity or pure memorization. The reality — structured vocabulary deployed conversationally in flow state — explains why jazz improvisation feels both free and coherent.',
 'Explain jazz improvisation using a language analogy: how is it similar to speaking a sentence fluently in real time? What would make someone a better "speaker"?',
 'A jazz musician improvising a 4-minute solo is making thousands of micro-decisions per second — harmony, rhythm, dynamics, response — in real time. It is one of the most cognitively demanding performances a human can give.'),

('44444444-0000-0000-0000-000000000002',
 'The Science of Color: Why Colors Don''t Exist Outside Your Brain',
 'Color is not a property of objects or light. It is a construction your brain makes from wavelength data. Two people looking at the same object may experience genuinely different colors — and both are correct.',
 'CREATIVE', 'all', 3, 10, TRUE,
 'Do you think the color "red" exists in the physical world, or only in your mind? What would a colorblind person say to challenge your answer?',
 '[
   {"step": 1, "text": "Physical light is just electromagnetic radiation at various wavelengths (380–700 nm for visible light). Wavelengths have no color — they are just energy frequencies. Color is the brain''s interpretation of those wavelengths."},
   {"step": 2, "text": "The human eye has 3 types of cone cells (S, M, L) sensitive to different wavelength ranges. Color perception is created by comparing the ratio of signals from these three cones — not by detecting color directly."},
   {"step": 3, "text": "Colorblind individuals have different cone sensitivities — they don''t see ''less'' color; they see a genuinely different, valid mapping of the spectrum. Tetrachromats (mostly women, ~12% of population) have 4 cone types and may distinguish colors that appear identical to trichromats."},
   {"step": 4, "text": "The color you experience also depends on context, memory, and language. The ''dress'' debate (2015 — was it blue/black or gold/white?) went viral because different people''s visual systems made different assumptions about ambient lighting, producing genuinely different color perceptions from identical pixel data."}
 ]',
 'Most people assume they perceive color objectively. The layered reality — wavelengths interpreted by variable biology, filtered through context and language — means color is a collaborative construction between the world and your brain.',
 'Explain to someone why saying "the apple is red" is more complex than it sounds. What three separate things are you actually describing when you use a color word?',
 'There is no red in the universe — only electromagnetic radiation at ~700 nm. Your brain invented red. So did everyone else''s, slightly differently.'),

('44444444-0000-0000-0000-000000000003',
 'Shakespeare''s Language: How He Invented Words We Still Use Daily',
 'Shakespeare coined over 1,700 words still in common use today — bedroom, lonely, generous, addiction, swagger, uncomfortable. He didn''t just write plays; he expanded the English language itself.',
 'CREATIVE', 'all', 2, 8, TRUE,
 'Which common English words do you think might have been invented by Shakespeare? Make a guess before reading on.',
 '[
   {"step": 1, "text": "Shakespeare''s plays were written in a period when English was rapidly absorbing Latin and French vocabulary. As a playwright, he needed words for emotions and situations that existing English didn''t cover — so he invented them, often by adding prefixes/suffixes to existing words."},
   {"step": 2, "text": "Examples of words coined by Shakespeare: bedroom, lonely, generous, addiction, bedroom, uncomfortable, hint, lackluster, swagger, worthless, generous, cold-blooded, break the ice, foregone conclusion, heart of gold, wild-goose chase."},
   {"step": 3, "text": "He also invented grammatical constructions. English speakers commonly say ''It''s a brave new world'' (The Tempest), ''All that glitters is not gold'' (Merchant of Venice), and ''Green-eyed monster'' (Othello) without knowing the source. These are now idioms, not quotes."},
   {"step": 4, "text": "Scholars debate how many words he truly ''invented'' vs. first recorded — he may have used street slang that wasn''t previously written down. But his plays are the earliest written record of 1,700+ words, making him the single largest known contributor to the English lexicon."}
 ]',
 'Most people think of Shakespeare as archaic and hard to read. The irony is that much of modern everyday English — including words that feel contemporary — traces back to him.',
 'Pick three Shakespeare-coined words from the list and explain to someone why language needed those words — what gap did each fill that existing words didn''t?',
 'When you say someone has "swagger," warn someone of a "wild-goose chase," or describe a "bedroom" — you''re using Shakespeare''s vocabulary. He didn''t just write about the world; he gave us words to describe it.'),

('44444444-0000-0000-0000-000000000004',
 'Architecture of Cathedrals: Engineering Miracles Built Without Computers',
 'Medieval cathedrals stand 50+ meters tall, span wide naves without internal columns, and have survived earthquakes and centuries of weather — all designed without calculators, structural engineering theory, or steel.',
 'CREATIVE', 'all', 3, 9, TRUE,
 'How do you think medieval builders designed structures that have stood for 800 years without modern engineering tools or mathematics?',
 '[
   {"step": 1, "text": "The key innovation was the Gothic arch and ribbed vault: pointed arches direct weight downward more efficiently than round arches, allowing taller, thinner walls. Ribbed vaults channel the roof''s weight to specific points rather than spreading it across the wall."},
   {"step": 2, "text": "Flying buttresses solve the problem of lateral thrust: the outward push of heavy stone roofs is redirected down and outward through stone arches that ''fly'' from the wall to external piers. This is why Gothic cathedrals have those distinctive exterior supports."},
   {"step": 3, "text": "Medieval builders used physical models and empirical rules of thumb passed down in guilds — not equations. They learned what proportions worked from observation, tradition, and trial and error (some cathedrals did collapse during construction)."},
   {"step": 4, "text": "Modern structural analysis of medieval cathedrals has revealed they were built to surprisingly precise structural optima — in many cases near the theoretical limits of what stone can do. Some researchers argue builders had intuitive mastery of structural principles they couldn''t formally articulate."}
 ]',
 'Most people assume medieval builders were limited by ignorance. The reality — structural solutions of near-mathematical elegance, derived empirically over centuries — suggests a different kind of engineering intelligence.',
 'Explain the concept of the flying buttress to someone using a physical analogy. Why does redirecting lateral thrust outward and downward make such a structural difference?',
 'The builders of Notre-Dame de Paris had no structural engineering degree, no CAD software, no finite element analysis. They built a 69-meter tower that has stood for 800 years. The knowledge was in their hands.'),

('44444444-0000-0000-0000-000000000005',
 'The Psychology of Music: Why Minor Keys Make You Sad',
 'Music triggers emotions so reliably that it''s used in advertising, therapy, and film. But the connection between sound and emotion is not universal — and some of it is learned, not innate.',
 'CREATIVE', 'all', 2, 8, TRUE,
 'Do you think the emotional response to music — sadness from minor keys, happiness from major — is biological or cultural? Could someone from a different culture hear it differently?',
 '[
   {"step": 1, "text": "Western listeners reliably associate minor keys with sadness and major keys with happiness — but this association is largely learned, not innate. Studies with the Mafa people of Cameroon (who had no prior exposure to Western music) showed significantly weaker emotional associations with major vs. minor scales."},
   {"step": 2, "text": "Some emotional responses to music appear more universal: tempo (fast = excited, slow = calm), loudness, and roughness (dissonance vs. consonance) produce similar emotional responses across cultures. These may be linked to how we process vocal and environmental sounds."},
   {"step": 3, "text": "Music triggers the brain''s reward system — dopamine is released during peak emotional moments (''chills'' or ''frissons''). This explains why people seek out sad music voluntarily: the emotional experience itself is rewarding, regardless of the valence."},
   {"step": 4, "text": "Music used in films demonstrates learned association: the same scene with different music produces opposite emotional reactions. Horror film composers use high-frequency violins because they mimic infant crying — a sound humans are evolutionarily primed to respond to with urgency."}
 ]',
 'Most people assume their emotional response to music is natural and universal. The layered reality — some responses are cultural, some are biological, and the brain rewards the experience itself — makes music one of the most studied emotional stimuli in neuroscience.',
 'Explain to someone why sad music can feel pleasurable. What are the different mechanisms at play — and why might someone actively choose to listen to something that makes them feel sad?',
 'When a film score makes you cry, a violin is mimicking an infant''s cry, and your ancient brain is responding to a stimulus 100 million years older than music itself.'),

('44444444-0000-0000-0000-000000000006',
 'The Golden Ratio: The Math That Appears in Art, Nature, and Architecture',
 'The golden ratio (φ ≈ 1.618) appears in the Parthenon, Leonardo''s paintings, nautilus shells, and sunflower seeds. Or does it? The truth about the most romanticized number in mathematics is more interesting than the myth.',
 'CREATIVE', 'all', 3, 8, TRUE,
 'Have you heard that the golden ratio appears throughout nature and art? Do you think this is a deep mathematical truth, a coincidence, or something else?',
 '[
   {"step": 1, "text": "The golden ratio φ = (1 + √5) / 2 ≈ 1.618 has a unique property: a rectangle with sides in this ratio, when you remove a square from it, leaves a smaller rectangle with the same ratio. It also appears in the Fibonacci sequence: consecutive Fibonacci numbers divide to approach φ."},
   {"step": 2, "text": "In nature, spiral patterns in sunflower seeds, pinecones, and nautilus shells do follow Fibonacci numbers. This is real and has an explanation: Fibonacci spacing maximizes packing density (each new seed grows at ~137.5° from the previous one, the ''golden angle'') — this is an optimal packing solution, not aesthetic."},
   {"step": 3, "text": "The claims about art and architecture are largely myth. Careful measurement of the Parthenon, Leonardo''s Vitruvian Man, and many other ''golden ratio'' examples shows the ratio is approximately but not precisely φ — and only some of many possible measurements fit, while others are ignored."},
   {"step": 4, "text": "The golden ratio''s reputation was largely built in the 19th–20th century through books that cherry-picked measurements. A 2015 study (Markowsky) found no evidence artists consciously used φ. The real story — that it emerges from optimal packing in biology, but was retrojected onto art — is more interesting than the myth."}
 ]',
 'The golden ratio is one of mathematics'' most oversold ideas. The truth — real in biology for a specific reason, mostly invented in art — demonstrates how pattern-seeking humans can find meaningful structure even in coincidence.',
 'Explain to someone skeptical of debunking: "Even if the golden ratio claims about art are exaggerated, why does it genuinely appear in sunflower seeds?" Walk through the packing logic.',
 'The golden ratio really does appear in sunflowers — because optimal packing and mathematics are the same thing. The rest is humans finding patterns they were looking for. Both facts are worth knowing.');
