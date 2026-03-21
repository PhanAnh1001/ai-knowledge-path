// =============================================================================
// AI Wisdom Battle — Neo4j Knowledge Graph Schema
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
