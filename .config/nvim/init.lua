-- [[ Leader Key ]]
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.relativenumber = true
vim.opt.laststatus = 0
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- [[ Lazy.nvim Bootstrap ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- [[ Plugins ]]
-- Load plugins based on NVIM_PROFILE environment variable
local profile = vim.env.NVIM_PROFILE or "default"

local profile_imports = {
	default = {
		{ import = "plugins.core" },
	},
	study = {
		{ import = "plugins.core" },
		{ import = "plugins.study" },
	},
	work = {
		{ import = "plugins.core" },
		{ import = "plugins.work" },
	},
}

require("lazy").setup(profile_imports[profile] or profile_imports.default)

-- [[ UI Settings ]]
vim.opt.termguicolors = true -- Enable 24-bit RGB colors
vim.cmd("colorscheme lunaperche")
vim.opt.fillchars:append({ vert = "▏" }) -- Delgada ▏ o cambia por "│"
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#3b4261", bg = "NONE" })

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })

-- Line numbers golden lunaperche style
vim.api.nvim_set_hl(0, "LineNr", { fg = "#FFFFFF" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#FFD700" })

-- [[ General Options ]]
vim.o.number = true
vim.o.relativenumber = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.list = true
vim.o.confirm = true
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99 -- Start with all folds open

-- Sync clipboard after UIEnter to reduce startup time
vim.api.nvim_create_autocmd("UIEnter", {
	callback = function()
		vim.o.clipboard = "unnamedplus"
	end,
})

-- [[ Keymaps ]]
vim.keymap.set("t", "<leader><Esc>", "<C-\\><C-n>")
-- Window navigation
vim.keymap.set("n", "<leader>h", "<C-w>h", { noremap = true })
vim.keymap.set("n", "<leader>j", "<C-w>j", { noremap = true })
vim.keymap.set("n", "<leader>k", "<C-w>k", { noremap = true })
vim.keymap.set("n", "<leader>l", "<C-w>l", { noremap = true })

-- Custom mappings
vim.keymap.set("n", "ñ", ";", { noremap = true })

-- Diagnostics (errors and warnings)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic message (float)" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic list (loclist)" })
vim.diagnostic.config({ virtual_text = true, virtual_lines = true })

-- Copilot keymaps (using Ctrl combos to avoid leader conflicts in insert mode)
vim.keymap.set("i", "<C-j>", "copilot#Accept()", {
	expr = true,
	silent = true,
	replace_keycodes = false,
	desc = "Accept Copilot suggestion",
})
vim.keymap.set("i", "<C-]>", "copilot#Next()", {
	expr = true,
	silent = true,
	replace_keycodes = false,
	desc = "Next Copilot suggestion",
})
vim.keymap.set("i", "<C-\\>", "copilot#Previous()", {
	expr = true,
	silent = true,
	replace_keycodes = false,
	desc = "Previous Copilot suggestion",
})

-- [[ Autocommands ]]
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	callback = function()
		vim.hl.on_yank()
	end,
})

local function telescope_lsp_picker(method, title, opts)
	local bufnr = opts and opts.bufnr or 0
	local params = vim.lsp.util.make_position_params(0, "utf-8")
	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = method })

	if opts and opts.params then
		params = vim.tbl_deep_extend("force", params, opts.params)
	end

	if vim.tbl_isempty(clients) then
		vim.notify("No LSP client supports " .. title, vim.log.levels.WARN)
		return
	end

	vim.lsp.buf_request_all(bufnr, method, params, vim.schedule_wrap(function(results)
		local seen = {}
		local items = {}

		for client_id, result in pairs(results) do
			local client = vim.lsp.get_client_by_id(client_id)
			local locations = result.result

			if locations then
				if not vim.islist(locations) then
					locations = { locations }
				end

				for _, location in ipairs(locations) do
					local uri = location.uri or location.targetUri
					local range = location.range or location.targetSelectionRange or location.targetRange

					if uri and range then
						local filename = vim.uri_to_fname(uri)
						local key = table.concat({
							filename,
							range.start.line,
							range.start.character,
							range["end"].line,
							range["end"].character,
						}, ":")

						if not seen[key] then
							seen[key] = true
							local text = location.text
							if not text and client then
								text = string.format("[%s]", client.name)
							end

							table.insert(items, {
								filename = filename,
								lnum = range.start.line + 1,
								col = range.start.character + 1,
								text = text or title,
							})
						end
					end
				end
			end
		end

		if opts and opts.filter then
			items = vim.tbl_filter(opts.filter, items)
		end

		if vim.tbl_isempty(items) then
			if opts and opts.fallback then
				return telescope_lsp_picker(opts.fallback.method, opts.fallback.title, {
					bufnr = bufnr,
					params = opts.fallback.params,
				})
			end

			vim.notify("No results for " .. title, vim.log.levels.INFO)
			return
		end

		table.sort(items, function(a, b)
			if a.filename ~= b.filename then
				return a.filename < b.filename
			end
			if a.lnum ~= b.lnum then
				return a.lnum < b.lnum
			end
			return a.col < b.col
		end)

		if #items == 1 then
			vim.cmd.edit(vim.fn.fnameescape(items[1].filename))
			vim.api.nvim_win_set_cursor(0, { items[1].lnum, items[1].col - 1 })
			return
		end

		vim.fn.setqflist({}, ' ', {
			title = title,
			items = items,
		})
		require('telescope.builtin').quickfix({})
	end))
end

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('LspAttach', { clear = false }),
	callback = function(event)
		local opts = { buffer = event.buf }
		-- Navigation
		vim.keymap.set('n', 'gd', function()
			telescope_lsp_picker('textDocument/definition', 'Definitions', { bufnr = event.buf })
		end, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to declaration' }))
		vim.keymap.set('n', 'gi', function()
			telescope_lsp_picker('textDocument/implementation', 'Implementations', {
				bufnr = event.buf,
				fallback = {
					method = 'textDocument/definition',
					title = 'Definitions',
				},
			})
		end, vim.tbl_extend('force', opts, { desc = 'Go to implementation' }))
		vim.keymap.set('n', 'gr', function()
			telescope_lsp_picker('textDocument/references', 'References', {
				bufnr = event.buf,
				params = { context = { includeDeclaration = false } },
				filter = function(item)
					return not (item.filename == vim.api.nvim_buf_get_name(0) and item.lnum == vim.fn.line('.'))
				end,
			})
		end, vim.tbl_extend('force', opts, { desc = 'Find references' }))
		vim.keymap.set('n', '<leader>D', function()
			telescope_lsp_picker('textDocument/typeDefinition', 'Type definitions', { bufnr = event.buf })
		end, vim.tbl_extend('force', opts, { desc = 'Go to type definition' }))
		-- Information
		vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
		vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
		vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
		-- Refactoring
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
		vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code actions' }))
		-- Symbols
		vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol, vim.tbl_extend('force', opts, { desc = 'Document symbols' }))
		vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, vim.tbl_extend('force', opts, { desc = 'Workspace symbols' }))
	end,
})

-- [[ User Commands ]]
vim.api.nvim_create_user_command("GitBlameLine", function()
	local line_number = vim.fn.line(".")
	local filename = vim.api.nvim_buf_get_name(0)
	print(vim.fn.system({ "git", "blame", "-L", line_number .. ",+1", filename }))
end, { desc = "Print the git blame for the current line" })

-- [[ Optional Packages ]]
vim.cmd("packadd! nohlsearch")
