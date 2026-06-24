"""
app/agents/graph_agent.py — Graph Agent（意图识别 + 工具调用 + 结果总结）

职责：
1. 接收用户问题
2. 调用 execute_sql 查询数据库
3. 调用 summarize_result 工具输出查询结果的自然语言总结
4. 返回总结作为 RAG context 给 Main Agent
"""

import json
import asyncio
from typing import Callable, Optional
from openai import AsyncOpenAI
from config import settings
from app.agents.tools.mysql_tool import execute_sql
from app.agents.tools.neo4j_tool import (
    is_neo4j_enabled,
    query_neo4j as neo4j_query_neo4j,
    get_graph_schema as neo4j_get_graph_schema,
    explore_graph_sample as neo4j_explore_graph_sample,
    count_nodes_by_label as neo4j_count_nodes_by_label,
    NEO4J_SCHEMA_INFO,
    NEO4J_USAGE_GUIDE,
)


MYSQL_QUERY_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "execute_sql",
            "description": "执行安全的 SQL SELECT 查询。只允许 SELECT，必须包含 LIMIT（最大100行）。适合单条文物详情、关键词 LIKE、统计聚合。",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "SQL 查询语句"
                    }
                },
                "required": ["query"]
            }
        }
    },
]


SUMMARY_TOOL = {
    "type": "function",
    "function": {
        "name": "summarize_result",
        "description": "将工具查询结果（MySQL 或 Neo4j）转换为自然语言总结，作为 RAG context 返回。所有数据查询完成后调用一次以结束检索。",
        "parameters": {
            "type": "object",
            "properties": {
                "summary": {
                    "type": "string",
                    "description": "查询结果的自然语言总结"
                }
            },
            "required": ["summary"]
        }
    },
}


# 向后兼容：保留旧名字 MYSQL_TOOLS，包含 execute_sql + summarize_result
MYSQL_TOOLS = MYSQL_QUERY_TOOLS + [SUMMARY_TOOL]


NEO4J_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "query_neo4j",
            "description": "【首选图数据库检索】执行 Cypher，从文物知识图谱中检索数据。"
                            "适用：多维关系查询（作者↔文物↔朝代↔材质↔类型）、多跳推理、跨馆实体对齐、字段溯源。"
                            "关系名是驼峰（belongsToMuseum / hasPrimaryMaterial 等）；节点定位用 uri 字段；必须含 LIMIT；只读。",
            "parameters": {
                "type": "object",
                "properties": {
                    "cypher": {
                        "type": "string",
                        "description": "Cypher 查询语句，必须包含 LIMIT 子句"
                    },
                    "params": {
                        "type": "string",
                        "description": "可选，JSON 字符串的查询参数"
                    }
                },
                "required": ["cypher"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_graph_schema",
            "description": "【必读】获取知识图谱的完整 Schema（11 类节点、8 条核心关系 + 2 条对齐、27 类字面量属性、URI 约定）和使用指南。"
                            "首次接触图谱或不确定 Schema 时必须先调用此工具。",
            "parameters": {
                "type": "object",
                "properties": {},
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "explore_graph_sample",
            "description": "【数据探查】查看某节点标签的 3 条样本数据，了解字段格式与值。",
            "parameters": {
                "type": "object",
                "properties": {
                    "node_label": {
                        "type": "string",
                        "description": "节点标签：Artifact / Museum / Dynasty / Artist / Material / ArtifactType / Location / Culture / EntityMaster / EntityAlias / EntitySource"
                    }
                },
                "required": ["node_label"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "count_nodes_by_label",
            "description": "【统计】统计某节点标签的总数，用于快速了解图谱规模。",
            "parameters": {
                "type": "object",
                "properties": {
                    "node_label": {
                        "type": "string",
                        "description": "节点标签（可选同 explore_graph_sample）"
                    }
                },
                "required": ["node_label"]
            }
        }
    },
]


NEO4J_TOOL_NAMES = {t["function"]["name"] for t in NEO4J_TOOLS}


def get_available_tools() -> list:
    """
    根据 settings.ENABLE_MYSQL / ENABLE_NEO4J 返回当前可用的工具列表。
    任意一个数据库开启时，summarize_result 也会被加入（用于结束检索）。
    """
    tools = []
    if settings.ENABLE_MYSQL:
        tools.extend(MYSQL_QUERY_TOOLS)
    if is_neo4j_enabled():
        tools.extend(NEO4J_TOOLS)
    if tools:
        tools.append(SUMMARY_TOOL)
    return tools


async def _invoke_neo4j_tool(name: str, args: dict) -> str:
    """统一调用 neo4j_tool.py 里 @tool 包装的异步函数。"""
    tool_map = {
        "query_neo4j": neo4j_query_neo4j,
        "get_graph_schema": neo4j_get_graph_schema,
        "explore_graph_sample": neo4j_explore_graph_sample,
        "count_nodes_by_label": neo4j_count_nodes_by_label,
    }
    tool = tool_map.get(name)
    if tool is None:
        return json.dumps({"error": f"未注册的 Neo4j 工具: {name}"}, ensure_ascii=False)
    try:
        return await tool.ainvoke(args or {})
    except Exception as e:
        return json.dumps({"error": f"Neo4j 工具 {name} 执行失败: {str(e)}"}, ensure_ascii=False)


def create_graph_agent(use_streaming: bool = False):
    """
    工厂函数（设计文档预留 API，兼容 qa_engine / main_qa_agent 的引用）。
    实际运行时通过 run_graph_agent 入口执行；这里仅在 langchain.agents.create_agent 可用时返回 agent。
    """
    try:
        from langchain.agents import create_agent as _lc_create_agent
    except ImportError:
        return None
    try:
        from app.retrieval.llm_generator import create_llm
    except ImportError:
        return None

    llm = create_llm(temperature=0)
    return _lc_create_agent(
        model=llm,
        tools=get_available_tools(),
        system_prompt=SYSTEM_PROMPT,
    )


SYSTEM_PROMPT = """你是一个专门负责海外藏中国文物知识问答的"查询 Agent"。

你拥有两类数据库工具可以调用：
1. **MySQL 工具**（结构化检索）：`execute_sql`
2. **Neo4j 工具**（图谱检索）：`query_neo4j` / `get_graph_schema` / `explore_graph_sample` / `count_nodes_by_label`

## ⭐ 工具选择策略（简单问题优先 MySQL，关系问题才用 Neo4j）

| 问题场景 | 推荐工具 |
|----------|----------|
| 单条文物详情、收藏地/年代/材质/作者/尺寸、关键词 LIKE、简单统计 | ✅ **MySQL: `execute_sql`（优先，通常 1 次即可）** |
| 字段过滤聚合（GROUP BY） | MySQL: `execute_sql` |
| **作者 ↔ 文物 ↔ 朝代** 多维关系、多跳推理 | Neo4j: `query_neo4j` |
| 跨馆同作者/同朝代归并 | Neo4j: `query_neo4j` |

> **效率法则：简单问题 → 只用 `execute_sql` + `summarize_result`（2 轮结束）；不要调用 `get_graph_schema` / `explore_graph_sample`。**
> **只有明确的多跳/关系问题才用 Neo4j，且尽量一次 Cypher 查全。**

## 多轮对话
- 用户可能追问「它」「这件」「上面那个」「刚才说的」等，**必须先结合对话历史**把指代解析成具体的文物名、object_id 或博物馆，再构造 SQL/Cypher。
- 若当前问题本身不完整，应从上文最近一次讨论的文物/主题出发查询，不要当作全新独立问题。

## Neo4j 关键提示
- 关系名是**驼峰**：`belongsToMuseum` / `hasPrimaryMaterial` / `createdBy` / `hasType` / `hasCulture` / `usesMaterial` / `hasPrimaryMaterial` / `locatedIn` / `belongsToDynasty` —— 不是 `COLLECTED_BY` / `CREATED_BY` 这种全大写
- 节点定位优先用 `uri` 字段：`MATCH (a:Artifact {uri: 'entity:artifact:1:abc'})`
- 朝代 `name` 字段带括号 `Tang（唐）`；模糊匹配用 `CONTAINS 'Tang'`
- 8 条核心关系：`belongsToMuseum` / `belongsToDynasty` / `createdBy` / `usesMaterial` / `hasPrimaryMaterial` / `hasType` / `hasCulture` / `locatedIn`
- 11 类节点：`Artifact` / `Museum` / `Dynasty` / `Artist` / `Material` / `ArtifactType` / `Location` / `Culture` + `EntityMaster` / `EntityAlias` / `EntitySource`
- Cypher 必须含 `LIMIT`；只读，禁止 `MERGE / CREATE / DELETE / SET / CALL`
- **查询 Artifact 时 RETURN 必须包含 `a.uri`, `a.object_id`, `a.name AS title`**

## MySQL 关键提示
- `overseas_chinese_artifacts.artifact` 表（6875+ 条记录）
- 字段：`object_id, title, artist, dynasty, type, museum, location, detail_url, image_url, material, dimensions, description, period, accession_number, credit_line, ...`
- **溯源**：查询具体文物时 SELECT 必须含 `detail_url`；纯统计/聚合可在同轮再查 1 条带 `detail_url` 的样例
- 必须以 SELECT 开头，必须含 LIMIT（最大 100 行）
- 支持模糊匹配：WHERE column LIKE '%关键词%'
- 支持聚合：COUNT, GROUP BY, ORDER BY

## 工作流程（追求最少轮次）
1. 收到用户问题：单条详情/属性/列举 → **直接 `execute_sql`**；多跳/关系 → **`query_neo4j`**
2. **禁止**为简单问题调用 `get_graph_schema` / `explore_graph_sample`（浪费一轮 LLM）
3. 拿到数据后**立即**调用 `summarize_result` 结束，不要重复查同类数据

## 分布 / 统计类问题（如「唐代瓷器在海外如何分布」）
- **一条 SQL 搞定**：`WHERE dynasty LIKE '%Tang%' AND (type LIKE '%Ceramic%' OR type LIKE '%瓷%')`，再 `GROUP BY museum, location` 或 `SELECT museum, location, COUNT(*) ...`
- 朝代字段用 `Tang` / `唐` 模糊匹配，不要查 schema
- 结果出来后**立刻** `summarize_result`，禁止第二轮同类统计 SQL

## 输出要求
调用 `summarize_result` 工具输出查询结果的自然语言总结，例如：
"从 Neo4j 图谱中查询到 Tang（唐）代瓷器在 Harvard Art Museums 共有 12 件，包括 ..."

**专有名词须保留英文原文**：title、artist、museum、dynasty 等字段在库中多为英文或「英文（中文）」格式，总结时不得把英文名全部改成纯中文；应保留英文名称，必要时可在括号内补充中文。

`summarize_result` 的输出会作为 RAG context 传给 Main Agent。**所有数据查询完成后必须调用一次 summarize_result 才能结束。**
"""


def _fallback_rag_context_from_snapshots(
    query_snapshots: list[tuple[str, str, Optional[int], Optional[str]]],
) -> str:
    """Graph Agent 未调用 summarize_result 时，用最后一次查询结果兜底。"""
    from app.core.source_extractor import _unpack_snapshot, _records_from_tool_output

    for item in reversed(query_snapshots):
        tool, content, _, _ = _unpack_snapshot(item)
        if tool not in {"execute_sql", "query_neo4j"} or not content:
            continue
        records = _records_from_tool_output(content)
        if not records:
            continue
        preview = json.dumps(records[:15], ensure_ascii=False, default=str)
        if len(preview) > 4000:
            preview = preview[:4000] + "…"
        return (
            f"数据库查询结果（共 {len(records)} 条，"
            f"展示前 {min(len(records), 15)} 条）：\n{preview}"
        )
    return ""


async def run_graph_agent(
    question: str,
    session_id: str = "",
    chat_history: Optional[list] = None,
    on_thinking: Optional[Callable[[str], None]] = None,
    on_tool_call: Optional[Callable[[str, str], None]] = None,
    on_tool_result: Optional[Callable[[str, str], None]] = None,
    stop_event: Optional[asyncio.Event] = None,
) -> dict:
    import logging
    from app.core.query_memory import get_query_memory
    from app.core.chat_history import prepare_chat_history, format_history_block

    logging.info(f"[GraphAgent] Processing: {question[:50]}...")
    logging.info(f"[GraphAgent] === Starting Graph Agent ===")
    logging.info(f"[GraphAgent] Session: {session_id[:8] if session_id else 'none'}...")

    if stop_event is None:
        stop_event = asyncio.Event()

    client = AsyncOpenAI(
        api_key=settings.LLM_API_KEY,
        base_url=settings.LLM_BASE_URL,
        timeout=settings.LLM_TIMEOUT,
    )

    logging.info(f"[GraphAgent] Model: {settings.LLM_MODEL_NAME}")

    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
    ]

    if session_id:
        query_memory = get_query_memory()
        query_context = query_memory.get_full_context(session_id, max_records=10)
        if query_context:
            messages[0]["content"] += f"\n\n{query_context}"
            logging.info(
                f"[GraphAgent] Added query context to system prompt, total length: {len(messages[0]['content'])}"
            )

    prepared_history = prepare_chat_history(chat_history, question)
    history_block = format_history_block(prepared_history)
    if history_block:
        messages[0]["content"] += (
            "\n\n## 对话历史（理解指代词时请结合上文）\n"
            + history_block
            + "\n\n当前用户问题可能省略主语，请结合历史理解后再查询。"
        )
        logging.info(
            f"[GraphAgent] Injected {len(prepared_history)} history message(s), "
            f"block length: {len(history_block)}"
        )

    messages.append({"role": "user", "content": question})
    logging.info(f"[GraphAgent] Messages prepared, total: {len(messages)}")

    max_turns = settings.GRAPH_AGENT_MAX_TURNS
    rag_context = ""
    query_snapshots: list[tuple[str, str, Optional[int], Optional[str]]] = []

    for turn in range(max_turns):
        logging.info(f"[GraphAgent] --- Turn {turn + 1}/{max_turns} ---")
        if stop_event.is_set():
            logging.info("[GraphAgent] Stopped")
            break

        try:
            logging.info(f"[GraphAgent] Calling LLM...")
            stream = await client.chat.completions.create(
                model=settings.LLM_MODEL_NAME,
                messages=messages,
                tools=get_available_tools(),
                stream=True,
                temperature=0,
            )
        except Exception as e:
            logging.error(
                "[GraphAgent] LLM call failed: %s | base_url=%s model=%s key_set=%s",
                e,
                settings.LLM_BASE_URL,
                settings.LLM_MODEL_NAME,
                bool(settings.LLM_API_KEY),
            )
            return {
                "rag_context": "",
                "kg_facts": "",
                "has_kg_facts": False,
                "intent_label": "ERROR",
                "sources": [],
            }

        tool_calls = []
        current_tc = None
        finish_reason = None

        try:
            async for chunk in stream:
                if stop_event.is_set():
                    break
                if not chunk.choices:
                    continue

                delta = chunk.choices[0].delta
                finish_reason = chunk.choices[0].finish_reason

                if delta is None:
                    continue

                if delta.tool_calls:
                    for tc in delta.tool_calls:
                        if tc.function and tc.function.name:
                            logging.info(f"[GraphAgent] LLM requests tool: {tc.function.name}")
                            current_tc = {
                                "id": tc.id or f"call_{len(tool_calls)}",
                                "name": tc.function.name,
                                "arguments": ""
                            }
                            tool_calls.append(current_tc)
                        elif current_tc and tc.function and tc.function.arguments:
                            current_tc["arguments"] += tc.function.arguments
        except Exception as e:
            logging.error(f"[GraphAgent] Stream failed: {e}")
            break

        logging.info(f"[GraphAgent] finish_reason: {finish_reason}, tool_calls: {len(tool_calls)}")

        if finish_reason == "stop":
            break

        if tool_calls:
            logging.info(f"[GraphAgent] Processing {len(tool_calls)} tool calls")

            assistant_msg = {
                "role": "assistant",
                "content": "",
                "tool_calls": [
                    {
                        "id": tc["id"],
                        "type": "function",
                        "function": {"name": tc["name"], "arguments": tc["arguments"]}
                    }
                    for tc in tool_calls
                ]
            }
            messages.append(assistant_msg)

            for tc in tool_calls:
                args = {}
                try:
                    if tc["arguments"]:
                        args = json.loads(tc["arguments"])
                except:
                    pass

                logging.info(f"[GraphAgent] Executing tool: {tc['name']}")

                if on_tool_call:
                    await on_tool_call(tc["name"], json.dumps(args))

                if tc["name"] == "execute_sql":
                    query = args.get("query", "")
                    logging.info(f"[GraphAgent] execute_sql called with query: {query}")
                    result = await execute_sql(query)
                    logging.info(f"[GraphAgent] execute_sql result: {len(result)} chars")

                    if session_id:
                        from app.core.query_memory import get_query_memory
                        query_memory = get_query_memory()
                        try:
                            result_data = json.loads(result)
                            result_count = len(result_data) if isinstance(result_data, list) else 0
                        except Exception:
                            result_count = 0
                        query_memory.add_record(
                            session_id, "execute_sql", query, result, result_count
                        )
                        logging.info("[GraphAgent] Recorded execute_sql to query memory")

                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc["id"],
                        "content": result
                    })
                    query_snapshots.append(("execute_sql", result, None, query))
                    if on_tool_result:
                        await on_tool_result(tc["name"], result)

                elif tc["name"] in NEO4J_TOOL_NAMES:
                    cypher = args.get("cypher", "")
                    extra = {k: v for k, v in args.items() if k != "cypher"}
                    logging.info(
                        f"[GraphAgent] {tc['name']} called: "
                        f"args={str(extra)[:120]} "
                        f"cypher={cypher[:80] if tc['name'] == 'query_neo4j' else ''}"
                    )
                    result = await _invoke_neo4j_tool(tc["name"], args)
                    logging.info(f"[GraphAgent] {tc['name']} result: {len(result)} chars")
                    from app.core.source_extractor import _museum_id_from_text
                    museum_hint = _museum_id_from_text(cypher) or _museum_id_from_text(
                        json.dumps(args, ensure_ascii=False)
                    )

                    if session_id:
                        from app.core.query_memory import get_query_memory
                        query_memory = get_query_memory()
                        try:
                            result_data = json.loads(result)
                            if isinstance(result_data, list):
                                result_count = len(result_data)
                            elif isinstance(result_data, dict) and "count" in result_data:
                                result_count = int(result_data.get("count") or 0)
                            elif isinstance(result_data, dict) and "error" not in result_data:
                                result_count = len(result_data)
                            else:
                                result_count = 0
                        except Exception:
                            result_count = 0

                        query_or_desc = cypher if tc["name"] == "query_neo4j" else json.dumps(args, ensure_ascii=False)
                        query_memory.add_record(
                            session_id, tc["name"], query_or_desc, result, result_count
                        )
                        logging.info(f"[GraphAgent] Recorded {tc['name']} to query memory")

                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc["id"],
                        "content": result
                    })
                    if tc["name"] == "query_neo4j":
                        query_snapshots.append(("query_neo4j", result, museum_hint, cypher))
                    if on_tool_result:
                        await on_tool_result(tc["name"], result)

                elif tc["name"] == "summarize_result":
                    summary = args.get("summary", "")
                    rag_context = summary
                    logging.info(f"[GraphAgent] summarize_result: {summary[:100]}...")
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc["id"],
                        "content": summary
                    })
                    if on_tool_result:
                        await on_tool_result(tc["name"], summary)
                else:
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc["id"],
                        "content": f"Unknown tool: {tc['name']}"
                    })
        else:
            logging.info("[GraphAgent] No tool calls, finishing")
            break

    if not rag_context.strip() and query_snapshots:
        rag_context = _fallback_rag_context_from_snapshots(query_snapshots)
        if rag_context:
            logging.info("[GraphAgent] Using fallback rag_context from tool outputs")

    logging.info(f"[GraphAgent] === Finished ===")
    logging.info(f"[GraphAgent] rag_context: {len(rag_context)} chars")

    from app.core.source_extractor import extract_sources_with_mysql
    from app.core.kg_facts_formatter import format_kg_facts_from_snapshots

    try:
        sources = await extract_sources_with_mysql(query_snapshots=query_snapshots, messages=messages)
    except Exception as src_err:
        import logging
        logging.error("[GraphAgent] extract_sources failed: %s", src_err, exc_info=True)
        sources = []
    try:
        kg_facts, has_kg_facts = format_kg_facts_from_snapshots(query_snapshots)
    except Exception as kg_err:
        import logging
        logging.warning("[GraphAgent] format_kg_facts failed (sources kept): %s", kg_err)
        kg_facts, has_kg_facts = "", bool(sources)
    logging.info(
        f"[GraphAgent] extracted {len(sources)} source(s), kg_facts={len(kg_facts)} chars"
    )

    return {
        "rag_context": rag_context,
        "kg_facts": kg_facts,
        "has_kg_facts": has_kg_facts,
        "intent_label": "ARTIFACT_QUERY",
        "sources": sources,
    }