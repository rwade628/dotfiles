local M = {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && yarn install",
    config = function()
        vim.g.mkdp_auto_close = true
        vim.g.mkdp_open_to_the_world = false
        vim.g.mkdp_open_ip = "127.0.0.1"
        vim.g.mkdp_port = "8888"
        vim.g.mkdp_browser = "/Applications/Firefox.app"
        vim.g.mkdp_echo_preview_url = true
        vim.g.mkdp_page_title = "${name}"
    end,
}

return M
