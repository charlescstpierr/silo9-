from pathlib import Path
probe = Path('/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.cstack/orchestrate/silo9/issue10/geometry-review/review_probes.py')
code = probe.read_text().replace("/ 'proof-tools'", "/ 'proof-tools-initial'")
exec(compile(code, str(probe), 'exec'), {'__file__': str(probe), '__name__': '__main__'})
