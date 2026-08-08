# conda → uv

This setup is uv-only. No conda, no mamba, no pyenv, no `pip install --user`.
This page covers why, how to move an existing environment across, and how to
get rid of the old install once you're happy.

## The old machine, for reference

The 2022–2026 laptop carried an 11 GB `~/miniconda3` with ten environments:

| env | size | what it was for |
|---|---|---|
| `manim_py3.12` | 1.1 GB | animations |
| `microsim` | 967 MB | simulation |
| `huggingface` | 880 MB | transformers work |
| `ocselection` | 655 MB | |
| `UncertaintyIntro` | 647 MB | teaching material |
| `stim-i2k24` | 554 MB | I2K 2024 |
| `jupyterbook` | 488 MB | book builds |
| `manim` | 477 MB | older animations env |
| `pytorch` | 386 MB | |
| `py12` | 55 MB | scratch |

Nothing above is recreated automatically. The point of the move is to rebuild
only what you still use, on demand, in seconds.

## The translation table

| conda | uv |
|---|---|
| `conda create -n foo python=3.12` | `uv venv --python 3.12` (per project) |
| `conda activate foo` | `source .venv/bin/activate`, or just `uv run <cmd>` |
| `conda install numpy` | `uv add numpy` |
| `pip install numpy` | `uv add numpy` |
| `conda env export > env.yml` | `uv.lock` — already there, already exact |
| `conda env create -f env.yml` | `uv sync` |
| `conda install -c conda-forge jupyterlab` (globally) | `uv tool install jupyterlab` |
| a one-off run of a tool | `uvx ruff check .` — no install at all |
| `conda deactivate` | `deactivate`, or nothing if you used `uv run` |

The big conceptual shift: conda environments are *named things you switch
between*; uv environments are *a `.venv` directory belonging to a project*.
You stop activating and start running `uv run`.

## Starting a new project

```bash
uv init myproject && cd myproject
uv add numpy scipy matplotlib
uv run python analysis.py
```

`pyproject.toml` records what you asked for, `uv.lock` records exactly what you
got, both are committable, and `uv sync` reproduces it on any machine.

## Porting an environment you still need

On the old machine, get the list of what's actually installed at top level:

```bash
conda env export --from-history -n pytorch
```

`--from-history` matters: it lists what *you* asked for rather than the full
dependency closure, which is what you want to translate. Then, on the new
machine:

```bash
uv init pytorch-work && cd pytorch-work
uv add torch torchvision numpy    # whatever the export showed
```

For Jupyter, don't put the kernel in the project — install JupyterLab once as a
tool and let it find project environments:

```bash
uv tool install jupyterlab
uv add --dev ipykernel            # in the project
uv run ipython kernel install --user --name=myproject
```

### The one case that needs care

Packages that only exist on conda-forge with compiled non-Python dependencies
(some bioimaging and geospatial stacks). Check PyPI first — most have wheels
now. If one genuinely doesn't, that specific project is a reason to keep a
conda install *somewhere*, not to keep it as the default toolchain.

## Removing conda from a machine

Not done automatically, and not done to the old laptop — check first that
nothing you still depend on lives in there.

```bash
# 1. record what exists, in case you want it back
conda env list
for e in $(conda env list | awk 'NR>2 && $1 !~ /^#/ {print $1}'); do
  conda env export --from-history -n "$e" > "$HOME/conda-envs-backup-$e.yml"
done

# 2. remove the install (11 GB)
rm -rf ~/miniconda3 ~/.conda ~/.condarc

# 3. remove the init blocks from any shell rc that still has them
#    (this repo has none; check ~/.zshrc.local and ~/.bash_profile)
grep -rn "conda initialize" ~/.zshrc.local ~/.bash_profile ~/.profile 2>/dev/null
```

Step 3 is the one people forget: deleting the directory but leaving the
`conda initialize` block means every new shell spends time failing to find it.
