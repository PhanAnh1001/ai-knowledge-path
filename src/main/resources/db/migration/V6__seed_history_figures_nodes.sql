-- V6: Schema improvements + Seed 7 Knowledge Nodes — Domain: HISTORY
-- Schema: add CHECK constraint on domain, replace low-selectivity boolean index
--         with composite (domain, is_published) index
-- Shared values for all rows: domain='HISTORY', age_group='all', is_published=TRUE
-- IDs: 55555555-0000-0000-0000-00000000000{1..7}

-- Enforce valid domain values (prevents silent typos in future seeds)
ALTER TABLE knowledge_nodes
    ADD CONSTRAINT chk_domain
    CHECK (domain IN ('NATURE', 'HISTORY', 'TECHNOLOGY', 'CREATIVE', 'SCIENCE', 'PHILOSOPHY', 'MATH'));

-- Replace low-selectivity boolean index with composite covering query: domain + is_published
DROP INDEX IF EXISTS idx_knowledge_nodes_published;
CREATE INDEX idx_knowledge_nodes_domain_published ON knowledge_nodes (domain, is_published);

-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO knowledge_nodes (id, title, hook, domain, age_group, difficulty, curiosity_score, is_published,
                              guess_prompt, journey_steps, reveal_text, teach_back_prompt, payoff_insight)
VALUES

('55555555-0000-0000-0000-000000000001',
 'Marie Curie: The Scientist Who Died for Her Discoveries',
 'She won the Nobel Prize twice, in two different sciences — the only person in history to do so. She also carried radioactive samples in her coat pockets and may have known it was killing her.',
 'HISTORY', 'all', 2, 9, TRUE,
 'What do you think it would take for a woman to become the world''s leading scientist in the 1890s? What obstacles would she face?',
 '[
   {"step": 1, "text": "Marie Skłodowska grew up in occupied Poland where women were barred from universities. She and her sister made a pact: they would take turns funding each other''s education in Paris."},
   {"step": 2, "text": "She discovered two elements — polonium (named after her homeland) and radium — by processing literally tons of uranium ore in a leaky shed with no proper equipment."},
   {"step": 3, "text": "Her Nobel Prize in Physics (1903) was almost not awarded to her — the committee initially planned to honor only her husband Pierre and colleague Becquerel. She received it after Pierre insisted she be included."},
   {"step": 4, "text": "Her second Nobel, in Chemistry (1911), was awarded while the French press was running a smear campaign attacking her as a foreign woman and a widow having an affair. She attended the ceremony anyway."}
 ]',
 'Most people know she was the first woman to win a Nobel Prize. Fewer know she overcame national occupation, institutional sexism, a smear campaign, and likely died from the radioactive materials she spent her life studying.',
 'Explain to someone why Marie Curie''s story is about more than just scientific genius — what structural forces was she fighting against, and how did she navigate them?',
 'Marie Curie''s personal research notebooks are still so radioactive that researchers must sign waivers to view them. Her legacy is literally dangerous to touch.'),

('55555555-0000-0000-0000-000000000002',
 'Ada Lovelace: The First Programmer — 100 Years Before Computers Existed',
 'In 1843, a woman wrote the world''s first computer program — for a machine that was never built. Her notes contained ideas that wouldn''t be fully understood for over a century.',
 'HISTORY', 'all', 3, 9, TRUE,
 'What do you think "programming" looked like before electronic computers existed? How would you write instructions for a machine made of gears?',
 '[
   {"step": 1, "text": "Ada Lovelace was the daughter of poet Lord Byron, raised by her mother to study mathematics — specifically to counteract what her mother feared was the ''dangerous'' poetic imagination she might inherit."},
   {"step": 2, "text": "She befriended Charles Babbage, who designed the Analytical Engine — a mechanical computer never built in his lifetime. Ada translated an Italian mathematician''s article about it, adding her own notes that tripled the length of the original."},
   {"step": 3, "text": "Her notes included what historians recognize as the first algorithm intended to be processed by a machine: a method for calculating Bernoulli numbers. This is widely considered the first computer program."},
   {"step": 4, "text": "More remarkably, she speculated the Engine could compose music and manipulate symbols beyond numbers — anticipating general-purpose computing, artificial intelligence, and symbolic reasoning, 100 years before Turing."}
 ]',
 'Most people imagine programming as inherently electronic. Ada''s insight was that any machine capable of following instructions could be programmed — a conceptual leap that predated the hardware by a century.',
 'How would you explain to a friend what''s remarkable about Ada''s insight — not just that she wrote an algorithm, but what she understood about what machines could eventually become?',
 'Ada Lovelace saw the full potential of computing in 1843. The hardware took 100 years to catch up with the vision.'),

('55555555-0000-0000-0000-000000000003',
 'Alan Turing: The Man Who Saved Millions and Was Destroyed by His Country',
 'He shortened World War II by an estimated two years, saving millions of lives. His reward: a criminal conviction, chemical castration, and death at 41. He is also the father of modern computing.',
 'HISTORY', 'all', 3, 10, TRUE,
 'Before we continue: what do you know about how the Enigma code was broken? And what happened to the person most responsible for breaking it?',
 '[
   {"step": 1, "text": "Turing''s theoretical 1936 paper — describing a hypothetical ''Universal Machine'' that could run any computable algorithm — defined the concept of the modern computer before transistors existed."},
   {"step": 2, "text": "At Bletchley Park during WWII, he designed the Bombe — an electromechanical device that could crack Enigma-encrypted Nazi communications. Historians estimate this shortened the war by 2–4 years, saving 14–21 million lives."},
   {"step": 3, "text": "In 1952, he reported a burglary to police. During the investigation, he disclosed he was in a relationship with a man. He was convicted of ''gross indecency'' under Victorian law still in force at the time."},
   {"step": 4, "text": "Given the choice between prison and chemical castration (hormone treatment to ''cure'' homosexuality), he chose the latter. He died in 1954 from cyanide poisoning — officially ruled suicide. He was 41. The UK granted him a formal pardon in 2013."}
 ]',
 'The distance between his contribution and his treatment is one of history''s most extreme examples of a society destroying the person who saved it. His story forces the question: what other Turings have we lost?',
 'How would you explain the concept of the ''Turing Machine'' to someone who has never studied computer science — the idea that one abstract machine could run any possible computation?',
 'Every device running software today is a physical realization of the theoretical machine Alan Turing described in 1936. He invented the concept of computing before computers existed — then was prosecuted for who he loved.'),

('55555555-0000-0000-0000-000000000004',
 'Cleopatra: The Scholar-Queen History Turned Into a Symbol',
 'Cleopatra is remembered for her beauty and her relationships with Caesar and Antony. She was actually a military strategist, polyglot scholar, and the first Ptolemaic ruler to bother learning Egyptian.',
 'HISTORY', 'all', 2, 8, TRUE,
 'What do you actually know about Cleopatra beyond what you''ve seen in movies? What made her a significant historical figure politically?',
 '[
   {"step": 1, "text": "Cleopatra VII spoke nine languages including Egyptian, Ethiopian, Hebrew, Arabic, and Parthian — making her the first ruler of her dynasty (after 300 years of Greek-speaking Ptolemies) to actually speak to her people in their own language."},
   {"step": 2, "text": "She was a trained philosopher and mathematician, educated at Alexandria — home of the greatest library in the ancient world. Ancient sources describe her as a skilled debater who could hold her own with scholars."},
   {"step": 3, "text": "Her relationships with Julius Caesar and Mark Antony were calculated political alliances — she needed Roman military power to secure her throne against her own family. Caesar helped her defeat her brother (also her co-ruler and husband, per custom)."},
   {"step": 4, "text": "Ancient sources — written by Romans who were her enemies — describe her as an irresistible seductress. Modern historians note these same sources had every reason to portray her as dangerous and manipulative rather than as a competent ruler who almost succeeded in creating an Egypto-Roman superpower."}
 ]',
 'The image of Cleopatra we inherit comes almost entirely from sources written by the people who defeated her. Her actual legacy — as a polyglot scholar, military strategist, and political operator — was written over by her enemies.',
 'How does the source of historical information shape what we think we know? How would history look different if written from Cleopatra''s perspective rather than Rome''s?',
 'Cleopatra''s story is partly about the politics of historical narrative: the winners write the history, and the losers are flattened into symbols. She was a symbol of seduction to Rome. She was the last pharaoh of Egypt.'),

('55555555-0000-0000-0000-000000000005',
 'Nikola Tesla: The Architect of the Modern Electrical World',
 'Tesla held 300 patents, predicted smartphones in 1926, and designed the AC electrical system that powers your home. He died broke and alone in a hotel room. His rival died rich and famous.',
 'HISTORY', 'all', 2, 8, TRUE,
 'Why do you think AC power (alternating current) won over DC power? And what do you know about the ''War of Currents''?',
 '[
   {"step": 1, "text": "Tesla''s alternating current (AC) system can transmit electricity over long distances at high voltage, then step it down for home use via transformers. Edison''s direct current (DC) couldn''t travel more than a mile without massive power loss."},
   {"step": 2, "text": "Edison waged a public campaign against AC, electrocuting animals publicly (including an elephant named Topsy) to demonstrate its danger. Tesla responded by passing 250,000 volts of AC through his own body on stage to show it was controllable."},
   {"step": 3, "text": "Tesla''s AC system was chosen to power the 1893 World''s Fair and Niagara Falls. The entire modern electrical grid — the infrastructure behind every powered device on Earth — is built on his design."},
   {"step": 4, "text": "Tesla''s later work on wireless power transmission and radio was financially sabotaged by JP Morgan, who had backed Marconi instead. Tesla died in 1943 in a New York hotel, $50,000 in debt. The Supreme Court posthumously credited him as radio''s inventor, not Marconi."}
 ]',
 'The War of Currents is often taught as a scientific debate. It was actually a commercial war where the better technology won despite — not because of — the business and PR advantages of its opponent.',
 'Explain to someone why AC beats DC for power distribution — not just that it does, but the underlying physics reason (what can transformers do with AC that they can''t do with DC?)',
 'You''re living in a world built on Tesla''s designs. Every time you plug something in, the AC electricity flowing through the wire is moving through infrastructure he designed over 130 years ago.'),

('55555555-0000-0000-0000-000000000006',
 'Genghis Khan: The Conqueror Who Accidentally Globalized the World',
 'Genghis Khan''s empire killed an estimated 40 million people — roughly 10% of the world''s population. It also created the largest free-trade zone in human history and connected East and West for the first time.',
 'HISTORY', 'all', 3, 9, TRUE,
 'Is it possible for a person responsible for tens of millions of deaths to also have had a net positive effect on human history? What''s your instinct?',
 '[
   {"step": 1, "text": "The Mongol Empire at its peak (1279) stretched from Korea to Hungary — the largest contiguous land empire in history, covering 24 million km². Genghis Khan began as the son of a minor chieftain, kidnapped as a child, and enslaved as a teenager."},
   {"step": 2, "text": "The conquests were catastrophically violent — entire cities were erased. The destruction of Baghdad''s irrigation system in 1258 permanently reduced Iraq''s agricultural capacity. The killing of skilled workers and farmers caused famines that outlasted the wars."},
   {"step": 3, "text": "Within the empire, the Pax Mongolica created the safest overland trade route in history. A merchant could travel from China to Europe without bandits or tolls — unprecedented. This accelerated the Silk Road, transferring paper money, printing, and gunpowder from East to West."},
   {"step": 4, "text": "The Black Death traveled the same Mongol trade routes westward in the 1340s, killing 30–60% of Europe''s population — an unintended consequence of the connectivity the empire created."}
 ]',
 'Both assessments — monster and globalizer — are accurate. The Mongol Empire is one of history''s clearest examples of how an event can simultaneously be catastrophic and transformative for human civilization.',
 'How do historians weigh atrocity against unintended positive consequences? Is it possible to give a net verdict on the Mongol Empire — or does the question itself have a flaw?',
 'The world you live in — with its global trade, paper money, and connected civilizations — owes a partial, uncomfortable debt to the most violent empire in human history.'),

('55555555-0000-0000-0000-000000000007',
 'Leonardo da Vinci: The Man Whose Notebooks Were 500 Years Ahead',
 'Leonardo da Vinci filled 13,000 pages of notebooks with inventions, anatomical drawings, and observations — most never published in his lifetime. Some weren''t understood until the 20th century.',
 'HISTORY', 'all', 2, 8, TRUE,
 'If you could only pick one of Leonardo''s abilities — painter, engineer, scientist, or anatomist — which do you think was his most significant contribution? Why?',
 '[
   {"step": 1, "text": "Leonardo dissected over 30 human corpses, producing anatomical drawings so accurate they were used as medical references for centuries. He described the function of heart valves 400 years before their mechanism was confirmed experimentally."},
   {"step": 2, "text": "His notebooks contain designs for a solar power concentrator, an armored vehicle, a hang glider, a helicopter, a robot, and a solar-powered water pump — none built in his lifetime, most not technically feasible until the 20th century."},
   {"step": 3, "text": "He wrote entirely in mirror script (right to left, reversed letters) — possibly to write faster as a left-hander, or to make casual reading difficult. His notebooks were scattered after his death and only partially assembled centuries later."},
   {"step": 4, "text": "Despite being considered the greatest painter of his era (the Mona Lisa, The Last Supper), Leonardo considered painting a lesser pursuit than science and engineering. He left dozens of paintings unfinished, abandoning them to pursue what he considered more important questions."}
 ]',
 'Most people know Leonardo as a painter. The full picture — anatomist, engineer, scientist, inventor — reveals someone whose curiosity outran his century''s ability to build what he imagined.',
 'How would you explain the concept of a "Renaissance person" using Leonardo as the example — what made his era produce people who crossed disciplines, and is that possible today?',
 'Leonardo''s notebooks contain ideas that waited 500 years for technology to catch up. He was not ahead of his time — his time simply hadn''t arrived yet.');
