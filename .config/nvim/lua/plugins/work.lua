-- Work profile plugins (JavaScript, TypeScript, Node.js)
-- Activate with: NVIM_PROFILE=work nvim

return {
	-- TypeScript/JavaScript LSP additional support
	{
		"pmizio/typescript-tools.nvim",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("typescript-tools").setup({
				settings = {
					separate_diagnostic_server = true,
					publish_diagnostic_on = "insert_leave",
					tsserver_file_preferences = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
				},
			})
		end,
	},

	-- Package.json support
	{
		"vuki656/package-info.nvim",
		ft = "json",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			require("package-info").setup()
		end,
	},

	-- Prettier formatter
	{
		"stevearc/conform.nvim",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "css", "scss", "html" },
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters_by_ft.javascript = { "prettier" }
			opts.formatters_by_ft.javascriptreact = { "prettier" }
			opts.formatters_by_ft.typescript = { "prettier" }
			opts.formatters_by_ft.typescriptreact = { "prettier" }
			opts.formatters_by_ft.json = { "prettier" }
			opts.formatters_by_ft.jsonc = { "prettier" }
			opts.formatters_by_ft.css = { "prettier" }
			opts.formatters_by_ft.scss = { "prettier" }
			opts.formatters_by_ft.html = { "prettier" }
			return opts
		end,
	},

	-- ESLint integration
	{
		"neovim/nvim-lspconfig",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		opts = function()
			local lspconfig = require("lspconfig")
			lspconfig.eslint.setup({
				on_attach = function(_, bufnr)
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						command = "EslintFixAll",
					})
				end,
			})
		end,
	},

	-- Tailwind CSS support
	{
		"neovim/nvim-lspconfig",
		ft = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
		opts = function()
			local lspconfig = require("lspconfig")
			lspconfig.tailwindcss.setup({})
		end,
	},
}
