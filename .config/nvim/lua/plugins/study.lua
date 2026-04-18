-- Study profile plugins (Quarto, R, Scientific Python, Java)
-- Activate with: NVIM_PROFILE=study nvim

return {
	-- ── Java ────────────────────────────────────────────────────

	-- Treesitter: add Java parser
	{
		"nvim-treesitter/nvim-treesitter",
		init = function()
			local extra = vim.g.treesitter_extra_parsers or {}
			table.insert(extra, "java")
			vim.g.treesitter_extra_parsers = extra
		end,
	},

	-- Mason: ensure jdtls + java tools are installed
	{
		"neovim/nvim-lspconfig",
		init = function()
			-- Tell mason to install jdtls, but mark it as external so the
			-- default handler won't start it (nvim-jdtls does that).
			local servers = vim.g.mason_extra_servers or {}
			table.insert(servers, "jdtls")
			vim.g.mason_extra_servers = servers

			local external = vim.g.mason_external_servers or {}
			table.insert(external, "jdtls")
			vim.g.mason_external_servers = external

			local tools = vim.g.mason_extra_tools or {}
			vim.list_extend(tools, { "java-debug-adapter", "java-test", "google-java-format" })
			vim.g.mason_extra_tools = tools
		end,
	},

	-- nvim-dap (Debug Adapter Protocol)
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		keys = {
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "Debug continue" },
			{ "<leader>do", function() require("dap").step_over() end, desc = "Debug step over" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "Debug step into" },
			{ "<leader>du", function() require("dap").step_out() end, desc = "Debug step out" },
			{ "<leader>dr", function() require("dap").repl.open() end, desc = "Debug REPL" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "Debug terminate" },
		},
	},

	-- nvim-dap-ui (visual debugger)
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		keys = {
			{ "<leader>dU", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
		},
		config = function()
			local dapui = require("dapui")
			dapui.setup()
			local dap = require("dap")
			dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
			dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
			dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
		end,
	},

	-- nvim-jdtls (Java LSP + debug + test runner)
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
		dependencies = {
			"mfussenegger/nvim-dap",
			"williamboman/mason.nvim",
		},
		config = function()
			local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
			local jdtls_path = mason_path .. "/jdtls"

			-- Bail out if jdtls is not installed yet
			if vim.fn.isdirectory(jdtls_path) == 0 then
				vim.notify("jdtls not installed. Run :MasonInstall jdtls", vim.log.levels.WARN)
				return
			end

			-- Find the launcher jar
			local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

			-- Detect OS config folder
			local os_config = "linux"
			if vim.fn.has("mac") == 1 then
				os_config = "mac"
			elseif vim.fn.has("win32") == 1 then
				os_config = "win"
			end
			local config_path = jdtls_path .. "/config_" .. os_config

			-- Workspace directory (unique per project)
			local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
			local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

			-- Debug/test bundles
			local bundles = {}
			local java_debug_path = mason_path .. "/java-debug-adapter"
			if vim.fn.isdirectory(java_debug_path) == 1 then
				vim.list_extend(bundles, vim.split(
					vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
					"\n"
				))
			end
			local java_test_path = mason_path .. "/java-test"
			if vim.fn.isdirectory(java_test_path) == 1 then
				vim.list_extend(bundles, vim.split(
					vim.fn.glob(java_test_path .. "/extension/server/*.jar", true),
					"\n"
				))
			end

			-- Use Java 21 for jdtls (required), even if system default is different
			local java_21 = "/usr/lib/jvm/java-21-openjdk/bin/java"
			if vim.fn.executable(java_21) == 0 then
				vim.notify("Java 21 not found. Install with: sudo pacman -S jdk21-openjdk", vim.log.levels.ERROR)
				return
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local config = {
				cmd = {
					java_21,
					"-Declipse.application=org.eclipse.jdt.ls.core.id1",
					"-Dosgi.bundles.defaultStartLevel=4",
					"-Declipse.product=org.eclipse.jdt.ls.core.product",
					"-Dlog.protocol=true",
					"-Dlog.level=ALL",
					"-Xmx1g",
					"--add-modules=ALL-SYSTEM",
					"--add-opens", "java.base/java.util=ALL-UNNAMED",
					"--add-opens", "java.base/java.lang=ALL-UNNAMED",
					"-jar", launcher_jar,
					"-configuration", config_path,
					"-data", workspace_dir,
				},
				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
				capabilities = capabilities,
				settings = {
					java = {
						signatureHelp = { enabled = true },
						contentProvider = { preferred = "fernflower" },
						completion = {
							favoriteStaticMembers = {
								"org.hamcrest.MatcherAssert.assertThat",
								"org.hamcrest.Matchers.*",
								"org.hamcrest.CoreMatchers.*",
								"org.junit.jupiter.api.Assertions.*",
								"java.util.Objects.requireNonNull",
								"java.util.Objects.requireNonNullElse",
								"org.mockito.Mockito.*",
							},
							filteredTypes = {
								"com.sun.*",
								"io.micrometer.shaded.*",
								"java.awt.*",
								"jdk.*",
								"sun.*",
							},
						},
						sources = {
							organizeImports = {
								starThreshold = 9999,
								staticStarThreshold = 9999,
							},
						},
						codeGeneration = {
							toString = {
								template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
							},
							useBlocks = true,
						},
						configuration = {
							-- Add runtimes here if you have multiple JDKs
							-- runtimes = {
							-- 	{ name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk" },
							-- },
						},
					},
				},
				init_options = {
					bundles = bundles,
				},
				on_attach = function(_, bufnr)
					-- Enable jdtls-specific commands
					require("jdtls").setup_dap({ hotcodereplace = "auto" })
					require("jdtls.dap").setup_dap_main_class_configs()

					-- Java-specific keymaps
					local opts = { buffer = bufnr }
					vim.keymap.set("n", "<leader>jo", function() require("jdtls").organize_imports() end,
						vim.tbl_extend("force", opts, { desc = "Organize imports" }))
					vim.keymap.set("n", "<leader>jv", function() require("jdtls").extract_variable() end,
						vim.tbl_extend("force", opts, { desc = "Extract variable" }))
					vim.keymap.set("v", "<leader>jv", function() require("jdtls").extract_variable(true) end,
						vim.tbl_extend("force", opts, { desc = "Extract variable" }))
					vim.keymap.set("n", "<leader>jc", function() require("jdtls").extract_constant() end,
						vim.tbl_extend("force", opts, { desc = "Extract constant" }))
					vim.keymap.set("v", "<leader>jc", function() require("jdtls").extract_constant(true) end,
						vim.tbl_extend("force", opts, { desc = "Extract constant" }))
					vim.keymap.set("v", "<leader>jm", function() require("jdtls").extract_method(true) end,
						vim.tbl_extend("force", opts, { desc = "Extract method" }))
					vim.keymap.set("n", "<leader>jt", function() require("jdtls").test_nearest_method() end,
						vim.tbl_extend("force", opts, { desc = "Test nearest method" }))
					vim.keymap.set("n", "<leader>jT", function() require("jdtls").test_class() end,
						vim.tbl_extend("force", opts, { desc = "Test class" }))
				end,
			}

			-- Start jdtls when a Java file is opened
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					require("jdtls").start_or_attach(config)
				end,
			})
		end,
	},

	-- Conform: add google-java-format for Java
	{
		"stevearc/conform.nvim",
		ft = "java",
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters_by_ft.java = { "google-java-format" }
			return opts
		end,
	},

	-- ── Quarto / Scientific ─────────────────────────────────────

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

			-- Configure YAML indentation for QMD files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "quarto",
				callback = function()
					-- Specific configuration for YAML
					vim.bo.tabstop = 2
					vim.bo.shiftwidth = 2
					vim.bo.softtabstop = 2
					vim.bo.expandtab = true
					vim.bo.indentexpr = ""
					vim.bo.cindent = false
					vim.bo.smartindent = false
					vim.bo.autoindent = true
				end,
			})

			-- Keymap to preview Quarto document
			vim.keymap.set("n", "<leader>qp", function()
				require("quarto").quartoPreview({ args = "--port 3000" })
			end, { desc = "Quarto Preview" })
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
