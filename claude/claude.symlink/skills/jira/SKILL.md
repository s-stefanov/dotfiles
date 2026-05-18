---
allowed-tools: Bash(acli:*)
description: Query and manage Jira tickets using natural language
argument-hint: <natural language request or JQL query>
---

# Jira Integration Skill

You help users interact with Jira via the Atlassian CLI (`acli`).

## Your Capabilities

1. **Search tickets** - Find issues by project, assignee, status, text, etc.
2. **View ticket details** - Show full information about a specific ticket
3. **Create tickets** - Create new issues (bugs, stories, tasks)
4. **Update tickets** - Change status, assignee, or add comments
5. **Sprint/board queries** - Show sprint contents and board status

## Command Reference

### Searching
```bash
# By project
acli jira workitem search --jql "project = PROJECT_KEY" --fields "key,summary,status,assignee"

# By assignee (current user)
acli jira workitem search --jql "assignee = currentUser() AND resolution = Unresolved" --fields "key,summary,status"

# By text search
acli jira workitem search --jql "project = PROJECT_KEY AND text ~ 'search term'" --fields "key,summary,status"

# By issue type
acli jira workitem search --jql "project = PROJECT_KEY AND issuetype = Bug" --fields "key,summary,status,priority"

# By epic/parent
acli jira workitem search --jql "parent = EPIC-KEY" --fields "key,summary,status,assignee"

# Current sprint
acli jira workitem search --jql "project = PROJECT_KEY AND sprint in openSprints()" --fields "key,summary,status,assignee"

# Recently updated
acli jira workitem search --jql "project = PROJECT_KEY AND updated >= -7d" --fields "key,summary,status,updated"
```

### Viewing Details
```bash
acli jira workitem view TICKET-KEY
```

### Creating Tickets
```bash
# Create a bug
acli jira workitem create --project PROJECT_KEY --type Bug --summary "Title here" --description "Description here"

# Create a story
acli jira workitem create --project PROJECT_KEY --type Story --summary "Title here"

# Create a task
acli jira workitem create --project PROJECT_KEY --type Task --summary "Title here"
```

### Updating Tickets

```bash
# Add comment
acli jira workitem comment create --key "TICKET-KEY" --body "Comment text"

# Edit ticket description (supports markdown in Jira Cloud)
acli jira workitem edit --key "TICKET-KEY" --description "New description with **markdown**" --yes

# Transition status (get available transitions first)
acli jira workitem transitions TICKET-KEY
acli jira workitem transition TICKET-KEY --transition "In Progress"

# Assign
acli jira workitem edit --key "TICKET-KEY" --assignee "user@email.com" --yes
```

> **Note:** Jira Cloud renders markdown in descriptions. Use markdown formatting (headers, tables, code blocks) for well-formatted ticket descriptions.

## Output Options
- `--fields "key,summary,status"` - Select specific columns
- `--paginate` - Fetch all results (use for large result sets)
- `--json` - JSON output (useful for further processing)
- `--csv` - CSV output
- `--limit N` - Limit to N results

## Instructions

When the user makes a request:

1. **Parse their intent** - Understand what they want (search, view, create, update)

2. **Ask for missing info** - If they say "my tickets" but you need a project, ask which project. If they want to create a ticket but didn't specify type, ask.

3. **Build the appropriate command** - Construct the `acli jira` command

4. **Execute and present results** - Run the command and format output clearly

5. **Handle errors gracefully**:
   - "Authentication failed" → Suggest: `acli login jira --url <url>`
   - "Project not found" → Ask user to verify project key
   - "No results" → Suggest broadening the search

## Common Patterns

| User Says | Interpret As |
|-----------|--------------|
| "my tickets", "my issues" | `assignee = currentUser() AND resolution = Unresolved` |
| "open bugs in X" | `project = X AND issuetype = Bug AND resolution = Unresolved` |
| "show ABC-123" | `acli jira workitem view ABC-123` |
| "what's blocking" | `status = Blocked` or `labels = blocked` |
| "sprint items" | `sprint in openSprints()` |
| "recent updates" | `updated >= -7d ORDER BY updated DESC` |

## User Request

$ARGUMENTS

Interpret the above request and execute the appropriate Jira command(s).
