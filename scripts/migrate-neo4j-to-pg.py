#!/usr/bin/env python3
"""
migrate-neo4j-to-pg.py
======================
Migrate knowledge graph data from Neo4j → PostgreSQL (node_relations table).

Steps:
  1. Export KnowledgeNode properties (content fields) from Neo4j → upsert into knowledge_nodes
  2. Export LEADS_TO / DEEP_DIVE / CROSS_DOMAIN relationships → insert into node_relations

Usage:
  pip install neo4j psycopg2-binary
  python scripts/migrate-neo4j-to-pg.py [--dry-run] [--export-only] [--csv-dir ./export]

Environment variables (or .env file):
  NEO4J_URI         bolt://localhost:7687
  NEO4J_USER        neo4j
  NEO4J_PASSWORD    your_password
  DATABASE_URL      postgres://user:pass@localhost:5432/ai_wisdom_battle

NOTE — PostgreSQL on Lightsail is NOT exposed externally.
Open an SSH tunnel before running import:
  ssh -i ~/.ssh/awb-lightsail -L 5433:localhost:5432 -N ubuntu@<IPv6> &
  DATABASE_URL=postgres://postgres:<pw>@localhost:5433/ai_wisdom_battle
"""

import argparse
import csv
import os
import sys
from pathlib import Path

# ── Optional: load .env ───────────────────────────────────────────────────────
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv optional


def get_env(key: str, default: str = "") -> str:
    return os.environ.get(key, default)


# ── Config ────────────────────────────────────────────────────────────────────
NEO4J_URI      = get_env("NEO4J_URI",      "bolt://localhost:7687")
NEO4J_USER     = get_env("NEO4J_USER",     "neo4j")
NEO4J_PASSWORD = get_env("NEO4J_PASSWORD", "")
DATABASE_URL   = get_env("DATABASE_URL",   "")


# =============================================================================
# Step 1: Export from Neo4j
# =============================================================================

def export_nodes(driver, csv_dir: Path) -> int:
    """Export KnowledgeNode properties to CSV."""
    outfile = csv_dir / "knowledge_nodes.csv"
    fieldnames = [
        "id", "title", "domain", "age_group", "difficulty", "curiosity_score",
        "is_published", "hook", "guess_prompt", "journey_steps",
        "reveal_text", "teach_back_prompt", "payoff_insight",
    ]
    query = """
        MATCH (n:KnowledgeNode)
        WHERE n.is_published IS NOT NULL
        RETURN
            n.id              AS id,
            n.title           AS title,
            n.domain          AS domain,
            COALESCE(n.ageGroup, n.age_group, 'all') AS age_group,
            COALESCE(n.difficulty, 2)                AS difficulty,
            COALESCE(n.curiosityScore, n.curiosity_score, 5) AS curiosity_score,
            COALESCE(n.isPublished, n.is_published, false)   AS is_published,
            COALESCE(n.hook, '')             AS hook,
            COALESCE(n.guessPrompt, n.guess_prompt, '')      AS guess_prompt,
            COALESCE(n.journeySteps, n.journey_steps, '[]')  AS journey_steps,
            COALESCE(n.revealText, n.reveal_text, '')        AS reveal_text,
            COALESCE(n.teachBackPrompt, n.teach_back_prompt, '') AS teach_back_prompt,
            COALESCE(n.payoffInsight, n.payoff_insight, '')  AS payoff_insight
        ORDER BY n.id
    """
    count = 0
    with open(outfile, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        with driver.session() as session:
            result = session.run(query)
            for record in result:
                writer.writerow(dict(record))
                count += 1
    print(f"  Exported {count} knowledge nodes → {outfile}")
    return count


def export_relations(driver, csv_dir: Path) -> int:
    """Export LEADS_TO, DEEP_DIVE, CROSS_DOMAIN relationships to CSV."""
    outfile = csv_dir / "node_relations.csv"
    fieldnames = [
        "from_node_id", "to_node_id", "relation_type",
        "weight", "relation_vi", "concept", "insight_vi",
    ]
    query = """
        MATCH (a:KnowledgeNode)-[r:LEADS_TO|DEEP_DIVE|CROSS_DOMAIN]->(b:KnowledgeNode)
        WHERE a.is_published IS NOT NULL AND b.is_published IS NOT NULL
        RETURN
            a.id                                  AS from_node_id,
            b.id                                  AS to_node_id,
            type(r)                               AS relation_type,
            COALESCE(r.weight, 1.0)               AS weight,
            COALESCE(r.relationVi, r.relation_vi, '') AS relation_vi,
            COALESCE(r.concept, '')               AS concept,
            COALESCE(r.insightVi, r.insight_vi, '') AS insight_vi
        ORDER BY from_node_id, relation_type, to_node_id
    """
    count = 0
    with open(outfile, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        with driver.session() as session:
            result = session.run(query)
            for record in result:
                writer.writerow(dict(record))
                count += 1
    print(f"  Exported {count} relationships → {outfile}")
    return count


# =============================================================================
# Step 2: Import into PostgreSQL
# =============================================================================

def import_nodes(conn, csv_dir: Path) -> tuple[int, int]:
    """Upsert knowledge_nodes from CSV. Returns (inserted, updated)."""
    infile = csv_dir / "knowledge_nodes.csv"
    if not infile.exists():
        print(f"  SKIP: {infile} not found")
        return 0, 0

    sql = """
        INSERT INTO knowledge_nodes (
            id, title, domain, age_group, difficulty, curiosity_score, is_published,
            hook, guess_prompt, journey_steps, reveal_text, teach_back_prompt, payoff_insight
        ) VALUES (
            %(id)s, %(title)s, %(domain)s, %(age_group)s, %(difficulty)s,
            %(curiosity_score)s, %(is_published)s,
            %(hook)s, %(guess_prompt)s, %(journey_steps)s::jsonb,
            %(reveal_text)s, %(teach_back_prompt)s, %(payoff_insight)s
        )
        ON CONFLICT (id) DO UPDATE SET
            title             = EXCLUDED.title,
            domain            = EXCLUDED.domain,
            age_group         = EXCLUDED.age_group,
            difficulty        = EXCLUDED.difficulty,
            curiosity_score   = EXCLUDED.curiosity_score,
            is_published      = EXCLUDED.is_published,
            hook              = EXCLUDED.hook,
            guess_prompt      = EXCLUDED.guess_prompt,
            journey_steps     = EXCLUDED.journey_steps,
            reveal_text       = EXCLUDED.reveal_text,
            teach_back_prompt = EXCLUDED.teach_back_prompt,
            payoff_insight    = EXCLUDED.payoff_insight,
            updated_at        = NOW()
    """
    inserted = updated = 0
    with open(infile, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        cur = conn.cursor()
        for row in reader:
            row["is_published"] = row["is_published"].lower() in ("true", "1", "yes")
            row["difficulty"]   = int(row["difficulty"] or 2)
            row["curiosity_score"] = int(row["curiosity_score"] or 5)
            # Normalize journey_steps to valid JSON
            js = row.get("journey_steps", "[]") or "[]"
            if not js.startswith("[") and not js.startswith("{"):
                js = "[]"
            row["journey_steps"] = js

            cur.execute("SELECT id FROM knowledge_nodes WHERE id = %s", (row["id"],))
            exists = cur.fetchone()
            cur.execute(sql, row)
            if exists:
                updated += 1
            else:
                inserted += 1

        conn.commit()
        cur.close()
    print(f"  knowledge_nodes: {inserted} inserted, {updated} updated")
    return inserted, updated


def import_relations(conn, csv_dir: Path) -> tuple[int, int]:
    """Insert node_relations from CSV. Returns (inserted, skipped)."""
    infile = csv_dir / "node_relations.csv"
    if not infile.exists():
        print(f"  SKIP: {infile} not found")
        return 0, 0

    sql = """
        INSERT INTO node_relations (
            from_node_id, to_node_id, relation_type, weight,
            relation_vi, concept, insight_vi
        ) VALUES (
            %(from_node_id)s, %(to_node_id)s, %(relation_type)s, %(weight)s,
            %(relation_vi)s, %(concept)s, %(insight_vi)s
        )
        ON CONFLICT (from_node_id, to_node_id, relation_type) DO UPDATE SET
            weight      = EXCLUDED.weight,
            relation_vi = EXCLUDED.relation_vi,
            concept     = EXCLUDED.concept,
            insight_vi  = EXCLUDED.insight_vi
    """
    inserted = skipped = 0
    with open(infile, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        cur = conn.cursor()
        for row in reader:
            row["weight"] = float(row.get("weight") or 1.0)
            # Validate relation_type
            valid = {"LEADS_TO", "DEEP_DIVE", "CROSS_DOMAIN"}
            if row["relation_type"] not in valid:
                skipped += 1
                continue
            # Verify both nodes exist in PostgreSQL
            cur.execute(
                "SELECT 1 FROM knowledge_nodes WHERE id = %s",
                (row["from_node_id"],)
            )
            if not cur.fetchone():
                skipped += 1
                continue
            cur.execute(
                "SELECT 1 FROM knowledge_nodes WHERE id = %s",
                (row["to_node_id"],)
            )
            if not cur.fetchone():
                skipped += 1
                continue

            cur.execute(sql, row)
            inserted += 1

        conn.commit()
        cur.close()
    print(f"  node_relations: {inserted} inserted, {skipped} skipped")
    return inserted, skipped


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(description="Migrate Neo4j → PostgreSQL")
    parser.add_argument("--dry-run",     action="store_true", help="Export only, do not import")
    parser.add_argument("--export-only", action="store_true", help="Same as --dry-run")
    parser.add_argument("--import-only", action="store_true", help="Skip Neo4j export, import from existing CSV")
    parser.add_argument("--csv-dir",     default="./migration-export", help="Directory for CSV files (default: ./migration-export)")
    args = parser.parse_args()

    csv_dir = Path(args.csv_dir)
    csv_dir.mkdir(parents=True, exist_ok=True)

    dry_run = args.dry_run or args.export_only

    # ── Neo4j export ──────────────────────────────────────────────────────────
    if not args.import_only:
        if not NEO4J_PASSWORD:
            print("ERROR: NEO4J_PASSWORD not set", file=sys.stderr)
            sys.exit(1)

        try:
            from neo4j import GraphDatabase  # type: ignore
        except ImportError:
            print("ERROR: pip install neo4j", file=sys.stderr)
            sys.exit(1)

        print(f"\n[1/2] Exporting from Neo4j ({NEO4J_URI})...")
        driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
        try:
            driver.verify_connectivity()
            export_nodes(driver, csv_dir)
            export_relations(driver, csv_dir)
        finally:
            driver.close()
        print("  Export done →", csv_dir)

    if dry_run:
        print("\n--dry-run: skipping PostgreSQL import")
        print("Review CSV files in:", csv_dir)
        return

    # ── PostgreSQL import ─────────────────────────────────────────────────────
    if not DATABASE_URL:
        print("ERROR: DATABASE_URL not set", file=sys.stderr)
        sys.exit(1)

    try:
        import psycopg2  # type: ignore
    except ImportError:
        print("ERROR: pip install psycopg2-binary", file=sys.stderr)
        sys.exit(1)

    print(f"\n[2/2] Importing into PostgreSQL...")
    conn = psycopg2.connect(DATABASE_URL)
    try:
        import_nodes(conn, csv_dir)
        import_relations(conn, csv_dir)
    finally:
        conn.close()

    print("\nMigration complete!")
    print(f"CSV files kept in: {csv_dir}")


if __name__ == "__main__":
    main()
