"""
app/agents/main_agent.py — Main QA Agent（主问答 Agent）

职责：
1. 接收用户问题
2. 调用 Graph Agent 获取 RAG context
3. 将 RAG context 和问题一起发送给 LLM 生成最终回答
4. 流式输出给前端
5. 支持前端停止信号
"""

import json
import asyncio
from typing import Callable, Optional, Any
from openai import AsyncOpenAI
from config import settings
from app.agents.graph_agent import run_graph_agent


# 工具名 → 友好显示名（前端再加 SVG icon）。不使用 emoji。
TOOL_DISPLAY_NAMES = {
    "execute_sql":           "MySQL 数据库",
    "query_neo4j":           "Neo4j 知识图谱",
    "get_graph_schema":      "知识图谱结构",
    "explore_graph_sample":  "图谱节点样本",
    "count_nodes_by_label":  "图谱节点统计",
    "summarize_result":      "结果整理",
}


def _tool_display_name(tool_name: str) -> str:
    return TOOL_DISPLAY_NAMES.get(tool_name, tool_name)


async def run_main_agent(
    question: str,
    history: list,
    token_callback: Callable[[str], None],
    done_callback: Callable[[Any], None],
    session_id: str = "",
    agent_step_callback: Optional[Callable[..., None]] = None,
    stop_event: Optional[asyncio.Event] = None,
) -> None:
    import logging
    from app.core.chat_history import (
        prepare_chat_history,
        build_openai_history_messages,
    )

    logging.info(f"[MainAgent] Processing: {question[:50]}...")
    logging.info(f"[MainAgent] === Starting Main Agent ===")
    logging.info(f"[MainAgent] Session: {session_id[:8] if session_id else 'none'}...")

    prepared_history = prepare_chat_history(history, question)
    if prepared_history:
        logging.info(f"[MainAgent] Chat history: {len(prepared_history)} prior message(s)")

    if stop_event is None:
        stop_event = asyncio.Event()

    async def emit_step(step_type: str, content: str, tool_name: str = ""):
        """统一发送 agent_step，回调签名兼容 (step_type, content) 与 (step_type, content, tool_name=...) 两种。"""
        if not agent_step_callback:
            return
        try:
            await agent_step_callback(step_type, content, tool_name=tool_name)
        except TypeError:
            await agent_step_callback(step_type, content)

    async def on_tool_call(tool_name: str, tool_args: str):
        logging.info(f"[MainAgent] Tool called: {tool_name}")
        if agent_step_callback:
            display = _tool_display_name(tool_name)
            await emit_step("tool_call", f"正在查询 {display}", tool_name=tool_name)

    async def on_tool_result(tool_name: str, result: str):
        logging.info(f"[MainAgent] Tool result: {tool_name}, result_len: {len(result)}")
        if agent_step_callback:
            display = _tool_display_name(tool_name)
            if "error" in result:
                await emit_step("tool_result", f"{display} 执行失败", tool_name=tool_name)
            else:
                try:
                    import json as json_mod
                    data = json_mod.loads(result)
                    if isinstance(data, list):
                        logging.info(f"[MainAgent] Tool returned {len(data)} items")
                        await emit_step("tool_result", f"{display} 返回 {len(data)} 条结果", tool_name=tool_name)
                    elif isinstance(data, dict) and "count" in data and "error" not in data:
                        await emit_step("tool_result", f"{display} = {data.get('count')}", tool_name=tool_name)
                    else:
                        await emit_step("tool_result", f"{display} 已返回", tool_name=tool_name)
                except Exception:
                    await emit_step("tool_result", f"{display} 已返回", tool_name=tool_name)

    logging.info(f"[MainAgent] Calling Graph Agent for RAG context...")
    graph_result = await run_graph_agent(
        question=question,
        session_id=session_id,
        chat_history=history,
        stop_event=stop_event,
        on_tool_call=on_tool_call,
        on_tool_result=on_tool_result,
    )

    logging.info(
        f"[MainAgent] Graph Agent returned rag_context: "
        f"{len(graph_result.get('rag_context', ''))} chars, "
        f"sources: {len(graph_result.get('sources', []))}"
    )

    if stop_event.is_set():
        logging.info("[MainAgent] Stopped after graph agent")
        await done_callback(None)
        return

    rag_context = graph_result.get("rag_context", "")
    sources = graph_result.get("sources", [])
    has_kg_facts = bool(graph_result.get("has_kg_facts"))

    if not rag_context:
        logging.warning("[MainAgent] No rag_context from graph agent, proceeding without database info")
        rag_context = "未从数据库查询到相关信息。"

    client = AsyncOpenAI(
        api_key=settings.LLM_API_KEY,
        base_url=settings.LLM_BASE_URL,
        timeout=settings.LLM_TIMEOUT,
    )

    system_prompt = """你是一个专业的海外藏中国文物知识问答助手。

根据以下 RAG context（数据库 / 知识图谱查询结果）回答用户问题，并对语言进行流畅润色。

要求：
- 直接、简洁地回答问题
- 如果 RAG context 有相关信息，基于它组织回答，可润色表述但不得编造事实
- **海外馆藏数据以英文记录为主**：文物名称(title)、作者(artist)、博物馆(museum)、朝代(dynasty)等须保留数据中的英文原文；可在英文后用括号补充中文，但不得把英文名全部替换成纯中文
  示例：Blue and White Vase（青花瓷器）、Harvard Art Museums、Tang（唐）
- 如果没有相关信息，直接告知用户
- 不要重复用户的问题
- 如有 detail_url 溯源链接，在回答中适当提及
- 不要在正文中写「根据知识图谱」「根据数据库」等系统内部术语
- **多轮对话**：用户可能用「它/这件/上面」等指代上文文物，须结合对话历史理解当前问题再回答"""

    current_user_content = f"""用户问题：{question}

数据库查询结果（RAG Context）：
{rag_context}

请根据以上信息回答用户问题："""

    messages: list[dict[str, str]] = [{"role": "system", "content": system_prompt}]
    messages.extend(build_openai_history_messages(prepared_history))
    messages.append({"role": "user", "content": current_user_content})

    logging.info(f"[MainAgent] Calling LLM for final answer...")
    logging.info(f"[MainAgent] RAG context length: {len(rag_context)} chars")

    try:
        stream = await client.chat.completions.create(
            model=settings.LLM_MODEL_NAME,
            messages=messages,
            stream=True,
            temperature=0.1,
        )
        logging.info("[MainAgent] LLM stream started...")

        full_response = ""
        async for chunk in stream:
            if stop_event.is_set():
                logging.info("[MainAgent] Stopped during streaming")
                if full_response:
                    await done_callback({
                        "content": full_response,
                        "has_kg_facts": has_kg_facts,
                        "has_llm_content": True,
                        "intent_label": graph_result.get("intent_label", "UNKNOWN"),
                        "sources": sources,
                    })
                else:
                    await done_callback(None)
                return

            if not chunk.choices:
                continue

            delta = chunk.choices[0].delta
            if delta is None:
                continue

            if delta.content:
                full_response += delta.content
                await token_callback(delta.content)

        logging.info(f"[MainAgent] Streaming finished, total: {len(full_response)} chars")
        await done_callback({
            "content": full_response,
            "has_kg_facts": has_kg_facts,
            "has_llm_content": bool(full_response.strip()),
            "intent_label": graph_result.get("intent_label", "UNKNOWN"),
            "sources": sources,
        })

    except Exception as e:
        logging.error(f"[MainAgent] LLM call failed: {e}")
        await done_callback({
            "content": f"生成回答时出错: {str(e)}",
            "has_kg_facts": has_kg_facts,
            "has_llm_content": True,
            "intent_label": "ERROR",
            "sources": sources,
        })
