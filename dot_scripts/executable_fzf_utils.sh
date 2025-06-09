#!/usr/bin/env bash
set -euo pipefail

# fzf便利ユーティリティ集
# 使用方法: fzf_utils.sh <command> [args...]

check_dependencies() {
  local deps=("$@")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Error: $dep is required but not installed." >&2
      exit 1
    fi
  done
}

show_usage() {
  cat <<EOF
Usage: $0 <command>

Available commands:
  docker-container (fzdc) - Select and inspect Docker containers
  git-branch (fzgb)      - Select and checkout Git branches
  git-log (fzgl)         - Browse Git commit history
  file-search (fzff)     - Search and edit project files
  process-kill (fzpk)    - Select and kill processes
  ssh-host (fzsh)        - Select SSH hosts from config
  git-diff (fzgd)        - View diff of changed files
  docker-image (fzdi)    - Manage Docker images
  recent-dir (fzcd)      - Navigate to recent directories
EOF
}

# Docker Container Selector
docker_container() {
  check_dependencies docker fzf

  local container
  container=$(docker ps -a --format "{{.Names}}" |
    fzf --preview 'docker inspect --format="
🐳 Container: {1}
📦 Image: {{.Config.Image}}
{{if eq .State.Status \"running\"}}🟢{{else}}🔴{{end}} Status: {{.State.Status}}
🌐 IP: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}
🔌 Ports: {{range \$p, \$conf := .NetworkSettings.Ports}}{{\$p}} {{end}}
📅 Created: {{.Created | printf \"%.19s\"}}
⏰ Started: {{.State.StartedAt | printf \"%.19s\"}}
🏷️ Project: {{index .Config.Labels \"com.docker.compose.project\"}} 
⚙️ Service: {{index .Config.Labels \"com.docker.compose.service\"}} 
🔄 Restart: {{.HostConfig.RestartPolicy.Name}}
📊 Exit Code: {{.State.ExitCode}}

【Environment Variables】
{{range .Config.Env}}• {{.}}
{{end}}

【Mounts】
{{range .Mounts}}• {{.Source}} → {{.Destination}} ({{.Type}})
{{end}}
" {}' \
      --preview-window=right:60% \
      --header="Select container (Enter: exec bash, Ctrl-L: logs, Ctrl-S: start, Ctrl-K: stop)" \
      --bind="ctrl-l:execute(docker logs {} | less)" \
      --bind="ctrl-s:execute(docker start {})" \
      --bind="ctrl-k:execute(docker stop {})")

  if [[ -n "$container" ]]; then
    echo "Selected container: $container"
    docker exec -it "$container" bash 2>/dev/null || docker exec -it "$container" sh
  fi
}

# Git Branch Selector
git_branch() {
  check_dependencies git fzf

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
  fi

  local branch
  branch=$(git branch -a --format="%(refname:short)" |
    sed 's/^origin\///' | sort -u |
    fzf --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(git merge-base HEAD {}) | head -20' \
      --preview-window=right:50% \
      --header="Select branch to checkout")

  if [[ -n "$branch" ]]; then
    git checkout "$branch"
  fi
}

# Git Log Explorer
git_log() {
  check_dependencies git fzf

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
  fi

  local commit
  commit=$(git log --oneline --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" |
    fzf --ansi \
      --preview 'git show --color=always {2}' \
      --preview-window=right:60% \
      --header="Browse commits (Enter: show, Ctrl-C: checkout)" \
      --bind="ctrl-c:execute(git checkout {2})+abort")

  if [[ -n "$commit" ]]; then
    local hash
    hash=$(echo "$commit" | awk '{print $2}')
    git show "$hash"
  fi
}

# File Search
file_search() {
  check_dependencies fzf

  local file
  if command -v rg >/dev/null 2>&1; then
    file=$(rg --files --hidden --follow --glob '!.git' |
      fzf --preview 'bat --color=always --style=header,grid --line-range=:300 {}' \
        --preview-window=right:60%)
  elif command -v fd >/dev/null 2>&1; then
    file=$(fd --type f --hidden --follow --exclude .git |
      fzf --preview 'cat {}' --preview-window=right:60%)
  else
    file=$(find . -type f -not -path '*/\.git/*' |
      fzf --preview 'cat {}' --preview-window=right:60%)
  fi

  if [[ -n "$file" ]]; then
    "${EDITOR:-vim}" "$file"
  fi
}

# Process Killer
process_kill() {
  check_dependencies ps fzf

  local pid
  pid=$(ps -ef | sed 1d |
    fzf --multi --header="Select processes to kill (Tab: multi-select)" \
      --preview 'echo {}' --preview-window=up:3:wrap |
    awk '{print $2}')

  if [[ -n "$pid" ]]; then
    echo "Killing process(es): $pid"
    echo "$pid" | xargs kill
  fi
}

# SSH Host Selector
ssh_host() {
  check_dependencies fzf

  local ssh_config="$HOME/.ssh/config"
  if [[ ! -f "$ssh_config" ]]; then
    echo "Error: SSH config file not found at $ssh_config" >&2
    exit 1
  fi

  local host
  host=$(grep "^Host " "$ssh_config" | awk '{print $2}' | grep -v '*' |
    fzf --preview 'grep -A 10 "^Host {}" ~/.ssh/config' \
      --preview-window=right:50% \
      --header="Select SSH host")

  if [[ -n "$host" ]]; then
    ssh "$host"
  fi
}

# Git Diff Viewer
git_diff() {
  check_dependencies git fzf

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
  fi

  local file
  file=$(git diff --name-only |
    fzf --preview 'git diff --color=always {}' \
      --preview-window=right:60% \
      --header="Select file to view diff")

  if [[ -n "$file" ]]; then
    git diff "$file" | less -R
  fi
}

# Docker Image Manager
docker_image() {
  check_dependencies docker fzf

  local image
  image=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}" |
    tail -n +2 |
    fzf --header="Select Docker image (Enter: inspect, Ctrl-R: run, Ctrl-D: delete)" \
      --preview 'docker inspect {3}' --preview-window=right:60% \
      --bind="ctrl-r:execute(docker run -it {1}:{2})" \
      --bind="ctrl-d:execute(docker rmi {3})")

  if [[ -n "$image" ]]; then
    local image_id
    image_id=$(echo "$image" | awk '{print $3}')
    docker inspect "$image_id"
  fi
}

# Recent Directory Navigator
recent_dir() {
  check_dependencies fzf

  local recent_dirs="$HOME/.local/share/recent_dirs"
  if [[ ! -f "$recent_dirs" ]]; then
    mkdir -p "$(dirname "$recent_dirs")"
    dirs -p >"$recent_dirs" 2>/dev/null || echo "$PWD" >"$recent_dirs"
  fi

  local dir
  dir=$(cat "$recent_dirs" |
    fzf --preview 'ls -la {}' --preview-window=right:50% \
      --header="Select directory")

  if [[ -n "$dir" && -d "$dir" ]]; then
    echo "cd \"$dir\""
  fi
}

# メイン処理
case "${1:-}" in
  docker-container | fzdc)
    docker_container
    ;;
  git-branch | fzgb)
    git_branch
    ;;
  git-log | fzgl)
    git_log
    ;;
  file-search|fzff)
    file_search
    ;;
  process-kill|fzpk)
    process_kill
    ;;
  ssh-host|fzsh)
    ssh_host
    ;;
  git-diff|fzgd)
    git_diff
    ;;
  docker-image|fzdi)
    docker_image
    ;;
  recent-dir|fzcd)
    recent_dir
    ;;
  *)
    show_usage
    exit 1
    ;;
esac