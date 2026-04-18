// =============================================================================
// AI Knowledge Path — Neo4j Knowledge Graph Schema
// Version: 1.0
// =============================================================================
// Cấu trúc:
//   Node labels:  KnowledgeNode, Domain, Concept, SessionTemplate
//   Relationships: LEADS_TO, DEEP_DIVE, CROSS_DOMAIN, BELONGS_TO,
//                  PART_OF_CLUSTER, REQUIRES, TAGGED_WITH
// =============================================================================


// =============================================================================
// CONSTRAINTS & INDEXES
// =============================================================================

// Unique constraints
CREATE CONSTRAINT knowledge_node_id IF NOT EXISTS
  FOR (n:KnowledgeNode) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT domain_name IF NOT EXISTS
  FOR (d:Domain) REQUIRE d.name IS UNIQUE;

CREATE CONSTRAINT concept_id IF NOT EXISTS
  FOR (c:Concept) REQUIRE c.id IS UNIQUE;

CREATE CONSTRAINT cluster_id IF NOT EXISTS
  FOR (cl:Cluster) REQUIRE cl.id IS UNIQUE;

// Indexes cho query phổ biến
CREATE INDEX knowledge_node_domain   IF NOT EXISTS FOR (n:KnowledgeNode) ON (n.domain);
CREATE INDEX knowledge_node_diff     IF NOT EXISTS FOR (n:KnowledgeNode) ON (n.difficulty);
CREATE INDEX knowledge_node_published IF NOT EXISTS FOR (n:KnowledgeNode) ON (n.is_published);
CREATE INDEX knowledge_node_age      IF NOT EXISTS FOR (n:KnowledgeNode) ON (n.age_group);


// =============================================================================
// NODE: Domain
// =============================================================================
// 4 lĩnh vực chính — khớp với explorer_type trong PostgreSQL

CREATE (:Domain {
  name:        'nature',         // tự nhiên, sinh học, vũ trụ
  label_vi:    'Khám phá tự nhiên',
  color:       '#4CAF50',
  icon:        'leaf'
});

CREATE (:Domain {
  name:        'technology',     // khoa học, kỹ thuật, lập trình
  label_vi:    'Công nghệ & Khoa học',
  color:       '#2196F3',
  icon:        'circuit'
});

CREATE (:Domain {
  name:        'history',        // lịch sử, văn minh, địa lý
  label_vi:    'Lịch sử & Văn minh',
  color:       '#FF9800',
  icon:        'scroll'
});

CREATE (:Domain {
  name:        'creative',       // nghệ thuật, triết học, tâm lý
  label_vi:    'Sáng tạo & Tư duy',
  color:       '#9C27B0',
  icon:        'star'
});


// =============================================================================
// NODE: Concept
// =============================================================================
// Khái niệm nền — một Concept có thể xuất hiện ở nhiều domain (cross-domain)
// Ví dụ: "fractal" xuất hiện trong nature (vân tay), technology (mã hóa), creative (nghệ thuật)

CREATE (:Concept {
  id:          'concept-fibonacci',
  name:        'Fibonacci & Dãy số tăng trưởng',
  description: 'Mẫu tăng trưởng tự nhiên xuất hiện khắp nơi trong tự nhiên và nghệ thuật'
});

CREATE (:Concept {
  id:          'concept-pressure',
  name:        'Áp suất & Cân bằng',
  description: 'Nguyên lý cân bằng lực xuất hiện từ vật lý đến sinh học'
});

CREATE (:Concept {
  id:          'concept-adaptation',
  name:        'Thích nghi & Tiến hóa',
  description: 'Cơ chế thay đổi để tồn tại qua thời gian'
});


// =============================================================================
// NODE: Cluster
// =============================================================================
// Nhóm các KnowledgeNode liên quan — dùng để gợi ý "Rabbit Hole Mode"

CREATE (:Cluster {
  id:       'cluster-deep-ocean',
  name:     'Đại dương sâu thẳm',
  domain:   'nature',
  size:     8
});

CREATE (:Cluster {
  id:       'cluster-human-brain',
  name:     'Não người & Nhận thức',
  domain:   'nature',
  size:     10
});

CREATE (:Cluster {
  id:       'cluster-ancient-civ',
  name:     'Văn minh cổ đại',
  domain:   'history',
  size:     12
});


// =============================================================================
// NODE: KnowledgeNode
// =============================================================================
// Mỗi node = 1 session học (5–8 phút)

// age_group: 'child_8_10' | 'teen_11_17' | 'adult_18_plus' | 'all'
// difficulty: 1 (dễ) → 5 (khó)
// curiosity_score: 1–10 (mức độ "bất ngờ/phản trực giác" — dùng để ưu tiên làm Hook)
// is_published: false = bản nháp chưa duyệt

// --- nature ---

MERGE (n1:KnowledgeNode {id: 'node-octopus-hearts'})
SET n1 += {
  title:          'Tại sao bạch tuộc có 3 trái tim?',
  hook:           'Bạch tuộc có 3 tim — và chúng ngừng đập khi bơi. Vậy bạch tuộc làm gì khi cần chạy trốn?',
  domain:         'nature',
  age_group:      'all',
  difficulty:     2,
  curiosity_score: 9,
  tags:           ['marine', 'biology', 'evolution'],
  is_published:   true,
  pg_id:          'uuid-placeholder'   // đồng bộ với PostgreSQL knowledge_nodes.id
};

MERGE (n2:KnowledgeNode {id: 'node-octopus-color'})
SET n2 += {
  title:          'Tại sao bạch tuộc đổi màu dù mù màu?',
  hook:           'Bạch tuộc không nhìn thấy màu sắc, nhưng ngụy trang hoàn hảo. Bí ẩn nằm ở đâu?',
  domain:         'nature',
  age_group:      'all',
  difficulty:     3,
  curiosity_score: 10,
  tags:           ['marine', 'neuroscience', 'perception'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

MERGE (n3:KnowledgeNode {id: 'node-shark-older-tree'})
SET n3 += {
  title:          'Tại sao cá mập xuất hiện trước cả cây cối?',
  hook:           'Cá mập có mặt trên Trái Đất 200 triệu năm trước khi cây đầu tiên mọc lên.',
  domain:         'nature',
  age_group:      'all',
  difficulty:     2,
  curiosity_score: 10,
  tags:           ['evolution', 'paleontology', 'marine'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

MERGE (n4:KnowledgeNode {id: 'node-deep-sea-pressure'})
SET n4 += {
  title:          'Tại sao sinh vật biển sâu không bị áp suất nghiền nát?',
  hook:           'Ở độ sâu 11km, áp suất gấp 1000 lần bề mặt. Cá vẫn sống bình thường.',
  domain:         'nature',
  age_group:      'child_8_10',
  difficulty:     2,
  curiosity_score: 8,
  tags:           ['marine', 'physics', 'adaptation'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

MERGE (n5:KnowledgeNode {id: 'node-coral-bleaching'})
SET n5 += {
  title:          'Tại sao san hô bị tẩy trắng?',
  hook:           'San hô không phải đá — chúng là sinh vật sống. Và đang chết dần.',
  domain:         'nature',
  age_group:      'all',
  difficulty:     3,
  curiosity_score: 7,
  tags:           ['marine', 'climate', 'ecosystem'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

// --- technology ---

MERGE (n6:KnowledgeNode {id: 'node-gps-relativity'})
SET n6 += {
  title:          'GPS hoạt động nhờ thuyết tương đối?',
  hook:           'Nếu không có Einstein, GPS của bạn sẽ sai 11km mỗi ngày.',
  domain:         'technology',
  age_group:      'teen_11_17',
  difficulty:     4,
  curiosity_score: 10,
  tags:           ['physics', 'engineering', 'space'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

MERGE (n7:KnowledgeNode {id: 'node-why-wifi-2.4ghz'})
SET n7 += {
  title:          'Tại sao WiFi dùng tần số lò vi sóng?',
  hook:           'Lò vi sóng và WiFi dùng cùng tần số 2.4GHz. Tại sao điện thoại không chín?',
  domain:         'technology',
  age_group:      'all',
  difficulty:     3,
  curiosity_score: 9,
  tags:           ['physics', 'engineering', 'everyday'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

// --- history ---

MERGE (n8:KnowledgeNode {id: 'node-roman-concrete'})
SET n8 += {
  title:          'Tại sao bê tông La Mã bền hơn bê tông hiện đại?',
  hook:           'Đền Pantheon 2000 tuổi vẫn đứng vững. Bê tông ngày nay chỉ bền 50 năm.',
  domain:         'history',
  age_group:      'all',
  difficulty:     3,
  curiosity_score: 9,
  tags:           ['engineering', 'ancient', 'materials'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};

// --- creative ---

MERGE (n9:KnowledgeNode {id: 'node-golden-ratio'})
SET n9 += {
  title:          'Tỉ lệ vàng có thật sự xuất hiện khắp nơi?',
  hook:           'Mọi người nói tỉ lệ vàng ở khắp nơi. Nhưng phần lớn là... bịa đặt.',
  domain:         'creative',
  age_group:      'all',
  difficulty:     3,
  curiosity_score: 8,
  tags:           ['math', 'art', 'myth-busting'],
  is_published:   true,
  pg_id:          'uuid-placeholder'
};


// =============================================================================
// RELATIONSHIPS
// =============================================================================

// -----------------------------------------------------------------------------
// BELONGS_TO — KnowledgeNode thuộc Domain
// -----------------------------------------------------------------------------
MATCH (n:KnowledgeNode), (d:Domain)
WHERE n.domain = d.name
MERGE (n)-[:BELONGS_TO]->(d);


// -----------------------------------------------------------------------------
// PART_OF_CLUSTER — KnowledgeNode thuộc Cluster
// -----------------------------------------------------------------------------
MATCH (n:KnowledgeNode {id: 'node-octopus-hearts'}),   (c:Cluster {id: 'cluster-deep-ocean'}) MERGE (n)-[:PART_OF_CLUSTER]->(c);
MATCH (n:KnowledgeNode {id: 'node-octopus-color'}),     (c:Cluster {id: 'cluster-deep-ocean'}) MERGE (n)-[:PART_OF_CLUSTER]->(c);
MATCH (n:KnowledgeNode {id: 'node-shark-older-tree'}),  (c:Cluster {id: 'cluster-deep-ocean'}) MERGE (n)-[:PART_OF_CLUSTER]->(c);
MATCH (n:KnowledgeNode {id: 'node-deep-sea-pressure'}), (c:Cluster {id: 'cluster-deep-ocean'}) MERGE (n)-[:PART_OF_CLUSTER]->(c);
MATCH (n:KnowledgeNode {id: 'node-coral-bleaching'}),   (c:Cluster {id: 'cluster-deep-ocean'}) MERGE (n)-[:PART_OF_CLUSTER]->(c);


// -----------------------------------------------------------------------------
// TAGGED_WITH — KnowledgeNode ↔ Concept (cross-domain concept link)
// -----------------------------------------------------------------------------
MATCH (n:KnowledgeNode {id: 'node-deep-sea-pressure'}), (c:Concept {id: 'concept-pressure'})  MERGE (n)-[:TAGGED_WITH]->(c);
MATCH (n:KnowledgeNode {id: 'node-shark-older-tree'}),  (c:Concept {id: 'concept-adaptation'}) MERGE (n)-[:TAGGED_WITH]->(c);
MATCH (n:KnowledgeNode {id: 'node-golden-ratio'}),      (c:Concept {id: 'concept-fibonacci'})  MERGE (n)-[:TAGGED_WITH]->(c);


// -----------------------------------------------------------------------------
// LEADS_TO — node A mở ra node B sau khi hoàn thành
//   Properties:
//     weight       float 0–1  — mức độ liên quan (dùng để ưu tiên gợi ý)
//     relation_vi  string     — nhãn hiển thị trên UI ("Khám phá tiếp", "Đào sâu hơn"...)
// -----------------------------------------------------------------------------

// Sau bạch tuộc tim → gợi ý bạch tuộc màu + cá mập + áp suất biển sâu
MATCH (a:KnowledgeNode {id: 'node-octopus-hearts'}), (b:KnowledgeNode {id: 'node-octopus-color'})
MERGE (a)-[:LEADS_TO {weight: 0.95, relation_vi: 'Cùng loài, bí ẩn hơn'}]->(b);

MATCH (a:KnowledgeNode {id: 'node-octopus-hearts'}), (b:KnowledgeNode {id: 'node-shark-older-tree'})
MERGE (a)-[:LEADS_TO {weight: 0.80, relation_vi: 'Sinh vật biển cổ đại hơn'}]->(b);

MATCH (a:KnowledgeNode {id: 'node-octopus-hearts'}), (b:KnowledgeNode {id: 'node-deep-sea-pressure'})
MERGE (a)-[:LEADS_TO {weight: 0.75, relation_vi: 'Môi trường biển sâu'}]->(b);

// Sau bạch tuộc màu → gợi ý san hô + áp suất + tỉ lệ vàng (cross-domain)
MATCH (a:KnowledgeNode {id: 'node-octopus-color'}), (b:KnowledgeNode {id: 'node-coral-bleaching'})
MERGE (a)-[:LEADS_TO {weight: 0.85, relation_vi: 'Sinh vật biển có màu sắc'}]->(b);

MATCH (a:KnowledgeNode {id: 'node-octopus-color'}), (b:KnowledgeNode {id: 'node-golden-ratio'})
MERGE (a)-[:LEADS_TO {weight: 0.60, relation_vi: 'Màu sắc trong nghệ thuật & tự nhiên'}]->(b);

// GPS → WiFi (cùng domain technology, cùng chủ đề sóng/tần số)
MATCH (a:KnowledgeNode {id: 'node-gps-relativity'}), (b:KnowledgeNode {id: 'node-why-wifi-2.4ghz'})
MERGE (a)-[:LEADS_TO {weight: 0.70, relation_vi: 'Vật lý trong cuộc sống hàng ngày'}]->(b);


// -----------------------------------------------------------------------------
// DEEP_DIVE — node A có bản "đào sâu" là node B (Rabbit Hole Mode — Premium)
//   Thường là cùng topic nhưng difficulty cao hơn, hoặc góc nhìn khác
// -----------------------------------------------------------------------------

MATCH (a:KnowledgeNode {id: 'node-octopus-hearts'}), (b:KnowledgeNode {id: 'node-octopus-color'})
MERGE (a)-[:DEEP_DIVE {depth_level: 1}]->(b);

MATCH (a:KnowledgeNode {id: 'node-shark-older-tree'}), (b:KnowledgeNode {id: 'node-deep-sea-pressure'})
MERGE (a)-[:DEEP_DIVE {depth_level: 1}]->(b);

MATCH (a:KnowledgeNode {id: 'node-coral-bleaching'}), (b:KnowledgeNode {id: 'node-deep-sea-pressure'})
MERGE (a)-[:DEEP_DIVE {depth_level: 2}]->(b);


// -----------------------------------------------------------------------------
// CROSS_DOMAIN — liên kết xuyên domain (thể hiện Knowledge Compounding liên ngành)
//   Dùng khi một concept xuất hiện ở 2 domain khác nhau
// -----------------------------------------------------------------------------

// Bê tông La Mã ↔ áp suất biển sâu (cùng concept "vật liệu chịu lực")
MATCH (a:KnowledgeNode {id: 'node-roman-concrete'}), (b:KnowledgeNode {id: 'node-deep-sea-pressure'})
MERGE (a)-[:CROSS_DOMAIN {
  concept:     'structural_strength',
  insight_vi:  'Cả hai đều giải quyết vấn đề chịu lực cực độ theo cách bất ngờ'
}]->(b);

// Tỉ lệ vàng ↔ bạch tuộc màu sắc (cùng concept "pattern trong tự nhiên")
MATCH (a:KnowledgeNode {id: 'node-golden-ratio'}), (b:KnowledgeNode {id: 'node-octopus-color'})
MERGE (a)-[:CROSS_DOMAIN {
  concept:     'natural_pattern',
  insight_vi:  'Tự nhiên tạo ra các mẫu hình mà không cần "biết" toán học'
}]->(b);

// WiFi tần số ↔ GPS tương đối (cùng domain nhưng concept khác: sóng điện từ)
MATCH (a:KnowledgeNode {id: 'node-why-wifi-2.4ghz'}), (b:KnowledgeNode {id: 'node-gps-relativity'})
MERGE (a)-[:CROSS_DOMAIN {
  concept:     'electromagnetic_wave',
  insight_vi:  'Sóng điện từ — từ lò vi sóng đến định vị vệ tinh'
}]->(b);


// -----------------------------------------------------------------------------
// REQUIRES — node B yêu cầu đã học node A (prerequisite, optional soft constraint)
// -----------------------------------------------------------------------------

// Hiểu áp suất biển sâu giúp hiểu san hô tốt hơn
MATCH (a:KnowledgeNode {id: 'node-deep-sea-pressure'}), (b:KnowledgeNode {id: 'node-coral-bleaching'})
MERGE (a)-[:REQUIRES {soft: true}]->(b);
// soft: true = gợi ý học trước, không bắt buộc


// =============================================================================
// COMMON QUERIES
// =============================================================================

// --- Q1: Gợi ý 3 node tiếp theo sau khi hoàn thành một session ---
// Input: node_id đã hoàn thành, user đã học node_ids nào
//
// MATCH (done:KnowledgeNode {id: $completedNodeId})-[r:LEADS_TO]->(next:KnowledgeNode)
// WHERE next.is_published = true
//   AND NOT next.id IN $completedNodeIds
// RETURN next, r.weight AS weight, r.relation_vi AS label
// ORDER BY r.weight DESC
// LIMIT 3

// --- Q2: Lấy subgraph cho knowledge map visualization ---
// Input: user_id, tất cả node đã học
//
// MATCH (n:KnowledgeNode)
// WHERE n.id IN $seenNodeIds
// WITH n
// MATCH (n)-[r:LEADS_TO|CROSS_DOMAIN]-(neighbor:KnowledgeNode)
// WHERE neighbor.is_published = true
// RETURN n, r, neighbor
// LIMIT 100

// --- Q3: Rabbit Hole Mode — chuỗi deep dive ---
// Input: node_id khởi đầu, depth tối đa
//
// MATCH path = (start:KnowledgeNode {id: $nodeId})-[:DEEP_DIVE*1..3]->(end:KnowledgeNode)
// WHERE end.is_published = true
// RETURN path ORDER BY length(path) ASC

// --- Q4: Cross-domain surprises (Premium "Kết nối bất ngờ") ---
// Input: node_id vừa học
//
// MATCH (n:KnowledgeNode {id: $nodeId})-[r:CROSS_DOMAIN]-(other:KnowledgeNode)
// WHERE other.domain <> n.domain AND other.is_published = true
// RETURN other, r.insight_vi AS insight
// ORDER BY rand()
// LIMIT 2

// --- Q5: Nodes cùng cluster (Rabbit Hole Mode) ---
// Input: cluster_id
//
// MATCH (n:KnowledgeNode)-[:PART_OF_CLUSTER]->(c:Cluster {id: $clusterId})
// WHERE n.is_published = true
// RETURN n ORDER BY n.difficulty ASC

// --- Q6: Nodes chưa học theo domain, sắp xếp theo curiosity_score ---
// Input: domain, user's completedNodeIds
//
// MATCH (n:KnowledgeNode {domain: $domain, is_published: true})
// WHERE NOT n.id IN $completedNodeIds
// RETURN n ORDER BY n.curiosity_score DESC, n.difficulty ASC
// LIMIT 10


// =============================================================================
// SEED DATA — 12 KnowledgeNode legacy (đồng bộ UUID với PostgreSQL init.sql)
// NOTE: IDs 11111111-001..003, 22222222-001..003, 44444444-001..003 được
//       ghi đè bởi V5-V8 migrations (xem section "V5–V8 SEED DATA" bên dưới)
// =============================================================================

// ── Nature ───────────────────────────────────────────────────────────────────
MERGE (n1:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'})
  SET n1.title = 'Tại sao bướm phải trải qua biến thái hoàn toàn?',
      n1.domain = 'nature', n1.age_group = 'child_8_10',
      n1.difficulty = 2, n1.curiosity_score = 9, n1.is_published = true;

MERGE (n2:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'})
  SET n2.title = 'Tại sao bầu trời có màu xanh mà hoàng hôn lại đỏ?',
      n2.domain = 'nature', n2.age_group = 'teen_11_17',
      n2.difficulty = 3, n2.curiosity_score = 8, n2.is_published = true;

MERGE (n3:KnowledgeNode {id: '11111111-0000-0000-0000-000000000003'})
  SET n3.title = 'Cây cối giao tiếp với nhau qua đất như thế nào?',
      n3.domain = 'nature', n3.age_group = 'adult_18_plus',
      n3.difficulty = 4, n3.curiosity_score = 10, n3.is_published = true;

// ── Technology ───────────────────────────────────────────────────────────────
MERGE (t1:KnowledgeNode {id: '22222222-0000-0000-0000-000000000001'})
  SET t1.title = 'GPS biết bạn đang ở đâu chính xác đến từng mét bằng cách nào?',
      t1.domain = 'technology', t1.age_group = 'teen_11_17',
      t1.difficulty = 3, t1.curiosity_score = 9, t1.is_published = true;

MERGE (t2:KnowledgeNode {id: '22222222-0000-0000-0000-000000000002'})
  SET t2.title = 'Internet thực ra là gì — vật lý mà nói?',
      t2.domain = 'technology', t2.age_group = 'child_8_10',
      t2.difficulty = 2, t2.curiosity_score = 8, t2.is_published = true;

MERGE (t3:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'})
  SET t3.title = 'Mã hóa hoạt động như thế nào — và tại sao ngay cả NSA cũng không crack được?',
      t3.domain = 'technology', t3.age_group = 'adult_18_plus',
      t3.difficulty = 5, t3.curiosity_score = 9, t3.is_published = true;

// ── History ───────────────────────────────────────────────────────────────────
MERGE (h1:KnowledgeNode {id: '33333333-0000-0000-0000-000000000001'})
  SET h1.title = 'Kim tự tháp được xây thế nào khi chưa có máy móc hiện đại?',
      h1.domain = 'history', h1.age_group = 'child_8_10',
      h1.difficulty = 2, h1.curiosity_score = 9, h1.is_published = true;

MERGE (h2:KnowledgeNode {id: '33333333-0000-0000-0000-000000000002'})
  SET h2.title = 'Thư viện Alexandria thực sự bị phá hủy như thế nào?',
      h2.domain = 'history', h2.age_group = 'teen_11_17',
      h2.difficulty = 3, h2.curiosity_score = 8, h2.is_published = true;

MERGE (h3:KnowledgeNode {id: '33333333-0000-0000-0000-000000000003'})
  SET h3.title = 'Con đường Tơ Lụa đã thay đổi thế giới như thế nào?',
      h3.domain = 'history', h3.age_group = 'adult_18_plus',
      h3.difficulty = 4, h3.curiosity_score = 8, h3.is_published = true;

// ── Creative ──────────────────────────────────────────────────────────────────
MERGE (c1:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'})
  SET c1.title = 'Tại sao âm nhạc làm chúng ta rùng mình và khóc?',
      c1.domain = 'creative', c1.age_group = 'teen_11_17',
      c1.difficulty = 3, c1.curiosity_score = 10, c1.is_published = true;

MERGE (c2:KnowledgeNode {id: '44444444-0000-0000-0000-000000000002'})
  SET c2.title = 'Màu sắc trộn lẫn: tại sao máy in dùng CMYK còn màn hình dùng RGB?',
      c2.domain = 'creative', c2.age_group = 'child_8_10',
      c2.difficulty = 2, c2.curiosity_score = 7, c2.is_published = true;

MERGE (c3:KnowledgeNode {id: '44444444-0000-0000-0000-000000000003'})
  SET c3.title = 'Khoa học của storytelling: tại sao não người bị cuốn vào câu chuyện?',
      c3.domain = 'creative', c3.age_group = 'adult_18_plus',
      c3.difficulty = 4, c3.curiosity_score = 9, c3.is_published = true;


// =============================================================================
// RELATIONSHIPS — Knowledge Graph Edges
// LEADS_TO: hoàn thành node A mở ra node B
// DEEP_DIVE: đi sâu hơn vào cùng chủ đề (Rabbit Hole Mode)
// CROSS_DOMAIN: kết nối liên ngành bất ngờ
// =============================================================================

// ── Nature LEADS_TO chain ─────────────────────────────────────────────────────
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.8}]->(b);

MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000003'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.9}]->(b);

// ── Technology LEADS_TO chain ─────────────────────────────────────────────────
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000001'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.85}]->(b);

MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.9}]->(b);

// ── History LEADS_TO chain ────────────────────────────────────────────────────
MATCH (a:KnowledgeNode {id: '33333333-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '33333333-0000-0000-0000-000000000002'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.8}]->(b);

MATCH (a:KnowledgeNode {id: '33333333-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '33333333-0000-0000-0000-000000000003'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.85}]->(b);

// ── Creative LEADS_TO chain ───────────────────────────────────────────────────
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.9}]->(b);

MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000003'})
MERGE (a)-[:LEADS_TO {curiosity_boost: 0.95}]->(b);

// ── DEEP_DIVE — cùng chủ đề, sâu hơn ────────────────────────────────────────
// Bướm → ánh sáng (cùng "tại sao thiên nhiên phức tạp?")
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'})
MERGE (a)-[:DEEP_DIVE]->(b);

// Cây cối → storytelling (cùng "giao tiếp không lời")
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000003'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000003'})
MERGE (a)-[:DEEP_DIVE]->(b);

// ── CROSS_DOMAIN — kết nối liên ngành bất ngờ ────────────────────────────────
// Ánh sáng (nature) ↔ RGB/CMYK (creative): cùng là vật lý ánh sáng
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000002'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.9}]->(b);

// Mã hóa (technology) ↔ Con đường Tơ Lụa (history): bí mật và thông tin
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'}),
      (b:KnowledgeNode {id: '33333333-0000-0000-0000-000000000003'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.85}]->(b);

// Storytelling (creative) ↔ GPS (technology): cách não xử lý "vị trí"
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000003'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000001'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.75}]->(b);

// Âm nhạc (creative) ↔ Biến thái bướm (nature): cùng chủ đề "biến đổi"
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.8}]->(b);

// =============================================================================
// V5–V8 SEED DATA — 30 KnowledgeNode (sync với PostgreSQL V5–V8 migrations)
// Version: 2.0  |  Added: 2026-03-22
// Dùng MERGE để upsert — an toàn khi chạy lại
// =============================================================================

// ── NATURE (V5) — IDs: 11111111-0000-0000-0000-00000000000{1..10} ─────────────

MERGE (nat01:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'})
SET nat01 += {title: 'Photosynthesis: How Plants Make Food from Light',
              domain: 'nature', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (nat02:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'})
SET nat02 += {title: 'Monarch Butterflies: A 4,500 km Journey with No GPS',
              domain: 'nature', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (nat03:KnowledgeNode {id: '11111111-0000-0000-0000-000000000003'})
SET nat03 += {title: 'Bioluminescence: Why the Deep Ocean Glows',
              domain: 'nature', age_group: 'all', difficulty: 2, curiosity_score: 9, is_published: true};
MERGE (nat04:KnowledgeNode {id: '11111111-0000-0000-0000-000000000004'})
SET nat04 += {title: 'The Wood Wide Web: How Trees Talk Through Fungi',
              domain: 'nature', age_group: 'all', difficulty: 3, curiosity_score: 10, is_published: true};
MERGE (nat05:KnowledgeNode {id: '11111111-0000-0000-0000-000000000005'})
SET nat05 += {title: 'Tardigrades: The Indestructible Animal',
              domain: 'nature', age_group: 'all', difficulty: 2, curiosity_score: 10, is_published: true};
MERGE (nat06:KnowledgeNode {id: '11111111-0000-0000-0000-000000000006'})
SET nat06 += {title: 'Pistol Shrimp: The Animal That Shoots Hotter Than the Sun',
              domain: 'nature', age_group: 'all', difficulty: 3, curiosity_score: 10, is_published: true};
MERGE (nat07:KnowledgeNode {id: '11111111-0000-0000-0000-000000000007'})
SET nat07 += {title: 'Elephants: Giants with Grief, Joy, and 60-Year Memories',
              domain: 'nature', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (nat08:KnowledgeNode {id: '11111111-0000-0000-0000-000000000008'})
SET nat08 += {title: 'Coral Bleaching: Why Reefs Turn White and Die',
              domain: 'nature', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (nat09:KnowledgeNode {id: '11111111-0000-0000-0000-000000000009'})
SET nat09 += {title: 'Birdsong: How Birds Learn Music Like Children Learn Language',
              domain: 'nature', age_group: 'all', difficulty: 2, curiosity_score: 7, is_published: true};
MERGE (nat10:KnowledgeNode {id: '11111111-0000-0000-0000-000000000010'})
SET nat10 += {title: 'The Nitrogen Cycle: The Invisible Process That Feeds the World',
              domain: 'nature', age_group: 'all', difficulty: 3, curiosity_score: 7, is_published: true};

// ── HISTORY (V6) — IDs: 55555555-0000-0000-0000-00000000000{1..7} ─────────────

MERGE (his01:KnowledgeNode {id: '55555555-0000-0000-0000-000000000001'})
SET his01 += {title: 'Marie Curie: The Scientist Who Died for Her Discoveries',
              domain: 'history', age_group: 'all', difficulty: 2, curiosity_score: 9, is_published: true};
MERGE (his02:KnowledgeNode {id: '55555555-0000-0000-0000-000000000002'})
SET his02 += {title: 'Ada Lovelace: The First Programmer — 100 Years Before Computers Existed',
              domain: 'history', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (his03:KnowledgeNode {id: '55555555-0000-0000-0000-000000000003'})
SET his03 += {title: 'Alan Turing: The Man Who Saved Millions and Was Destroyed by His Country',
              domain: 'history', age_group: 'all', difficulty: 3, curiosity_score: 10, is_published: true};
MERGE (his04:KnowledgeNode {id: '55555555-0000-0000-0000-000000000004'})
SET his04 += {title: 'Cleopatra: The Scholar-Queen History Turned Into a Symbol',
              domain: 'history', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (his05:KnowledgeNode {id: '55555555-0000-0000-0000-000000000005'})
SET his05 += {title: 'Nikola Tesla: The Architect of the Modern Electrical World',
              domain: 'history', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (his06:KnowledgeNode {id: '55555555-0000-0000-0000-000000000006'})
SET his06 += {title: 'Genghis Khan: The Conqueror Who Accidentally Globalized the World',
              domain: 'history', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (his07:KnowledgeNode {id: '55555555-0000-0000-0000-000000000007'})
SET his07 += {title: 'Leonardo da Vinci: The Man Whose Notebooks Were 500 Years Ahead',
              domain: 'history', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};

// ── TECHNOLOGY (V7) — IDs: 22222222-0000-0000-0000-00000000000{1..7} ──────────

MERGE (tec01:KnowledgeNode {id: '22222222-0000-0000-0000-000000000001'})
SET tec01 += {title: 'How GPS Actually Works: Satellites and the Speed of Light',
              domain: 'technology', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (tec02:KnowledgeNode {id: '22222222-0000-0000-0000-000000000002'})
SET tec02 += {title: 'How the Internet Actually Works: Packets, Routing, and TCP/IP',
              domain: 'technology', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (tec03:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'})
SET tec03 += {title: 'Encryption: How HTTPS Keeps Your Passwords Secret',
              domain: 'technology', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (tec04:KnowledgeNode {id: '22222222-0000-0000-0000-000000000004'})
SET tec04 += {title: 'How LLMs Work: Predicting the Next Word at Massive Scale',
              domain: 'technology', age_group: 'all', difficulty: 4, curiosity_score: 10, is_published: true};
MERGE (tec05:KnowledgeNode {id: '22222222-0000-0000-0000-000000000005'})
SET tec05 += {title: 'Moore''s Law: Why Computers Double in Power Every Two Years',
              domain: 'technology', age_group: 'all', difficulty: 3, curiosity_score: 8, is_published: true};
MERGE (tec06:KnowledgeNode {id: '22222222-0000-0000-0000-000000000006'})
SET tec06 += {title: 'The Algorithm Behind Your Feed: Recommendation Systems',
              domain: 'technology', age_group: 'all', difficulty: 2, curiosity_score: 9, is_published: true};
MERGE (tec07:KnowledgeNode {id: '22222222-0000-0000-0000-000000000007'})
SET tec07 += {title: 'CRISPR: How Scientists Learned to Edit the Code of Life',
              domain: 'technology', age_group: 'all', difficulty: 3, curiosity_score: 10, is_published: true};

// ── CREATIVE (V8) — IDs: 44444444-0000-0000-0000-00000000000{1..6} ───────────

MERGE (cre01:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'})
SET cre01 += {title: 'Jazz Improvisation: How Musicians Compose in Real Time',
              domain: 'creative', age_group: 'all', difficulty: 2, curiosity_score: 9, is_published: true};
MERGE (cre02:KnowledgeNode {id: '44444444-0000-0000-0000-000000000002'})
SET cre02 += {title: 'The Science of Color: Why Colors Don''t Exist Outside Your Brain',
              domain: 'creative', age_group: 'all', difficulty: 3, curiosity_score: 10, is_published: true};
MERGE (cre03:KnowledgeNode {id: '44444444-0000-0000-0000-000000000003'})
SET cre03 += {title: 'Shakespeare''s Language: How He Invented Words We Still Use Daily',
              domain: 'creative', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (cre04:KnowledgeNode {id: '44444444-0000-0000-0000-000000000004'})
SET cre04 += {title: 'Architecture of Cathedrals: Engineering Miracles Built Without Computers',
              domain: 'creative', age_group: 'all', difficulty: 3, curiosity_score: 9, is_published: true};
MERGE (cre05:KnowledgeNode {id: '44444444-0000-0000-0000-000000000005'})
SET cre05 += {title: 'The Psychology of Music: Why Minor Keys Make You Sad',
              domain: 'creative', age_group: 'all', difficulty: 2, curiosity_score: 8, is_published: true};
MERGE (cre06:KnowledgeNode {id: '44444444-0000-0000-0000-000000000006'})
SET cre06 += {title: 'The Golden Ratio: The Math That Appears in Art, Nature, and Architecture',
              domain: 'creative', age_group: 'all', difficulty: 3, curiosity_score: 8, is_published: true};


// =============================================================================
// V5–V8 RELATIONSHIPS
// =============================================================================

// ── BELONGS_TO Domain (bulk — covers all 30 new nodes) ───────────────────────
MATCH (n:KnowledgeNode), (d:Domain) WHERE n.domain = d.name MERGE (n)-[:BELONGS_TO]->(d);

// ── NATURE LEADS_TO chain ─────────────────────────────────────────────────────
// Photosynthesis → Wood Wide Web (both about how plants work)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000004'})
MERGE (a)-[:LEADS_TO {weight: 0.90, relation_vi: 'Thực vật còn làm được nhiều hơn thế'}]->(b);

// Wood Wide Web → Tardigrades (both: life is more resilient than you think)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000004'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000005'})
MERGE (a)-[:LEADS_TO {weight: 0.80, relation_vi: 'Sự sống phi thường khác'}]->(b);

// Bioluminescence → Pistol Shrimp (both: deep ocean physics surprises)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000003'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000006'})
MERGE (a)-[:LEADS_TO {weight: 0.85, relation_vi: 'Vũ khí vật lý khác của đại dương'}]->(b);

// Monarch butterflies → Elephant memory (both: animal intelligence surprises)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000007'})
MERGE (a)-[:LEADS_TO {weight: 0.75, relation_vi: 'Trí tuệ bẩm sinh của động vật'}]->(b);

// Coral Bleaching → Nitrogen Cycle (both: ecosystem-level processes)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000008'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000010'})
MERGE (a)-[:LEADS_TO {weight: 0.70, relation_vi: 'Chu trình vô hình khác của tự nhiên'}]->(b);

// Birdsong → Elephant memory (both: animal learning & culture)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000009'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000007'})
MERGE (a)-[:LEADS_TO {weight: 0.80, relation_vi: 'Trí nhớ và văn hóa động vật'}]->(b);

// ── HISTORY LEADS_TO chain ────────────────────────────────────────────────────
// Ada Lovelace → Alan Turing (direct historical lineage: computing)
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '55555555-0000-0000-0000-000000000003'})
MERGE (a)-[:LEADS_TO {weight: 0.95, relation_vi: 'Người kế thừa ý tưởng lập trình'}]->(b);

// Marie Curie → Nikola Tesla (both: genius vs. institutional resistance)
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '55555555-0000-0000-0000-000000000005'})
MERGE (a)-[:LEADS_TO {weight: 0.80, relation_vi: 'Thiên tài bị hệ thống cản trở'}]->(b);

// Cleopatra → Genghis Khan (both: power, strategy, and historical misrepresentation)
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000004'}),
      (b:KnowledgeNode {id: '55555555-0000-0000-0000-000000000006'})
MERGE (a)-[:LEADS_TO {weight: 0.75, relation_vi: 'Lịch sử viết bởi kẻ chiến thắng'}]->(b);

// Leonardo da Vinci → Ada Lovelace (both: imagined technology before it existed)
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000007'}),
      (b:KnowledgeNode {id: '55555555-0000-0000-0000-000000000002'})
MERGE (a)-[:LEADS_TO {weight: 0.85, relation_vi: 'Tầm nhìn vượt thời đại'}]->(b);

// ── TECHNOLOGY LEADS_TO chain ─────────────────────────────────────────────────
// Internet → Encryption (packets flow, encryption protects them)
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'})
MERGE (a)-[:LEADS_TO {weight: 0.90, relation_vi: 'Bảo mật lớp trên của mạng'}]->(b);

// GPS → Moore's Law (both: physics constraints on computation)
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000005'})
MERGE (a)-[:LEADS_TO {weight: 0.70, relation_vi: 'Giới hạn vật lý của công nghệ'}]->(b);

// LLMs → Recommendation Algorithms (both: ML optimizing for a metric)
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000004'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000006'})
MERGE (a)-[:LEADS_TO {weight: 0.85, relation_vi: 'AI tối ưu hóa cho mục tiêu'}]->(b);

// CRISPR → LLMs (both: emergent capabilities from scale/optimization)
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000007'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000004'})
MERGE (a)-[:LEADS_TO {weight: 0.75, relation_vi: 'Công nghệ thay đổi định nghĩa sự sống'}]->(b);

// ── CREATIVE LEADS_TO chain ───────────────────────────────────────────────────
// Color science → Golden Ratio (both: perception vs. reality in art)
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000006'})
MERGE (a)-[:LEADS_TO {weight: 0.85, relation_vi: 'Nhận thức trong nghệ thuật'}]->(b);

// Jazz → Psychology of Music (flow state → emotional response)
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000005'})
MERGE (a)-[:LEADS_TO {weight: 0.90, relation_vi: 'Tại sao âm nhạc tác động đến cảm xúc'}]->(b);

// Shakespeare → Cathedral architecture (both: human creativity without modern tools)
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000003'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000004'})
MERGE (a)-[:LEADS_TO {weight: 0.70, relation_vi: 'Sáng tạo thời trung cổ'}]->(b);

// ── CROSS_DOMAIN — liên kết liên ngành bất ngờ ───────────────────────────────
// Ada Lovelace (history) ↔ LLMs (technology): conceptual lineage of computing
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000004'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.95,
  concept: 'computing_origins',
  insight_vi: 'Ada tưởng tượng LLM 180 năm trước khi nó được tạo ra'}]->(b);

// Alan Turing (history) ↔ Encryption (technology): Turing's direct legacy
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000003'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.90,
  concept: 'cryptography',
  insight_vi: 'Turing phá mã Enigma — cha đẻ của mật mã học hiện đại'}]->(b);

// Nitrogen Cycle (nature) ↔ CRISPR (technology): both rewrite "the code of life"
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000010'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000007'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.85,
  concept: 'life_chemistry',
  insight_vi: 'Vi khuẩn cố định N₂ và vi khuẩn tạo CRISPR: đều là công cụ tự nhiên con người mượn'}]->(b);

// Golden Ratio (creative) ↔ Photosynthesis (nature): math in nature
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000006'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.80,
  concept: 'natural_pattern',
  insight_vi: 'Fibonacci trong hoa hướng dương và hiệu quả đóng gói — toán học và tự nhiên là một'}]->(b);

// Color science (creative) ↔ Bioluminescence (nature): light perception
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000003'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.88,
  concept: 'light_perception',
  insight_vi: 'Ánh sáng không có màu — từ đại dương sâu đến não người'}]->(b);

// Psychology of Music (creative) ↔ Birdsong (nature): cultural transmission
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000005'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000009'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.85,
  concept: 'cultural_sound',
  insight_vi: 'Chim và người đều học âm nhạc qua văn hóa, không phải bản năng thuần túy'}]->(b);

// Marie Curie (history) ↔ CRISPR (technology): science that changes everything at personal cost
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000007'})
MERGE (a)-[:CROSS_DOMAIN {surprise_factor: 0.78,
  concept: 'science_ethics',
  insight_vi: 'Khoa học thay đổi thế giới đôi khi phá hủy người tạo ra nó'}]->(b);

// ── DEEP_DIVE — cùng chủ đề, sâu hơn ────────────────────────────────────────
// Photosynthesis → Wood Wide Web (deeper: plants network, not just photosynthesize)
MATCH (a:KnowledgeNode {id: '11111111-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '11111111-0000-0000-0000-000000000004'})
MERGE (a)-[:DEEP_DIVE {depth_level: 1}]->(b);

// Internet → Encryption (deeper: what travels over those packets)
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000003'})
MERGE (a)-[:DEEP_DIVE {depth_level: 1}]->(b);

// Ada Lovelace → Alan Turing (deeper: from first program to first computer)
MATCH (a:KnowledgeNode {id: '55555555-0000-0000-0000-000000000002'}),
      (b:KnowledgeNode {id: '55555555-0000-0000-0000-000000000003'})
MERGE (a)-[:DEEP_DIVE {depth_level: 1}]->(b);

// Jazz → Psychology of Music (deeper: from performance to brain science)
MATCH (a:KnowledgeNode {id: '44444444-0000-0000-0000-000000000001'}),
      (b:KnowledgeNode {id: '44444444-0000-0000-0000-000000000005'})
MERGE (a)-[:DEEP_DIVE {depth_level: 1}]->(b);

// Moore's Law → LLMs (deeper: the hardware that made AI possible)
MATCH (a:KnowledgeNode {id: '22222222-0000-0000-0000-000000000005'}),
      (b:KnowledgeNode {id: '22222222-0000-0000-0000-000000000004'})
MERGE (a)-[:DEEP_DIVE {depth_level: 2}]->(b);
