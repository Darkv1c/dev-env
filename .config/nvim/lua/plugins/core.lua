return {
	-- cmd line
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			{
				"rcarriga/nvim-notify",
				opts = {
					background_colour = "#000000",
				},
			},
		},
		opts = {
			presets = {
				command_palette = true,
				bottom_search = false,
				long_message_to_split = true,
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
		},
	},
	
	-- Yazi: File Manager and Note-Taking
	{
		"mikavilpas/yazi.nvim",
		lazy = false,
		keys = {
			{
				"<leader>-",
				"<cmd>Yazi<cr>",
				desc = "Open yazi at the current file",
			},
			{
				"<leader>y",
				"<cmd>Yazi cwd<cr>",
				desc = "Open the file manager in nvim's working directory",
			},
		},
		opts = {
			open_for_directories = false,
		},
	},

	-- Cursor animation
	{
		"sphamba/smear-cursor.nvim",
		opts = {},
	},
	
	-- Treesitter (Syntax Highlighting, Indentation)
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})
			-- Install base parsers
			local parsers = { "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" }
			-- Merge extra parsers from profiles (e.g. work.lua sets vim.g.treesitter_extra_parsers)
			local extra = vim.g.treesitter_extra_parsers
			if extra then
				for _, p in ipairs(extra) do
					table.insert(parsers, p)
				end
			end
			require("nvim-treesitter").install(parsers)
			-- Enable treesitter highlighting for all supported filetypes
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},

	-- Autopairs
	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	
	-- Telescope (Finder)
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-tree/nvim-web-devicons", enabled = true },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					path_display = { "filename_first" },
					file_ignore_patterns = { "node_modules" },
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			})
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
		end,
	},

	-- LSP & Mason (Intelligence, Linters & Errors)
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			-- Setup Mason (The installer)
			require("mason").setup()
			-- Build ensure_installed list from base + profile extras
			local ensure_installed = { "lua_ls" }
			local extra_servers = vim.g.mason_extra_servers
			if extra_servers then
				for _, s in ipairs(extra_servers) do
					table.insert(ensure_installed, s)
				end
			end
			-- Setup Mason-LSPConfig (Automation)
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			-- Servers managed externally (e.g. nvim-jdtls manages jdtls)
			local external_servers = vim.g.mason_external_servers or {}
			require("mason-lspconfig").setup({
				ensure_installed = ensure_installed,
				handlers = {
					function(server_name)
						-- Skip servers managed by dedicated plugins
						for _, ext in ipairs(external_servers) do
							if server_name == ext then return end
						end
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end,
					["lua_ls"] = function()
						require("lspconfig").lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									diagnostics = { globals = { "vim" } },
								},
							},
						})
					end,
					["eslint"] = function()
						require("lspconfig").eslint.setup({
							capabilities = capabilities,
							on_attach = function(_, bufnr)
								vim.api.nvim_create_autocmd("BufWritePre", {
									buffer = bufnr,
									command = "EslintFixAll",
								})
							end,
						})
					end,
					["jsonls"] = function()
						require("lspconfig").jsonls.setup({
							capabilities = capabilities,
							settings = {
								json = {
									schemas = require("lspconfig").util.default_config
											and require("lspconfig").util.default_config.settings
											and require("lspconfig").util.default_config.settings.json
											and require("lspconfig").util.default_config.settings.json.schemas
										or {},
									validate = { enable = true },
								},
							},
						})
					end,
				},
			})
			-- Install formatters via Mason
			local ensure_tools = { "stylua" }
			local extra_tools = vim.g.mason_extra_tools
			if extra_tools then
				for _, t in ipairs(extra_tools) do
					table.insert(ensure_tools, t)
				end
			end
			local mr = require("mason-registry")
			for _, tool in ipairs(ensure_tools) do
				local p = mr.get_package(tool)
				if not p:is_installed() then
					p:install()
				end
			end
		end,
	},

	-- Autocompletion (Cmp)
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Disable Copilot ghost text when cmp menu is visible
			cmp.event:on("menu_opened", function()
				vim.b.copilot_suggestion_hidden = true
			end)
			cmp.event:on("menu_closed", function()
				vim.b.copilot_suggestion_hidden = false
			end)
		end,
	},

	-- Copilot
	{
		"github/copilot.vim",
		event = "InsertEnter",
		config = function()
			vim.g.copilot_no_tab_map = true -- Disable default Tab mapping
			vim.g.copilot_assume_mapped = true -- Assume Tab is already mapped
		end,
	},

	-- Opencode
	{
		"NickvanDyke/opencode.nvim",
		dependencies = {
			{ "folke/snacks.nvim", opts = { input = {}, picker = {} } },
		},
		config = function()
			vim.g.opencode_opts = {
				theme = "nord",
			}

			vim.opt.autoread = true

			-- Keymaps
			vim.keymap.set({ "n", "x" }, "<leader>oa",
				function() require("opencode").ask("@this: ", { submit = true }) end,
				{ desc = "Ask about this" })

			vim.keymap.set({ "n", "x" }, "<leader>os",
				function() require("opencode").select() end,
				{ desc = "Select prompt" })

			vim.keymap.set({ "n", "x" }, "<leader>o+",
				function() require("opencode").prompt("@this") end,
				{ desc = "Add this" })

			vim.keymap.set("n", "<leader>ot",
				function() require("opencode").toggle() end,
				{ desc = "Toggle embedded" })

			vim.keymap.set("n", "<leader>oc",
				function() require("opencode").command() end,
				{ desc = "Select command" })

			vim.keymap.set("n", "<leader>on",
				function() require("opencode").command("session_new") end,
				{ desc = "New session" })

			vim.keymap.set("n", "<leader>oi",
				function() require("opencode").command("session_interrupt") end,
				{ desc = "Interrupt session" })

			vim.keymap.set("n", "<leader>oA",
				function() require("opencode").command("agent_cycle") end,
				{ desc = "Cycle selected agent" })

			vim.keymap.set("n", "<S-C-u>",
				function() require("opencode").command("messages_half_page_up") end,
				{ desc = "Messages half page up" })

			vim.keymap.set("n", "<S-C-d>",
				function() require("opencode").command("messages_half_page_down") end,
				{ desc = "Messages half page down" })
		end,
	},

	-- Firenvim (Neovim in browser)
	{
		"glacambre/firenvim",
		lazy = not vim.g.started_by_firenvim,
		build = ":call firenvim#install(0)",
		config = function()
			vim.g.firenvim_config = {
				globalSettings = {
					alt = "all",
				},
				localSettings = {
					[".*"] = {
						cmdline = "neovim",
						content = "text",
						priority = 0,
						selector = "textarea",
						takeover = "never",
					},
				},
			}
		end,
	},

	-- Conform (Code Formatter)
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{
				"<leader>f",
				function() require("conform").format({ async = true, lsp_fallback = true }) end,
				mode = { "n", "v" },
				desc = "Format buffer with conform",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				jsonc = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				scss = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				vue = { "prettierd", "prettier", stop_after_first = true },
			},
			default_format_opts = {
				lsp_fallback = true,
			},
			format_on_save = function(bufnr)
				local ignore_filetypes = { "sql", "java" }
				if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
					return
				end
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		},
	},
}
