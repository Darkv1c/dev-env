-- Study profile plugins (Quarto, R, Scientific Python)
-- Activate with: NVIM_PROFILE=study nvim

return {
	-- Quarto support
	{
		"quarto-dev/quarto-nvim",
		ft = { "quarto", "markdown" },
		dependencies = {
			"jmbuhr/otter.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("quarto").setup({
				lspFeatures = {
					enabled = true,
					languages = { "r", "python", "julia", "bash" },
					diagnostics = {
						enabled = true,
						triggers = { "BufWritePost" },
					},
					completion = {
						enabled = true,
					},
				},
				codeRunner = {
					enabled = true,
					default_method = "molten",
				},
			})
		end,
	},

	-- Otter for embedded language support in markdown
	{
		"jmbuhr/otter.nvim",
		ft = { "quarto", "markdown" },
		config = function()
			require("otter").setup({})
		end,
	},

	-- Molten for Jupyter notebook integration
	{
		"benlubas/molten-nvim",
		ft = { "quarto", "markdown", "python" },
		build = ":UpdateRemotePlugins",
		init = function()
			vim.g.molten_image_provider = "image.nvim"
			vim.g.molten_output_win_max_height = 20
		end,
	},

	-- Image support for Molten
	{
		"3rd/image.nvim",
		ft = { "quarto", "markdown" },
		opts = {
			backend = "kitty",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
				},
			},
		},
	},
}
