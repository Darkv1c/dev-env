-- Work profile plugins (JavaScript, TypeScript, Node.js)
-- Activate with: NVIM_PROFILE=work nvim

return {
	-- Treesitter parsers for React/Web development
	{
		"nvim-treesitter/nvim-treesitter",
		init = function()
			-- Register additional parsers for work profile
			-- core.lua's config will pick these up via vim.g.treesitter_extra_parsers
			vim.g.treesitter_extra_parsers = {
				"javascript", "typescript", "tsx",
				"html", "css", "scss",
				"json", "graphql", "vue",
			}
		end,
	},

	-- Auto close and rename HTML/JSX tags
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		ft = { "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "xml", "vue" },
		opts = {
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = true,
			},
		},
	},

	-- TypeScript/JavaScript LSP additional support
	{
		"pmizio/typescript-tools.nvim",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			require("typescript-tools").setup({
				capabilities = capabilities,
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

	-- React & Vue 3 snippets
	{
		"L3MON4D3/LuaSnip",
		config = function()
			local ls = require("luasnip")
			local s = ls.snippet
			local t = ls.text_node
			local i = ls.insert_node
			local f = ls.function_node

			-- Helper: get filename without extension for component name
			local function filename()
				return f(function()
					local name = vim.fn.expand("%:t:r")
					return name ~= "" and name or "Component"
				end)
			end

			-- ── React (tsx/jsx) ──────────────────────────────────────
			local react_snippets = {
				-- Functional component (arrow)
				s("rfc", {
					t("export default function "), filename(), t({ "(props) {", "\treturn (", "\t\t<div>" }),
					i(1, "content"),
					t({ "</div>", "\t);", "}" }),
				}),

				-- Functional component with arrow function
				s("rafce", {
					t("const "), filename(), t({ " = () => {", "\treturn (", "\t\t<div>" }),
					i(1, "content"),
					t({ "</div>", "\t);", "};", "", "export default " }), filename(), t(";"),
				}),

				-- useState
				s("us", {
					t("const ["), i(1, "state"), t(", set"),
					f(function(args)
						local name = args[1][1] or ""
						return name:sub(1, 1):upper() .. name:sub(2)
					end, { 1 }),
					t("] = useState("), i(2, "initial"), t(");"),
				}),

				-- useEffect
				s("ue", {
					t({ "useEffect(() => {", "\t" }),
					i(1),
					t({ "", "}, [" }),
					i(2),
					t({ "]);" }),
				}),

				-- useRef
				s("ur", {
					t("const "), i(1, "ref"), t(" = useRef("), i(2, "null"), t(");"),
				}),

				-- useMemo
				s("um", {
					t("const "), i(1, "value"), t({ " = useMemo(() => {", "\treturn " }),
					i(2),
					t({ ";", "}, [" }),
					i(3),
					t({ "]);" }),
				}),

				-- useCallback
				s("ucb", {
					t("const "), i(1, "fn"), t({ " = useCallback((" }),
					i(2),
					t({ ") => {", "\t" }),
					i(3),
					t({ "", "}, [" }),
					i(4),
					t({ "]);" }),
				}),

				-- useContext
				s("uctx", {
					t("const "), i(1, "value"), t(" = useContext("), i(2, "Context"), t(");"),
				}),

				-- Import React
				s("imr", {
					t("import { "), i(1), t(" } from 'react';"),
				}),
			}

			-- ── Vue 3 (vue) ──────────────────────────────────────────
			local vue_snippets = {
				-- SFC setup (script + template + style)
				s("vbase", {
					t({ '<script setup lang="ts">', "" }),
					i(1),
					t({ "", "</script>", "", "<template>", "\t<div>" }),
					i(2, "content"),
					t({ "</div>", "</template>", "", '<style scoped>', "" }),
					i(3),
					t({ "", "</style>" }),
				}),

				-- script setup block
				s("vscript", {
					t({ '<script setup lang="ts">', "" }),
					i(1),
					t({ "", "</script>" }),
				}),

				-- ref
				s("vref", {
					t("const "), i(1, "name"), t(" = ref("), i(2, "initial"), t(");"),
				}),

				-- reactive
				s("vreactive", {
					t("const "), i(1, "state"), t({ " = reactive({", "\t" }),
					i(2),
					t({ "", "});" }),
				}),

				-- computed
				s("vcomputed", {
					t("const "), i(1, "value"), t({ " = computed(() => {", "\treturn " }),
					i(2),
					t({ ";", "});" }),
				}),

				-- watch
				s("vwatch", {
					t("watch("), i(1, "source"), t({ ", (newVal, oldVal) => {", "\t" }),
					i(2),
					t({ "", "});" }),
				}),

				-- watchEffect
				s("vwatcheffect", {
					t({ "watchEffect(() => {", "\t" }),
					i(1),
					t({ "", "});" }),
				}),

				-- onMounted
				s("vmounted", {
					t({ "onMounted(() => {", "\t" }),
					i(1),
					t({ "", "});" }),
				}),

				-- defineProps
				s("vprops", {
					t("const props = defineProps<{"), i(1), t({ "}>();" }),
				}),

				-- defineEmits
				s("vemits", {
					t("const emit = defineEmits<{"), i(1), t({ "}>();" }),
				}),

				-- Vue imports
				s("vimport", {
					t("import { "), i(1), t(" } from 'vue';"),
				}),
			}

			ls.add_snippets("typescriptreact", react_snippets)
			ls.add_snippets("javascriptreact", react_snippets)
			ls.add_snippets("typescript", react_snippets)
			ls.add_snippets("javascript", react_snippets)
			ls.add_snippets("vue", vue_snippets)
		end,
	},

	-- Mason + LSP: ensure React/Web servers and formatters are installed
	{
		"neovim/nvim-lspconfig",
		init = function()
			-- Register extra LSP servers for work profile
			vim.g.mason_extra_servers = { "eslint", "tailwindcss", "jsonls" }
			-- Register extra formatters/tools for work profile
			vim.g.mason_extra_tools = { "prettierd" }
		end,
	},
}
