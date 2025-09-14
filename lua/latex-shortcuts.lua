-- Function to expand shortcuts in LaTeX files owo!
-- when you press ';al' it will expand to '\alpha' in insert mode, only in LaTeX files
-- when you press ';;en' it will expand to a LaTeX enumerate environment etc
function latex_shortcuts()
  local shortcuts = {
    al = "\\alpha",
    be = "\\beta",
    de = "\\delta",
    et = "\\eta",
    ep = "\\epsilon",
    vep = "\\varepsilon",
    ga = "\\gamma",
    la = "\\lambda",
    mu = "\\mu",
    nu = "\\nu",
    om = "\\omega",
    ph = "\\phi",
    vph = "\\varphi",
    ps = "\\psi",
    pi = "\\pi",
    rh = "\\rho",
    si = "\\sigma",
    th = "\\theta",
    xi = "\\xi",
    ze = "\\zeta",

    Al = "\\Alpha",
    Be = "\\Beta",
    De = "\\Delta",
    Et = "\\Eta",
    Ep = "\\Epsilon",
    Ga = "\\Gamma",
    La = "\\Lambda",
    Mu = "\\Mu",
    Nu = "\\Nu",
    Om = "\\Omega",
    Ph = "\\Phi",
    Ps = "\\Psi",
    Pi = "\\Pi",
    Rh = "\\Rho",
    Si = "\\Sigma",
    Th = "\\Theta",
    Xi = "\\Xi",
    Ze = "\\Zeta",

    pt = "\\partial",
    xr = "\\xrightarrow{",
    --ar = "\\arrow[",
    arr =  "\\ar{r}",
    arl =  "\\ar{l}",
    aru =  "\\ar{u}",
    ard =  "\\ar{d}",
    arur = "\\ar{ur}",
    arul = "\\ar{ul}",
    ardr = "\\ar{dr}",
    ardl = "\\ar{dl}",
    Ra = "\\Rightarrow",
    La = "\\Leftarrow",
    ra = "\\rightarrow",
    lefta = "\\leftarrow",
    to = "\\to",
    lr = "\\leftrightarrow",
    Lr = "\\Leftrightarrow",
    sh = "\\sharp",
    se = "\\section{",
    sse = "\\subsection{",
    ssse = "\\subsubsection{", 
    bf = "\\textbf{",
    it = "\\textit{",
    un = "\\underline{",
    ti = "\\times",
    ot = "\\otimes",
    op = "\\oplus",
    mc = "\\mc", -- mathcal
    mf = "\\mf", -- mathfrak
    mb = "\\mb", -- mathbb
    mrm = "\\mathrm{",
    Hom = "\\Hom",
    mps = "\\mapsto",
    sum = "\\sum_{",
    pro = "\\prod_{",
    int = "\\int_{",
    sm = "\\sim",
    inf = "\\infty",
    emp = "\\emptyset",
    vnt = "\\varnothing",
    sbs = "\\subset",
    esbs = "\\subseteq",
    sps = "\\supset",
    esps = "\\supseteq",
  }

  for shortcut, expansion in pairs(shortcuts) do
    vim.api.nvim_set_keymap('i', ';' .. shortcut, expansion, { noremap = true, silent = true })
  end

  -- enumerate, itemize related
  vim.api.nvim_set_keymap('i', ';;en', 
    '\\begin{enumerate}\n\\item \n\\end{enumerate}<Esc>kA', 
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap('i', ';;it', 
    '\\begin{itemize}\n\\item \n\\end{itemize}<Esc>kA', 
    { noremap = true, silent = true }
  )
  vim.api.nvim_set_keymap('i', ';*', '\\item ', { noremap = true, silent = true })

  -- big brackets
  vim.api.nvim_set_keymap('i', ';(', 
    '\\left(  \\right)<Esc>Bi', 
    { noremap = true, silent = true }
  )

  -- aligning formula
  vim.api.nvim_set_keymap('i', ';;al', 
    '\\begin{align*}\n \n\\end{align*}<Esc>kA', 
    { noremap = true, silent = true }
  )

  -- aligning formula
  vim.api.nvim_set_keymap('i', ';;pm', 
    '\\begin{pmatrix}\n    & \\\\    & \n\\end{pmatrix}<Esc>kA', 
    { noremap = true, silent = true }
  )

  -- cases
  vim.api.nvim_set_keymap('i', ';;ca', 
    '\\begin{cases}\n\\item \n\\end{cases}<Esc>kA', 
    { noremap = true, silent = true }
  )

  -- definition, theorem, proposition, proof, example, remark
  vim.api.nvim_set_keymap('i', ';;de', 
    '\\begin{defn}\n \n\\end{defn}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;le', 
    '\\begin{lem}\n \n\\end{lem}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;th', 
    '\\begin{thm}\n \n\\end{thm}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;pp', 
    '\\begin{prop}\n \n\\end{prop}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;pf', 
    '\\begin{proof}\n \n\\end{proof}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;cor', 
    '\\begin{cor}\n \n\\end{cor}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;eg', 
    '\\begin{eg}\n \n\\end{eg}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;re', 
    '\\begin{rem}\n \n\\end{rem}<Esc>kA', 
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap('i', ';;ti', 
    '$$\\begin{tikzcd}\n \n\\end{tikzcd}$$<Esc>kA', 
    { noremap = true, silent = true }
  )

end

-- Set the autocmd to apply this only in LaTeX files
vim.api.nvim_exec([[
  augroup LaTeXShortcuts
    autocmd!
    autocmd FileType tex lua latex_shortcuts()
    autocmd FileType markdown lua latex_shortcuts()
  augroup END
]], false)
