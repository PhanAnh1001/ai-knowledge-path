-- V7: Seed 7 Knowledge Nodes — Domain: TECHNOLOGY
-- Shared values for all rows: domain='TECHNOLOGY', age_group='all', is_published=TRUE
-- IDs: 22222222-0000-0000-0000-00000000000{1..7}

INSERT INTO knowledge_nodes (id, title, hook, domain, age_group, difficulty, curiosity_score, is_published,
                              guess_prompt, journey_steps, reveal_text, teach_back_prompt, payoff_insight)
VALUES

('22222222-0000-0000-0000-000000000001',
 'How GPS Actually Works: Satellites and the Speed of Light',
 'Your phone knows its location to within a few meters using signals from satellites 20,000 km away. The math that makes this work also required Einstein''s theory of relativity.',
 'TECHNOLOGY', 'all', 3, 9, TRUE,
 'How do you think GPS calculates your exact position? What information would you need from satellites to figure out where you are?',
 '[
   {"step": 1, "text": "GPS satellites constantly broadcast a signal that includes the exact time (from atomic clocks) and the satellite''s position. Your phone receives signals from at least 4 satellites simultaneously."},
   {"step": 2, "text": "Your device calculates how long each signal took to arrive, multiplies by the speed of light, and gets the distance to each satellite. With 4 distances, it can triangulate your 3D position (latitude, longitude, altitude)."},
   {"step": 3, "text": "Here''s where Einstein comes in: GPS satellites move at 14,000 km/h, causing time dilation (special relativity — clocks run slow when moving fast). They also orbit at high altitude, where weaker gravity causes clocks to run faster (general relativity). Combined, these effects would drift GPS by 10 km per day without correction."},
   {"step": 4, "text": "GPS satellite clocks are pre-adjusted to compensate for both relativistic effects. Without relativistic corrections built into the system, GPS would be useless within hours of launch."}
 ]',
 'Most people guess "signal strength" or "cell towers." The actual mechanism — time-stamped radio signals plus Einstein''s relativity — makes GPS one of the most physics-dependent consumer technologies ever deployed.',
 'Explain to a friend why GPS needs Einstein''s relativity to function. What specifically would go wrong if relativity weren''t accounted for?',
 'Every time you navigate somewhere, your phone is running calculations that depend on Einstein''s 1905 theories. Relativity is not abstract physics — it''s infrastructure.'),

('22222222-0000-0000-0000-000000000002',
 'How the Internet Actually Works: Packets, Routing, and TCP/IP',
 'When you load a webpage, your request fragments into hundreds of pieces, travels multiple different routes across continents, reassembles in the right order, and renders in milliseconds. Nothing is in charge.',
 'TECHNOLOGY', 'all', 3, 9, TRUE,
 'When you send a message to someone across the world, what do you imagine is actually happening at the network level? How does the data get there?',
 '[
   {"step": 1, "text": "Data is split into packets — small chunks typically 1,500 bytes each — each labeled with source address, destination address, and sequence number. A single webpage might require hundreds of packets."},
   {"step": 2, "text": "Each packet is independently routed across the network by devices called routers. A router examines the destination address and forwards the packet toward the destination — but different packets from the same request can take entirely different physical paths."},
   {"step": 3, "text": "TCP (Transmission Control Protocol) handles reassembly: the receiving end collects all packets and uses sequence numbers to reassemble them in the correct order, requesting re-transmission of any that are lost or corrupted."},
   {"step": 4, "text": "The internet has no central coordinator. It''s a decentralized network of networks — routers share routing tables with neighbors, and the system self-organizes around failures automatically. The original ARPANET was designed this way explicitly to survive nuclear attacks."}
 ]',
 'Most people imagine a direct pipe between devices. The reality — fragmented, independently routed, reassembled, with no central authority — is what makes the internet simultaneously resilient and remarkable.',
 'Explain packet switching to someone using an analogy: if you had to mail a book by tearing it into 300 pieces and sending each piece separately, what would be the advantages and challenges?',
 'The internet has no owner, no central computer, and no master controller. It''s one of the largest self-organizing systems humans have ever built — and it works because of rules everyone agreed to follow.'),

('22222222-0000-0000-0000-000000000003',
 'Encryption: How HTTPS Keeps Your Passwords Secret',
 'When you type a password on a website, it travels across dozens of computers before reaching the server. Anyone watching could read it — unless HTTPS is involved. The math that prevents this is elegant.',
 'TECHNOLOGY', 'all', 3, 9, TRUE,
 'How do you think your password gets securely sent to a website? If someone was watching your internet traffic, why couldn''t they just read it?',
 '[
   {"step": 1, "text": "HTTPS uses TLS (Transport Layer Security) to encrypt data. Before any data is exchanged, your browser and the server perform a ''handshake'' — they agree on an encryption method and exchange keys without ever sending the keys over the network."},
   {"step": 2, "text": "This is possible through asymmetric encryption (public-key cryptography): the server sends a public key anyone can see. Your browser uses it to encrypt a secret. Only the server''s private key can decrypt it. A spy watching the handshake cannot derive the private key."},
   {"step": 3, "text": "The security is based on mathematical hardness: multiplying two huge prime numbers is easy; factoring the result back into those primes is computationally infeasible with today''s computers (RSA). Breaking 2048-bit RSA would take longer than the age of the universe with current hardware."},
   {"step": 4, "text": "Symmetric encryption then takes over for the actual data: both parties now share a session key that was negotiated securely. Symmetric encryption is much faster than asymmetric and is used to encrypt the actual HTTP traffic."}
 ]',
 'Most people think of encryption as a lock. The elegant twist is that public-key cryptography solves a problem that seemed impossible: how do two strangers agree on a secret without ever meeting, over a channel where anyone can listen?',
 'Explain to a non-technical friend why public-key cryptography is remarkable: "Imagine you want to agree on a secret with someone you''ve never met, in public, where anyone can listen — how?',
 'Public-key cryptography, invented in 1976, made secure internet commerce possible. Every HTTPS connection uses math that would have seemed like magic to the engineers who built the first networks.'),

('22222222-0000-0000-0000-000000000004',
 'How LLMs Work: Predicting the Next Word at Massive Scale',
 'Large language models like GPT don''t "understand" language — they predict what text is most likely to come next, trained on nearly all human writing. And yet the results are startlingly coherent.',
 'TECHNOLOGY', 'all', 4, 10, TRUE,
 'How do you think AI language models actually generate text? What''s your mental model of what''s happening inside?',
 '[
   {"step": 1, "text": "LLMs are trained on vast text datasets (books, websites, code) to predict the next token (roughly, word piece) given all previous tokens. The training adjusts billions of numerical weights to maximize prediction accuracy across the dataset."},
   {"step": 2, "text": "The key architecture is the Transformer''s attention mechanism: for each token, the model learns to weight how relevant every other token in the context is to predicting the next one. This lets it capture long-range dependencies — a pronoun hundreds of words after its referent."},
   {"step": 3, "text": "At inference (generation) time, the model doesn''t retrieve stored answers — it computes a probability distribution over all possible next tokens and samples from it. ''Temperature'' controls randomness: high temperature = more creative/random; low temperature = more predictable/focused."},
   {"step": 4, "text": "Emergent capabilities — reasoning, translation, coding — were not explicitly programmed. They arose from scale: as models grew from millions to hundreds of billions of parameters, qualitatively new capabilities appeared that weren''t present in smaller versions."}
 ]',
 'Most people imagine LLMs as a database or a search engine. The reality — statistical prediction at enormous scale producing emergent reasoning — is what makes them both powerful and unpredictable.',
 'Explain to someone skeptical of AI: if a model is "just predicting the next word," why does it sometimes seem to reason? What''s your theory of what''s actually happening?',
 'LLMs emerged from a simple objective — predict the next word — applied at a scale no one had tried before. The capabilities that appeared were not designed. They were discovered.'),

('22222222-0000-0000-0000-000000000005',
 'Moore''s Law: Why Computers Double in Power Every Two Years',
 'In 1965, Gordon Moore predicted that the number of transistors on a chip would double every two years. He was right for 60 years. Understanding why it''s now ending reveals the physical limits of computation.',
 'TECHNOLOGY', 'all', 3, 8, TRUE,
 'Why do you think computers have gotten so much faster and cheaper over the decades? What''s the physical mechanism behind it?',
 '[
   {"step": 1, "text": "Transistors are switches — binary on/off components. More transistors = more computation per clock cycle. In 1971, Intel''s first processor had 2,300 transistors. Today''s chips have over 100 billion."},
   {"step": 2, "text": "Doubling transistors requires halving their size. Transistors are now measured in nanometers (a human hair is ~80,000 nm wide). The most advanced chips use 2–3 nm transistors — meaning the gate controlling current flow is only ~10 silicon atoms wide."},
   {"step": 3, "text": "At this scale, quantum tunneling becomes a problem: electrons stop obeying classical physics and start ''tunneling'' through barriers they classically shouldn''t cross, causing current leakage and erratic behavior."},
   {"step": 4, "text": "Moore''s Law is slowing for classical silicon. The industry is responding with 3D chip stacking (layering chips vertically), specialized processors (GPUs, TPUs), and research into quantum computing and new materials like gallium nitride."}
 ]',
 'Most people experience Moore''s Law as "phones get faster." The underlying story — engineering racing toward the quantum limit of silicon — is one of the most sustained technological achievements in human history.',
 'Explain why Moore''s Law is slowing down: what physical barrier makes it impossible to keep shrinking transistors indefinitely? Use the quantum tunneling concept in your explanation.',
 'Sixty years of Moore''s Law is why a phone in your pocket has more computing power than all the computers NASA used to land on the moon. That era is ending — and what comes next is being figured out now.'),

('22222222-0000-0000-0000-000000000006',
 'The Algorithm Behind Your Feed: Recommendation Systems',
 'Netflix, TikTok, Spotify, and YouTube don''t just show you things you like — they shape what you like next. The algorithm''s goal is engagement, and that objective has unexpected consequences.',
 'TECHNOLOGY', 'all', 2, 9, TRUE,
 'Do you think recommendation algorithms understand you, or are they just pattern-matching? And does it matter which one it is?',
 '[
   {"step": 1, "text": "Collaborative filtering: the algorithm finds users similar to you (based on watch/listen/click history) and recommends what those users liked. No understanding of content — pure behavioral pattern-matching."},
   {"step": 2, "text": "Content-based filtering adds features about the content itself (genre, tempo, duration, topic tags) to recommend similar items to what you engaged with, even if no other user has watched both."},
   {"step": 3, "text": "Modern systems combine both approaches and optimize for an engagement metric — watch time, clicks, likes. The algorithm is not trying to make you happy or informed; it''s maximizing the specific signal it was told to maximize."},
   {"step": 4, "text": "Optimizing for engagement can produce filter bubbles (only showing confirming content), outrage amplification (angry content drives more engagement than neutral content), and rabbit holes (each recommendation is slightly more extreme than the last to maintain novelty)."}
 ]',
 'Most people experience recommendation algorithms as helpful or annoying. The structural reality — an optimizer maximizing a proxy metric that is not identical to human well-being — has implications far beyond music discovery.',
 'Explain to someone why "optimizing for engagement" is different from "optimizing for user satisfaction." What would a recommendation algorithm look like if it optimized for something different?',
 'You are not the customer of a recommendation algorithm — you are the product. Your attention is being sold, and the algorithm is designed to maximize how much of it you give.'),

('22222222-0000-0000-0000-000000000007',
 'CRISPR: How Scientists Learned to Edit the Code of Life',
 'In 2012, scientists discovered they could edit DNA with the precision of a word processor — cut a specific gene, delete it, or replace it. The tool came from bacteria. The implications are still unfolding.',
 'TECHNOLOGY', 'all', 3, 10, TRUE,
 'If you could edit the genes of an unborn human to remove a disease, would you? Where would you draw the line — and who should decide?',
 '[
   {"step": 1, "text": "CRISPR (Clustered Regularly Interspaced Short Palindromic Repeats) is a bacterial immune system. Bacteria store snippets of viral DNA and use them to recognize and cut matching viral DNA if the virus attacks again."},
   {"step": 2, "text": "Scientists repurposed this as a gene-editing tool: Cas9 (an enzyme) is guided by a synthetic RNA sequence to a specific location in any genome, where it cuts the DNA. The cell''s own repair machinery then fixes the cut — you can control whether it deletes the gene, disrupts it, or inserts new sequence."},
   {"step": 3, "text": "CRISPR has already been used to treat sickle cell disease in humans (approved therapies in 2023), eliminate certain cancers in mice, and create disease-resistant crops. It''s faster, cheaper, and more precise than any previous gene-editing technology by orders of magnitude."},
   {"step": 4, "text": "In 2018, a Chinese scientist used CRISPR to edit human embryos that were carried to term — producing the first ''gene-edited babies'' with modified CCR5 genes intended to confer HIV resistance. The scientific community responded with widespread condemnation; he was sentenced to prison. The edited children are alive."}
 ]',
 'CRISPR is simultaneously a medical breakthrough and an ethical frontier. The technology itself is neutral; the questions about who controls it, who benefits, and where to stop are not.',
 'Explain the CRISPR mechanism using the ''find and replace'' analogy for a non-biologist. What are the limits of that analogy — where does it break down?',
 'Bacteria invented a way to remember and defeat viruses. Humans stole it and used it to rewrite the code of life. The first gene-edited humans are already alive. The rest of the story is being written now.');
