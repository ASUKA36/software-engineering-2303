# 将 docs/组会/ 同步到 GitHub Wiki 并推送
# 用法：在项目根目录执行  powershell -ExecutionPolicy Bypass -File scripts/push-wiki.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

$WikiDir = Join-Path $Root ".wiki-repo"
$Remote = "https://github.com/ASUKA36/software-engineering-2303.wiki.git"
$Weeks = @(
    "第八周组会记录", "第九周组会记录", "第十周组会记录",
    "第十一周组会记录", "第十二周组会记录", "第十三周组会记录", "第十四周组会记录"
)

Write-Host ">> 同步组会 Markdown 到 .wiki-repo ..."
if (-not (Test-Path $WikiDir)) { New-Item -ItemType Directory -Path $WikiDir | Out-Null }
foreach ($w in $Weeks) {
    Copy-Item "docs/组会/$w.md" "$WikiDir/$w.md" -Force
}
Copy-Item "scripts/wiki-Home.md" "$WikiDir/Home.md" -Force -ErrorAction SilentlyContinue
if (-not (Test-Path "$WikiDir/Home.md")) {
    Write-Host "警告: 未找到 scripts/wiki-Home.md，保留现有 Home.md"
}

Set-Location $WikiDir
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
    git remote add origin $Remote
}

git add -A
$status = git status --porcelain
if ($status) {
    git commit -m "同步组会文档（第八～十四周）"
} else {
    Write-Host "Wiki 内容无变更，跳过 commit"
}

Write-Host ">> 推送到 $Remote ..."
git push -u origin main --force

Write-Host "完成。Wiki: https://github.com/ASUKA36/software-engineering-2303/wiki"
