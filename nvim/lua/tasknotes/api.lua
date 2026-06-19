-- TaskNotes — HTTP client for the TaskNotes REST API.
-- All reads/writes go through config.api_url. Holds the TTL'd API caches
-- (filter-options + task paths) as module-level upvalues (singleton via require).

local config = require("tasknotes.config")

local M = {}

-- URL-encodes a path-as-id (vault-relative path with slashes and unicode).
-- The API uses the relative path as the resource id and expects it
-- percent-encoded (including the forward slashes between segments).
function M._encode_id(path)
	return (path:gsub("([^%w%-%._~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

function M.request(method, endpoint, params)
	local curl = require("plenary.curl")
	local url = config.api_url .. endpoint
	-- See M.health for rationale: `on_error` prevents plenary from
	-- raising error() from its libuv callback when curl exit code != 0.
	local options = {
		headers = {
			content_type = "application/json",
		},
		on_error = function() end,
	}

	local fn
	if method == "POST" then
		options.body = vim.fn.json_encode(params or {})
		fn = curl.post
	elseif method == "PUT" then
		options.body = vim.fn.json_encode(params or {})
		fn = curl.put
	elseif method == "DELETE" then
		fn = curl.delete
	else -- GET
		options.query = params
		fn = curl.get
	end

	local ok, res = pcall(fn, url, options)
	if not ok or not res or res.status ~= 200 or not res.body or res.body == "" then
		local code = (ok and res and res.status) or "no-response"
		vim.notify(
			string.format("TaskNotes API error (%s %s): %s", method, endpoint, tostring(code)),
			vim.log.levels.ERROR
		)
		return nil
	end
	local decoded_ok, decoded = pcall(vim.fn.json_decode, res.body)
	if not decoded_ok then
		vim.notify(string.format("TaskNotes API decode error (%s %s)", method, endpoint), vim.log.levels.ERROR)
		return nil
	end
	return decoded
end

function M.post(endpoint, body)
	return M.request("POST", endpoint, body)
end

function M.put(endpoint, body)
	return M.request("PUT", endpoint, body)
end

function M.get(endpoint, params)
	return M.request("GET", endpoint, params)
end

-- Health probe used at boot.
-- @return boolean true if /api/health responded with success
function M.health()
	local curl = require("plenary.curl")
	-- plenary's curl raises `error()` from its libuv on_exit callback when
	-- exit code != 0. That error escapes a wrapping pcall (different stack)
	-- and surfaces as "Lua callback" noise. Passing `on_error` neutralizes
	-- the throw; the curl call returns normally and we infer failure from
	-- the absent body / non-200 status.
	local ok, res = pcall(curl.get, config.api_url .. "/health", {
		timeout = 1500,
		on_error = function() end,
	})
	if not ok or not res or res.status ~= 200 or not res.body or res.body == "" then
		return false
	end
	local decoded_ok, decoded = pcall(vim.fn.json_decode, res.body)
	return decoded_ok and decoded and decoded.success == true or false
end

-- Returns the full task object for a given vault-relative path.
function M.get_task(id)
	local res = M.get("/tasks/" .. M._encode_id(id))
	if res and res.success then
		return res.data
	end
	return nil
end

-- Partial update via PUT /api/tasks/{id}. patch is a table with only the
-- fields to change (e.g. { status = "done" }).
-- @return updated task object or nil on failure
function M.update_task(id, patch)
	local res = M.put("/tasks/" .. M._encode_id(id), patch)
	if res and res.success then
		return res.data
	end
	return nil
end

function M.query_tasks(query)
	local res
	if query then
		res = M.post("/tasks/query", { query = query, limit = 1000 })
	else
		res = M.get("/tasks", { limit = 1000 })
	end

	if res and res.success and res.data and res.data.tasks then
		return res.data.tasks
	end
	return {}
end

-- ──────────────────────────────────────────────────────────────────────
-- API-backed caches (TTL'd, force-refresh via cache.force_refresh)
-- ──────────────────────────────────────────────────────────────────────

M._filter_options_cache = nil
M._task_paths_cache = nil

-- Fetches /api/filter-options (statuses, priorities, contexts, projects, tags).
-- @param force_refresh boolean: bypass TTL cache
-- @return table|nil { statuses, priorities, contexts, projects, tags } with rich metadata
function M.get_filter_options(force_refresh)
	if not force_refresh and M._filter_options_cache then
		if os.time() - M._filter_options_cache.fetched_at < 300 then
			return M._filter_options_cache.data
		end
	end
	local res = M.get("/filter-options")
	if res and res.success and res.data then
		M._filter_options_cache = { data = res.data, fetched_at = os.time() }
		return res.data
	end
	return nil
end

-- Returns a set { [vault_relative_path] = true } of all task paths in the vault.
-- Used to validate whether the current buffer is a task without touching the FS.
function M.get_task_paths(force_refresh)
	if not force_refresh and M._task_paths_cache then
		if os.time() - M._task_paths_cache.fetched_at < 60 then
			return M._task_paths_cache.set
		end
	end
	local tasks = M.query_tasks(nil) or {}
	local set = {}
	for _, t in ipairs(tasks) do
		if t.path then
			set[t.path] = true
		end
	end
	M._task_paths_cache = { set = set, fetched_at = os.time() }
	return set
end

function M.invalidate_caches()
	M._filter_options_cache = nil
	M._task_paths_cache = nil
end

return M
