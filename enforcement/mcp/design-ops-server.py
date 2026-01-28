#!/usr/bin/env python3
"""
Design-Ops MCP Server

Exposes design-ops validation rules and project patterns via Model Context Protocol.

Usage:
    # In Claude Code MCP settings:
    {
      "mcpServers": {
        "design-ops": {
          "command": "python",
          "args": ["/path/to/design-ops-server.py"]
        }
      }
    }

Tools provided:
- get_invariants: Get all 43 invariants
- get_security_rules: Get security validation rules
- get_project_conventions: Get CONVENTIONS.md if exists
- validate_spec_snippet: Validate a snippet against rules
"""

import json
import sys
from pathlib import Path

# MCP Protocol
def send_message(msg):
    """Send MCP message to stdout"""
    print(json.dumps(msg), flush=True)

def receive_message():
    """Receive MCP message from stdin"""
    line = sys.stdin.readline()
    if not line:
        return None
    return json.loads(line)

def get_invariants():
    """Return all 43 system invariants"""
    # Read from system-invariants.md
    design_ops_base = Path.home() / ".claude/design-ops"
    invariants_file = design_ops_base / "system-invariants.md"

    if invariants_file.exists():
        content = invariants_file.read_text()
        # Parse invariants (simplified - real implementation would parse markdown)
        return {
            "count": 43,
            "source": str(invariants_file),
            "content": content[:5000]  # Truncate for MCP response size
        }
    else:
        return {"error": "system-invariants.md not found"}

def get_security_rules():
    """Return security validation rules"""
    return {
        "rules": [
            {
                "id": "SEC-001",
                "name": "Authentication Required",
                "check": "Spec must mention authentication method (JWT, OAuth, session-based)"
            },
            {
                "id": "SEC-002",
                "name": "Authorization Documented",
                "check": "Spec must define permission model and access control rules"
            },
            {
                "id": "SEC-003",
                "name": "PII Handling",
                "check": "If handling personal data, must specify encryption, retention, GDPR compliance"
            },
            {
                "id": "SEC-004",
                "name": "Rate Limiting",
                "check": "API endpoints must define rate limits"
            },
            {
                "id": "SEC-005",
                "name": "Input Validation",
                "check": "Must specify validation rules for all user inputs"
            },
            {
                "id": "SEC-006",
                "name": "Error Handling",
                "check": "Error messages must not leak sensitive information"
            },
            {
                "id": "SEC-007",
                "name": "SQL Injection Prevention",
                "check": "Must use parameterized queries"
            },
            {
                "id": "SEC-008",
                "name": "XSS Prevention",
                "check": "Must sanitize all inputs"
            },
            {
                "id": "SEC-009",
                "name": "CSRF Protection",
                "check": "Must use CSRF tokens"
            }
        ]
    }

def get_project_conventions(project_dir="."):
    """Return CONVENTIONS.md if exists in project"""
    conventions_file = Path(project_dir) / "CONVENTIONS.md"

    if conventions_file.exists():
        return {
            "found": True,
            "path": str(conventions_file),
            "content": conventions_file.read_text()[:5000]
        }
    else:
        return {
            "found": False,
            "message": "No CONVENTIONS.md found in project"
        }

def validate_spec_snippet(snippet):
    """Quick validation of a spec snippet against common issues"""
    issues = []

    # Check for vague words
    vague_words = ["properly", "correctly", "appropriately", "easily", "simply", "just", "obviously"]
    for word in vague_words:
        if word in snippet.lower():
            issues.append({
                "severity": "warning",
                "rule": "Invariant #1: Ambiguity is Invalid",
                "message": f"Vague word '{word}' found - replace with objective criteria"
            })

    # Check for missing error states
    if "error" not in snippet.lower() and "fail" not in snippet.lower():
        issues.append({
            "severity": "warning",
            "rule": "Common Issue: Missing Error States",
            "message": "Consider documenting error handling"
        })

    # Check for missing acceptance criteria
    if "acceptance" not in snippet.lower() and "success" not in snippet.lower():
        issues.append({
            "severity": "info",
            "rule": "Best Practice: Acceptance Criteria",
            "message": "Consider adding clear acceptance criteria"
        })

    return {
        "valid": len(issues) == 0,
        "issues": issues,
        "checked_rules": ["ambiguity", "error_states", "acceptance_criteria"]
    }

# MCP Server Loop
def main():
    # Send server info
    send_message({
        "jsonrpc": "2.0",
        "method": "initialized",
        "params": {
            "serverInfo": {
                "name": "design-ops",
                "version": "1.0.0"
            },
            "capabilities": {
                "tools": {
                    "listChanged": False
                }
            }
        }
    })

    # Main loop
    while True:
        msg = receive_message()
        if not msg:
            break

        method = msg.get("method")
        id = msg.get("id")
        params = msg.get("params", {})

        if method == "tools/list":
            # List available tools
            send_message({
                "jsonrpc": "2.0",
                "id": id,
                "result": {
                    "tools": [
                        {
                            "name": "get_invariants",
                            "description": "Get all 43 design-ops system invariants",
                            "inputSchema": {
                                "type": "object",
                                "properties": {}
                            }
                        },
                        {
                            "name": "get_security_rules",
                            "description": "Get security validation rules (9 rules)",
                            "inputSchema": {
                                "type": "object",
                                "properties": {}
                            }
                        },
                        {
                            "name": "get_project_conventions",
                            "description": "Get project-specific conventions from CONVENTIONS.md",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "project_dir": {
                                        "type": "string",
                                        "description": "Project directory path (default: current)"
                                    }
                                }
                            }
                        },
                        {
                            "name": "validate_spec_snippet",
                            "description": "Quick validation of spec text against common issues",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "snippet": {
                                        "type": "string",
                                        "description": "Spec text to validate"
                                    }
                                },
                                "required": ["snippet"]
                            }
                        }
                    ]
                }
            })

        elif method == "tools/call":
            # Execute tool
            tool_name = params.get("name")
            arguments = params.get("arguments", {})

            result = None
            if tool_name == "get_invariants":
                result = get_invariants()
            elif tool_name == "get_security_rules":
                result = get_security_rules()
            elif tool_name == "get_project_conventions":
                project_dir = arguments.get("project_dir", ".")
                result = get_project_conventions(project_dir)
            elif tool_name == "validate_spec_snippet":
                snippet = arguments.get("snippet", "")
                result = validate_spec_snippet(snippet)
            else:
                result = {"error": f"Unknown tool: {tool_name}"}

            send_message({
                "jsonrpc": "2.0",
                "id": id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(result, indent=2)
                        }
                    ]
                }
            })

if __name__ == "__main__":
    main()
