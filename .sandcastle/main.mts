/**
 * ONE ISSUE, ONE CONTAINER, ONE REVIEW -- one after another.
 *
 *   npx tsx .sandcastle/main.mts               the LOOP: run the queue, one issue at a time, keep watching
 *   npx tsx .sandcastle/main.mts --issue N     run N ONCE and exit (also: a bare N)
 *   add --dry-run to either                    resolve every decision, start no container, exit
 *   add --show-prompt to a dry run             print prompt.md with the placeholders substituted
 *
 * Adapted on 2026-10-21 from the Maple project's `.sandcastle/main.mts`, where this shape has run
 * unattended since 2026-10-17. What is kept, and why, in short:
 *
 *   * NOT the upstream Plan -> (Implement -> Review) x4 -> Merge shape. The user's standing rule
 *     (maple, 2026-10-16) is one issue at a time, "instead of have infinite PRs to review", and
 *     token usage under control. So: one model invocation per issue, and a sequential loop on the
 *     HOST around it. Every gate below runs again for every issue.
 *   * THE HOST DOES WHAT THE CONTAINER MUST NOT. The container's GH_TOKEN is Issues-RW + Metadata-R
 *     only, so it physically cannot push or open a PR. The host pushes the branch and opens a DRAFT
 *     PR with the agent's own text as the body. Nothing here merges: the user merges, every time.
 *   * A SEPARATE CLONE, NOT THE WORKING TREE. `cwd` decides which repo sandcastle bind-mounts, and
 *     it mounts that repo's `.git` WRITABLE (a container that writes `.git/hooks/pre-commit` gets
 *     code execution on this machine at the next commit). Pointing `cwd` at a disposable clone means
 *     the exposed `.git` is the clone's. The clone is also checked out with `core.autocrlf=false`,
 *     so a Linux container does not see every tracked file as modified (this host has autocrlf=true
 *     and no .gitattributes).
 *   * NO HOST MOUNTS. Maple mounts its memory store and test fixtures read-only. This repo is PUBLIC:
 *     the memory store and the private add-on repo both hold business material, and an agent that can
 *     read them can paste them into a public commit. The container gets the repo, the issue, and
 *     prompt.md -- nothing else. Every test in this repo is self-contained, so nothing is lost.
 *
 * What Maple has that this file deliberately leaves out: the rig gate (no live hardware here) and
 * issue-declared file mounts (no gitignored fixtures here).
 */
import { run, claudeCode, Output } from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

// ---------------------------------------------------------------------------- the knobs
//
// MODEL. Token control comes from one invocation per issue, not from a smaller model.
// "claude-sonnet-5-5" is the swap if a run turns out not to need it, and the only edit.
const MODEL = "claude-opus-5-5";
const GITHUB_REPO = "Shiningingy/Restaurant-System";   // the canonical name; the old "Restruant" spelling redirects
const SANDCASTLE_REPO = "G:/restaurant-sandcastle";      // the disposable clone, see the header
const SANDCASTLE_LABEL = "sandcastle";                    // the opt-in: "fit for an unattended container"
const LABELS = [SANDCASTLE_LABEL, "ready-for-agent"];

// ONE name, read by both the preflight and the docker() provider. Two literals for one image is the
// two-ledgers bug in miniature: a preflight that checks the wrong name reports health it never measured.
const IMAGE_NAME = "sandcastle-restaurant";

// `Output.string` requires the resolved prompt to contain this tag literally, so the name is read by
// both the prompt check and the Output definition.
const PR_BODY_TAG = "pr-body";

// THE IDLE WINDOW MUST BE LONGER THAN THE SLOWEST SINGLE CHECK. The engine fails a run after this
// many seconds with no agent output. The first `flutter pub get` in a fresh container plus the
// sqlite3mc native build plus `flutter test` on apps/merchant can take several minutes; prompt.md
// asks the agent to run the gates ONE AT A TIME and never in the background, which is the other
// half of this fix. Maple measured its full suite at 736 s and settled on 1800; same here until
// a run measures otherwise.
const IDLE_TIMEOUT_S = 1800;

// `--dry-run` resolves everything a run depends on (docker, the clone, the issue, the base ref, the
// keys, the prompt) and stops before a container. tsx does not typecheck, so running the decisions
// is the only cheap way to exercise this file. Every refusal below is reachable with no container.
const DRY_RUN = process.argv.includes("--dry-run");

// An explicit pick -- `<N>` or `--issue <N>` -- runs N once and exits. It is a convenience for
// choosing among SUITABLE issues, never a bypass: N must still carry `sandcastle` and pass every
// gate. The backlog cap is the one gate it ignores, because a human pick is a human accepting one
// more PR to review.
function parseExplicitIssue(argv: string[]): number | undefined {
  const at = argv.indexOf("--issue");
  const raw = at >= 0 ? argv[at + 1] : argv.find((a) => /^\d+$/.test(a));
  if (raw === undefined && at < 0) return undefined;
  if (raw === undefined || !/^[1-9]\d*$/.test(raw)) {
    console.error(`REFUSING TO START: --issue needs an issue number, got ${raw ?? "nothing"}.`);
    process.exit(2);
  }
  return Number(raw);
}
const EXPLICIT_ISSUE = parseExplicitIssue(process.argv.slice(2));

// MAX_OPEN_PRS. The user reads every PR, so a queue that drains faster than it is read is the
// failure. The loop WAITS at this many open `sandcastle/issue-*` PRs. A PR whose issue carries
// `deferred` is not counted: the user parked it.
const MAX_OPEN_PRS = 2;
const WATCH_S = 600;                         // a pass is a few REST calls and zero tokens
const LABEL_NEXT_UP = "next-up";             // picked first; then the LOWEST number
const LABEL_HUMAN = "ready-for-human";       // the user's to judge: database, payment, a dependency, a seam
const LABEL_DEFERRED = "deferred";           // parked by the user: its PR does not count toward the cap
const LABEL_REWORK = "needs-more-work";      // the user reviewed the PR and wants more: rerun on the SAME branch
const LABEL_REVIEW = "under-review";         // set by the host once a draft PR exists

// THE BASE BRANCH IS A PER-ISSUE FACT, so it lives on the issue as a `base:<branch>` label. Maple
// refuses an issue with no base label; here `main` is the default, because this repo's work almost
// always starts from main and the extension-slot branch is the exception. An issue that builds on
// another branch says so: `base:feature/extension-slot`.
const BASE_LABEL_PREFIX = "base:";
const DEFAULT_BASE = "main";

// ---------------------------------------------------------------------------- 1. gates on this host
function dockerGate(): void {
  let dockerServer = "";
  try {
    dockerServer = execFileSync("docker", ["version", "--format", "{{.Server.Version}}"],
      { encoding: "utf8", stdio: "pipe", timeout: 20_000 }).trim();
  } catch { /* refused just below: an unreachable daemon is the expected failure, not an exception */ }
  if (!dockerServer) {
    console.error("REFUSING TO START: the Docker daemon is not reachable.");
    console.error("  Start Docker Desktop and wait for it to report running before re-running this.");
    process.exit(10);
  }
  let haveImage = "";
  try {
    haveImage = execFileSync("docker",
      ["images", "--format", "{{.Repository}}", "--filter", `reference=${IMAGE_NAME}`],
      { encoding: "utf8", stdio: "pipe", timeout: 20_000 }).trim();
  } catch { /* same: report it below rather than dying with a stack trace */ }
  if (!haveImage) {
    console.error(`REFUSING TO START: the Docker daemon is up, but image '${IMAGE_NAME}' does not exist.`);
    console.error("  Build it from the working tree (the Dockerfile copies nothing from the repo):");
    console.error(`    docker build -t ${IMAGE_NAME} -f .sandcastle/Dockerfile .`);
    process.exit(10);
  }
}

function cloneGate(): void {
  if (existsSync(SANDCASTLE_REPO)) return;
  console.error(`REFUSING TO START: ${SANDCASTLE_REPO} does not exist.`);
  console.error("  Create it once. It is deliberately NOT this working tree (see the header), and it is");
  console.error("  cloned FROM GITHUB so that `gh` and `git push origin` resolve to where the PR is opened:");
  console.error(`    git clone -c core.autocrlf=false https://github.com/${GITHUB_REPO}.git "${SANDCASTLE_REPO}"`);
  process.exit(4);
}

// ---------------------------------------------------------------------------- 2. pick the issue
// Every read is the REST API, never `gh issue list`: that goes through GitHub's search index, which
// lags a label edit by minutes and once made Maple's launcher skip the issue it had just been pointed
// at. `--repo` is explicit so a `gh` default in the clone can never redirect these calls.
const gh = (args: string[]) => execFileSync("gh", args, { encoding: "utf8", cwd: SANDCASTLE_REPO });
const ghGet = <T,>(path: string): T => JSON.parse(gh(["api", path])) as T;
const ghList = <T,>(path: string): T[] => JSON.parse(gh(["api", "--paginate", "--slurp", path])).flat() as T[];
const REPO_API = `repos/${GITHUB_REPO}`;

type Issue = {
  number: number; title: string; body: string | null; html_url: string; state: string;
  labels: { name: string }[]; pull_request?: unknown;
};
const labelsOf = (i: Issue) => i.labels.map((l) => l.name);

// Deterministic, so re-running the same issue REUSES the branch and accumulates progress instead of
// starting over. The same name is how an open PR is mapped back to its issue.
const BRANCH_PREFIX = "sandcastle/issue-";
const branchOf = (n: number) => `${BRANCH_PREFIX}${n}`;

function fetchIssue(n: number): Issue | null {
  try { return ghGet<Issue>(`${REPO_API}/issues/${n}`); } catch { return null; }
}

// Open PRs on a `sandcastle/issue-N` head, keyed by N. One call answers both "does this issue already
// have a PR" and "how big is the backlog", so the two can never disagree.
type OpenPr = { url: string; number: number };
function openSandcastlePrs(): Map<number, OpenPr> {
  const byIssue = new Map<number, OpenPr>();
  for (const p of ghList<{ html_url: string; number: number; head: { ref: string } }>(`${REPO_API}/pulls?state=open&per_page=100`)) {
    if (!p.head.ref.startsWith(BRANCH_PREFIX)) continue;
    const n = Number(p.head.ref.slice(BRANCH_PREFIX.length));
    if (Number.isInteger(n) && n > 0) byIssue.set(n, { url: p.html_url, number: p.number });
  }
  return byIssue;
}

// GitHub's NATIVE blocked-by list, not a convention parsed out of a body: a blocker closes when its
// PR merges (`Closes #N`, which the tail writes), so "an open blocker" IS "the dependency is not merged".
const openBlockers = (n: number) =>
  ghList<{ number: number; state: string }>(`${REPO_API}/issues/${n}/dependencies/blocked_by?per_page=100`)
    .filter((b) => b.state === "open").map((b) => b.number);

// Keep the clone current. This is also what makes BASE_REF resolvable at all.
const fetchOrigin = () =>
  execFileSync("git", ["fetch", "origin", "--prune"], { cwd: SANDCASTLE_REPO, stdio: "inherit" });

type Plan = { issue: Issue; BASE_BRANCH: string; BASE_REF: string; branch: string; rework: OpenPr | null };
type Refusal = { code: number; why: string[] };

function resolvePlan(issue: Issue, openPrs: Map<number, OpenPr>): Plan | Refusal {
  const branch = branchOf(issue.number);

  // An open PR means the ball is in the user's court, so an unattended launch stops here -- UNLESS the
  // user put `needs-more-work` on the issue, which means "rerun on the same branch and update that PR".
  const pr = openPrs.get(issue.number) ?? null;
  const rework = labelsOf(issue).includes(LABEL_REWORK);
  if (pr && !rework) {
    return { code: 0, why: [
      `#${issue.number} already has an open PR: ${pr.url}`,
      `  Merge it, close it, or label the issue \`${LABEL_REWORK}\` to have it reworked. Nothing to do.`,
    ] };
  }
  if (rework && !pr) {
    return { code: 12, why: [
      `#${issue.number} carries \`${LABEL_REWORK}\` but has no open ${BRANCH_PREFIX}* PR to rework.`,
      "  Remove the label to run it fresh.",
    ] };
  }

  const blockers = openBlockers(issue.number);
  if (blockers.length) {
    return { code: 11, why: [
      `#${issue.number} is blocked by open issue(s) ${blockers.map((b) => `#${b}`).join(", ")}: a dependency not yet merged.`,
    ] };
  }

  const baseLabels = labelsOf(issue).filter((n) => n.startsWith(BASE_LABEL_PREFIX));
  if (baseLabels.length > 1) {
    return { code: 7, why: [
      `#${issue.number} carries ${baseLabels.length} base: labels (${baseLabels.join(", ")}). Exactly one, or none for main.`,
    ] };
  }
  const BASE_BRANCH = baseLabels.length ? baseLabels[0].slice(BASE_LABEL_PREFIX.length) : DEFAULT_BASE;

  // The run must start from the FETCHED ref, not the clone's local branch: `git fetch` advances
  // `origin/*` and nothing else. The engine resolves `baseBranch` as a plain committish inside the clone.
  const BASE_REF = `origin/${BASE_BRANCH}`;
  try {
    execFileSync("git", ["rev-parse", "--verify", "--quiet", `${BASE_REF}^{commit}`],
      { cwd: SANDCASTLE_REPO, stdio: "pipe" });
  } catch {
    return { code: 7, why: [
      `${BASE_REF} does not exist on origin. #${issue.number} is labelled ${BASE_LABEL_PREFIX}${BASE_BRANCH}: push that branch, or fix the label.`,
    ] };
  }

  return { issue, BASE_BRANCH, BASE_REF, branch, rework: rework ? pr : null };
}

function describePlan(p: Plan): void {
  console.log(`\n  issue    #${p.issue.number}  ${p.issue.title}`);
  console.log(`           ${p.issue.html_url}`);
  console.log(`  labels   ${labelsOf(p.issue).join(", ")}`);
  console.log(`  base     ${p.BASE_REF}  (PR --base ${p.BASE_BRANCH})`);
  console.log(`  branch   ${p.branch}${p.rework ? `  (REWORK of open PR ${p.rework.url})` : ""}`);
  console.log(`  model    ${MODEL}   image ${IMAGE_NAME}   idle ${IDLE_TIMEOUT_S} s`);
}

// ---------------------------------------------------------------------------- 3. credentials
const localEnv = (name: string) => fileURLToPath(new URL(name, import.meta.url));

// The engine's own parser minus the escape handling: skip blanks and `#`, split on the first `=`,
// strip one layer of matching quotes.
function parseEnvFile(file: string): Record<string, string> {
  const vars: Record<string, string> = {};
  for (const line of readFileSync(file, "utf8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    let value = trimmed.slice(eq + 1).trim();
    const quote = value[0];
    if (value.length >= 2 && (quote === '"' || quote === "'") && value.endsWith(quote)) value = value.slice(1, -1);
    vars[trimmed.slice(0, eq).trim()] = value;
  }
  return vars;
}

// The engine reads `.sandcastle/.env` from `cwd`, i.e. from the CLONE. The real tokens stay in THIS
// folder's .env; the clone gets a keys-only file, and an empty value makes the engine fall back to the
// host process env, which `launch` sets just before `run()` and restores right after.
function loadCredentials(): { REQUIRED_KEYS: string[]; secrets: Record<string, string> } {
  for (const f of [".env.example", ".env"]) {
    if (existsSync(localEnv(f))) continue;
    console.error(`REFUSING TO START: .sandcastle/${f} does not exist.`);
    console.error("  .env.example is the KEY LIST, .env holds the values, and both live next to this script.");
    process.exit(5);
  }
  const REQUIRED_KEYS = Object.keys(parseEnvFile(localEnv(".env.example")));
  const secrets = parseEnvFile(localEnv(".env"));
  const missingKeys = REQUIRED_KEYS.filter((k) => !secrets[k]);
  if (missingKeys.length) {
    console.error(`REFUSING TO START: ${missingKeys.join(", ")} missing from .sandcastle/.env`);
    console.error("  The container authenticates with these and cannot ask for them.");
    process.exit(5);
  }
  const cloneSandcastle = `${SANDCASTLE_REPO}/.sandcastle`;
  mkdirSync(cloneSandcastle, { recursive: true });
  writeFileSync(`${cloneSandcastle}/.gitignore`, ".env\nlogs/\nworktrees/\n");
  writeFileSync(`${cloneSandcastle}/.env`, [
    "# Written by .sandcastle/main.mts on every run. KEYS ONLY, DELIBERATELY NO VALUES: the engine falls",
    `# back to the host process env for an empty value, so the real tokens stay in`,
    `# "${localEnv(".env")}" and never land in this clone. Editing this file does nothing.`,
    ...REQUIRED_KEYS.map((k) => `${k}=`), "",
  ].join("\n"));
  console.log(`  keys     ${REQUIRED_KEYS.join(", ")}  (values stay on the host)`);
  return { REQUIRED_KEYS, secrets };
}

// ---------------------------------------------------------------------------- 4. the prompt
// The host picked the issue, so the container must not pick it again: the pick travels as promptArgs.
// The engine strips the shell-block marker from every value, so a backtick in an issue body is inert.
// A missing `{{KEY}}` is a hard failure, never a blank, which is why an empty body is "" and not null.
const promptArgsOf = (p: Plan) => ({
  ISSUE_NUMBER: p.issue.number,
  ISSUE_TITLE: p.issue.title,
  ISSUE_URL: p.issue.html_url,
  ISSUE_BODY: p.issue.body ?? "",
  BASE_BRANCH: p.BASE_BRANCH,
  REWORK_NOTE: p.rework
    ? `This is a REWORK. Draft PR ${p.rework.url} already holds your earlier commits on this branch; the user ` +
      `reviewed it and labelled the issue \`${LABEL_REWORK}\`. Read their review comments with ` +
      `\`gh pr view ${p.rework.number} --comments\` and \`gh api ${REPO_API}/pulls/${p.rework.number}/comments\`, ` +
      `and address them. Build on the existing commits; do not start over.`
    : "This is a fresh run on a new branch.",
});

// Validate the placeholders and shell blocks HERE: the engine only validates them once a run has
// started, and substitution does not skip HTML comments, so a placeholder written as an example is a
// dead run. Mirrored from the engine's PromptArgumentSubstitution; if a run ever fails on a placeholder
// that passed here, this is the line that went stale.
const PLACEHOLDER_PATTERN = /\{\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\}/g;
const BUILT_IN_ARGS = ["SOURCE_BRANCH", "TARGET_BRANCH"];
const SHELL_BLOCK_PATTERN = /!`([^`]+)`/g;
const COMMAND_TOKEN = /^[A-Za-z0-9_./-]+$/;

// The prompt is read from THIS folder by absolute path, not from the clone: until `.sandcastle/` is
// merged, the clone has no prompt.md, and even after, one prompt with one home beats two copies.
const PROMPT_FILE = localEnv("prompt.md");

function checkPrompt(promptArgs: ReturnType<typeof promptArgsOf>): string {
  const promptText = readFileSync(PROMPT_FILE, "utf8");
  const referenced = [...new Set([...promptText.matchAll(PLACEHOLDER_PATTERN)].map((m) => m[1]))];
  const missingArgs = referenced.filter((k) => !BUILT_IN_ARGS.includes(k) && !(k in promptArgs));
  if (missingArgs.length) {
    console.error(`REFUSING TO START: prompt.md references ${missingArgs.map((k) => `{{${k}}}`).join(", ")} with no value.`);
    console.error("  A placeholder written as an EXAMPLE counts: substitution does not skip HTML comments.");
    process.exit(8);
  }
  for (const k of Object.keys(promptArgs)) {
    if (!referenced.includes(k)) console.error(`  warn: promptArgs.${k} is never referenced in prompt.md`);
  }
  const shellBlocks = [...promptText.matchAll(SHELL_BLOCK_PATTERN)].map((m) => m[1].trim());
  const bogus = shellBlocks.filter((c) => !COMMAND_TOKEN.test(c.split(/\s+/)[0]));
  if (bogus.length) {
    console.error(`REFUSING TO START: prompt.md has a shell block that cannot be a command: ${bogus.map((c) => `\`${c}\``).join(", ")}`);
    console.error("  The engine EXECUTES these in the container and a non-zero exit kills the run before the agent exists.");
    process.exit(8);
  }
  if (!promptText.includes(`<${PR_BODY_TAG}>`)) {
    console.error(`REFUSING TO START: prompt.md does not contain the <${PR_BODY_TAG}> tag.`);
    process.exit(8);
  }
  console.log(`  prompt   ${referenced.length} placeholders, ${shellBlocks.length} shell block(s), <${PR_BODY_TAG}> present`);
  for (const c of shellBlocks) console.log(`  exec     \`${c}\`  (runs IN the container)`);
  return promptText;
}

// ---------------------------------------------------------------------------- 5. run ONE issue
async function launch(plan: Plan): Promise<string> {
  describePlan(plan);
  const { issue, BASE_BRANCH, BASE_REF, branch } = plan;
  const { REQUIRED_KEYS, secrets } = loadCredentials();
  const promptArgs = promptArgsOf(plan);
  const promptText = checkPrompt(promptArgs);

  if (DRY_RUN) {
    if (process.argv.includes("--show-prompt")) {
      console.log("\n--- prompt.md, substituted (shell blocks still expand in the container) ---");
      console.log(promptText.replace(PLACEHOLDER_PATTERN, (m, k) =>
        k in promptArgs ? String(promptArgs[k as keyof typeof promptArgs]) : m));
      console.log("--- end ---\n");
    }
    console.log("--dry-run: docker, clone, issue, base ref, keys, placeholders, shell blocks and the output");
    console.log("  tag all resolved. No container started.");
    return "dry-run";
  }

  // Captured BEFORE the bridge overwrites it, because the tail needs the USER's auth back: the
  // container's GH_TOKEN cannot open a PR (403 on /pulls by design). Restored in `finally`, and an
  // unset value is restored AS UNSET so `gh` falls back to the user's own stored credentials.
  const HOST_ENV_BEFORE: Record<string, string | undefined> =
    Object.fromEntries(REQUIRED_KEYS.map((k) => [k, process.env[k]]));
  for (const k of REQUIRED_KEYS) process.env[k] = secrets[k];

  let result;
  try {
    result = await run({
      name: `issue-${issue.number}`,
      cwd: SANDCASTLE_REPO,
      agent: claudeCode(MODEL),
      promptFile: PROMPT_FILE,
      maxIterations: 1,                       // ONE. The user's rule, not a default to tune.
      idleTimeoutSeconds: IDLE_TIMEOUT_S,
      promptArgs,
      // The PR body is the agent's to write: it is the only party that knows what it did. `maxRetries: 1`
      // has the engine ask once more if the tag never came; if it still does not, the host pushes the
      // branch and does NOT invent a body.
      output: Output.string({ tag: PR_BODY_TAG, maxRetries: 1 }),
      // NOT the docker default of {type:"head"}: that bind-mounts the live working tree on whatever
      // branch is checked out, which would let an unattended agent commit to main.
      branchStrategy: { type: "branch", branch, baseBranch: BASE_REF },
      sandbox: docker({
        imageName: IMAGE_NAME,
        // No mounts, on purpose: see the header. The repo is public; the memory store and the
        // private add-ons are not.
        cpus: 4,
      }),
      // No `logging` key: `{ type: "file" }` with no `path` SUPPRESSES the default log instead of
      // requesting it (measured on maple). Omitted, the engine writes .sandcastle/logs/ under the clone.
    });
  } finally {
    for (const [k, v] of Object.entries(HOST_ENV_BEFORE)) {
      if (v === undefined) delete process.env[k]; else process.env[k] = v;
    }
  }

  console.log(`\n--- #${issue.number} finished ---`);
  console.log(`  branch   ${result.branch}`);
  console.log(`  commits  ${result.commits.length}`);
  console.log(`  signal   ${result.completionSignal ?? "(none: it did not say COMPLETE)"}`);
  for (const [n, it] of result.iterations.entries()) {
    if (!it.usage) continue;
    const u = it.usage;
    console.log(`  tokens   #${n + 1}  in ${u.inputTokens}  out ${u.outputTokens}` +
                `  cache(write ${u.cacheCreationInputTokens} / read ${u.cacheReadInputTokens})`);
  }
  if (result.logFilePath) console.log(`  log      ${result.logFilePath}`);

  if (!result.commits.length) {
    console.log("\nNo commits. Read the issue comment: it either had nothing to do or it is blocked.");
    return "no commits";
  }

  // PUSH AND OPEN A DRAFT PR, AND STILL NEVER MERGE. A draft is the honest state for work no human has
  // read yet: the user marks it ready, and the user merges.
  execFileSync("git", ["push", "origin", branch], { cwd: SANDCASTLE_REPO, stdio: "inherit" });

  const emitted = typeof result.output === "string" ? result.output.trim() : "";
  const [titleLine, ...bodyLines] = emitted.split("\n");
  const prTitle = titleLine.replace(/^#+\s*/, "").trim() || `${issue.title} (#${issue.number})`;
  const prBody = `${bodyLines.join("\n").trim()}\n\nCloses #${issue.number}\n\n` +
                 `🤖 Generated with [Claude Code](https://claude.com/claude-code)`;

  if (plan.rework) {
    // The PR already exists: the push updated it. Record the rework as a PR comment, hand the issue
    // back to the user. ⚠️ UNTESTED as of 2026-10-21: no rework has run yet.
    gh(["pr", "comment", String(plan.rework.number), "--repo", GITHUB_REPO, "--body",
        emitted ? `Rework pushed.\n\n${emitted}` : "Rework pushed; the agent emitted no <pr-body>."]);
    gh(["issue", "edit", String(issue.number), "--repo", GITHUB_REPO,
        "--remove-label", LABEL_REWORK, "--add-label", LABEL_REVIEW]);
    console.log(`\n  updated draft PR  ${plan.rework.url}\n  It is a DRAFT. You mark it ready. You merge.`);
    return `reworked ${plan.rework.url}`;
  }

  if (!emitted) {
    console.log(`\nPushed ${branch}, but the agent emitted no <pr-body>, even after a retry.`);
    console.log("  A PR body is a claim about what was done, so it is not mine to invent. Open it yourself:");
    console.log(`    gh pr create --repo ${GITHUB_REPO} --draft --head ${branch} --base ${BASE_BRANCH} --title "<why, in one line>"`);
    return "pushed, no PR body";
  }

  const prUrl = gh(["pr", "create", "--repo", GITHUB_REPO, "--draft", "--head", branch, "--base", BASE_BRANCH,
                    "--title", prTitle, "--body", prBody]).trim();
  try { gh(["issue", "edit", String(issue.number), "--repo", GITHUB_REPO, "--add-label", LABEL_REVIEW]); }
  catch { console.error(`  warn: could not add \`${LABEL_REVIEW}\` to #${issue.number}`); }

  console.log(`\n  draft PR  ${prUrl}`);
  console.log(`
Read it against ${BASE_REF}: git -C "${SANDCASTLE_REPO}" diff ${BASE_REF}...${branch}
It is a DRAFT, and tested(container) at best: no device, no printer, no cloud, no Stripe.
You mark it ready. You merge.
`);
  return `draft PR ${prUrl}`;
}

// ---------------------------------------------------------------------------- 6. the two callers
const printRefusal = (r: Refusal) => {
  for (const line of r.why) (r.code === 0 ? console.log : console.error)(line);
};

async function runExplicit(n: number): Promise<never> {
  console.log(`\n=== sandcastle, explicit pick #${n}, ${new Date().toISOString()} ===`);
  cloneGate();
  dockerGate();
  fetchOrigin();
  const issue = fetchIssue(n);
  if (!issue || issue.pull_request) {
    console.error(`REFUSING TO START: #${n} is not an issue on ${GITHUB_REPO}.`);
    process.exit(3);
  }
  if (issue.state !== "open") { console.error(`REFUSING TO START: #${n} is ${issue.state}.`); process.exit(3); }
  if (!labelsOf(issue).includes(SANDCASTLE_LABEL)) {
    console.error(`REFUSING TO START: #${n} does not carry \`${SANDCASTLE_LABEL}\`: nobody has said it is fit for an unattended container.`);
    process.exit(3);
  }
  if (labelsOf(issue).includes(LABEL_HUMAN)) {
    console.error(`REFUSING TO START: #${n} carries \`${LABEL_HUMAN}\`: it needs your decision first (database, payment, a dependency, a seam).`);
    process.exit(3);
  }
  const plan = resolvePlan(issue, openSandcastlePrs());
  if ("why" in plan) { printRefusal(plan); process.exit(plan.code); }
  console.log(`  outcome  ${await launch(plan)}`);
  process.exit(0);
}

async function pass(attempted: Set<number>): Promise<string | null> {
  console.log(`\n=== sandcastle pass, ${new Date().toISOString()} ===`);
  cloneGate();
  dockerGate();
  fetchOrigin();

  const openPrs = openSandcastlePrs();
  const counted = [...openPrs.keys()].filter((n) => {
    const i = fetchIssue(n);
    return !(i && labelsOf(i).includes(LABEL_DEFERRED));
  });
  const capped = counted.length >= MAX_OPEN_PRS;
  console.log(`  backlog  ${counted.length} open ${BRANCH_PREFIX}* PR(s) awaiting review, cap ${MAX_OPEN_PRS}`);
  const waitingOnCap = `${counted.length} open PRs (${counted.map((n) => `#${n}`).join(", ")}); review one and the queue moves`;
  if (capped && !DRY_RUN) return waitingOnCap;

  const candidates = ghList<Issue>(`${REPO_API}/issues?state=open&labels=${LABELS.join(",")}&per_page=100`)
    .filter((i) => !i.pull_request)
    .sort((a, b) =>
      Number(labelsOf(b).includes(LABEL_NEXT_UP)) - Number(labelsOf(a).includes(LABEL_NEXT_UP)) ||
      a.number - b.number);

  const queue: Plan[] = [];
  const skipped: string[] = [];
  for (const i of candidates) {
    const skip = (why: string) => skipped.push(`#${i.number}  ${why}`);
    if (labelsOf(i).includes(LABEL_HUMAN)) { skip(`carries \`${LABEL_HUMAN}\`: yours to judge, not a container's`); continue; }
    if (attempted.has(i.number)) { skip("already launched by this loop and left no open PR; relaunch to retry"); continue; }
    const plan = resolvePlan(i, openPrs);
    if ("why" in plan) skip(plan.why[0].replace(`#${i.number} `, "")); else queue.push(plan);
  }

  console.log(`  queue    ${queue.length ? queue.map((p) => `#${p.issue.number}`).join(" -> ") : "(empty)"}` +
              `   [${LABELS.join(" + ")}, ${LABEL_NEXT_UP} first, then lowest #]`);
  for (const p of queue) console.log(`    #${p.issue.number}  ${p.issue.title}`);
  for (const s of skipped) console.log(`  skipped  ${s}`);

  if (DRY_RUN) {
    if (capped) console.log(`  waiting: ${waitingOnCap}`);
    if (queue.length) {
      console.log(`\n  ${capped ? "would run once the cap frees" : "would run"}: #${queue[0].issue.number}`);
      await launch(queue[0]);
    }
    console.log("\n--dry-run: ONE selection pass, then exit. The loop itself never started.");
    process.exit(0);
  }
  if (!queue.length) return `nothing eligible with [${LABELS.join(" + ")}]`;

  attempted.add(queue[0].issue.number);
  try {
    console.log(`  outcome  ${await launch(queue[0])}`);
  } catch (e) {
    console.error(`\n#${queue[0].issue.number} FAILED: ${(e as Error).message}`);
  }
  return null;
}

// Pass after pass, ONE container at a time: `launch` is awaited before the next pass begins. Ctrl+C
// between passes is a clean exit (nothing in flight); during a run the engine's own handler tears the
// container down.
async function loop(): Promise<never> {
  const attempted = new Set<number>();
  for (;;) {
    let waiting: string | null;
    try {
      waiting = await pass(attempted);
    } catch (e) {
      waiting = `a selection call failed (${(e as Error).message.split("\n")[0]})`;
    }
    if (waiting === null) continue;
    console.log(`  waiting: ${waiting}.`);
    console.log(`  Re-checking in ${WATCH_S} s. Ctrl+C exits cleanly; nothing is in flight.`);
    await new Promise((r) => setTimeout(r, WATCH_S * 1000));
  }
}

if (EXPLICIT_ISSUE !== undefined) await runExplicit(EXPLICIT_ISSUE);
else await loop();
