-- V4: Thêm các cột nội dung session 6 giai đoạn vào knowledge_nodes
-- Mỗi KnowledgeNode giờ lưu đủ nội dung cho toàn bộ session:
--   ① hook (đã có)       — câu mở đầu gây tò mò
--   ② guess_prompt       — câu hỏi để người dùng đoán trước khi xem
--   ③ journey_steps      — mảng 3–4 insights (JSONB: [{step, text}])
--   ④ reveal_text        — so sánh dự đoán với câu trả lời thật
--   ⑤ teach_back_prompt  — prompt Feynman Technique (giải thích lại cho nhân vật ảo)
--   ⑥ payoff_insight     — insight "wow" kết thúc session, mở ra gợi ý tiếp theo

ALTER TABLE knowledge_nodes
    ADD COLUMN guess_prompt      TEXT,
    ADD COLUMN journey_steps     JSONB,
    ADD COLUMN reveal_text       TEXT,
    ADD COLUMN teach_back_prompt TEXT,
    ADD COLUMN payoff_insight    TEXT;
