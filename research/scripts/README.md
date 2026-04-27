# research/scripts

Operational scripts for the research execution.

## diagnose-server.sh

A read-only diagnostic that assesses a Linux GPU server's capability for LLM fine-tuning and inference workloads. Auto-detects Ubuntu/Debian vs Fedora/RHEL/Rocky/Alma. Single self-contained bash script.

### Safety

The script is **strictly read-only**:
- Does not install anything
- Does not modify any files
- Does not change any system configuration
- Only runs read-only queries (`nvidia-smi`, `lscpu`, `free`, `df`, `dpkg/rpm -q`, etc.)
- Python introspection is read-only (`python3 -c "import torch; print(...)"`)

Safe for any admin to run without authorization concerns. No root required (some sections show extra detail with sudo, but the script works fine without).

### Usage

```bash
# Run and save output
bash diagnose-server.sh > diagnostic-$(hostname)-$(date +%Y%m%d).txt 2>&1

# Or pipe to less for live viewing
bash diagnose-server.sh 2>&1 | less

# Or just see it on screen
bash diagnose-server.sh
```

The `2>&1` merges stderr into stdout so any errors from missing tools are captured in the output too. The output is plain text with markdown-style section headers.

### What it checks

15 sections covering:

1. **OS / kernel** — distribution, version, kernel, uptime
2. **Hardware: CPU & RAM** — cores, memory, NUMA topology
3. **Storage** — disk usage, mount points, NFS mounts, inodes
4. **NVIDIA GPU hardware** — GPU model, memory, NVLink, topology, running processes
5. **CUDA / cuDNN / NCCL / TensorRT** — toolkit versions, library locations
6. **Python environment** — interpreters, pip, conda
7. **ML/AI Python packages** — PyTorch, transformers, peft, bitsandbytes, vLLM, etc., with PyTorch+CUDA load-bearing test
8. **Network & Hugging Face Hub** — connectivity, DNS, HTTP reachability, cache config
9. **Useful tools** — git, tmux, htop, docker, etc.
10. **System limits & tuning** — ulimits, sysctl
11. **Currently running processes** — top memory/CPU consumers
12. **Distribution-specific package checks** — dpkg / rpm queries for NVIDIA/CUDA/Python packages
13. **Filesystem permissions** — common cache paths and writability
14. **Containerization** — Docker, Podman, Singularity, Apptainer, NVIDIA Container Toolkit
15. **Capability summary** — auto-detected assessment of what fine-tuning and inference workloads the hardware supports

### Sending output back

The output file can be pasted into a chat message, attached to an issue, or sent as text. Should be ~500-1500 lines depending on installed packages. Doesn't contain any sensitive data (no credentials, no private file contents) — but does contain hostname, username, and detailed system info, so review before posting publicly.

### What the capability summary tells you

Heuristic mapping of GPU count + memory to the LLM workloads supported:

| GPU configuration | Capability |
|-------------------|------------|
| 8× 80GB-class | Frontier scale (405B QLoRA, 70B full FT, 671B inference) |
| 2× 80GB-class | Strong dual-GPU (70B QLoRA + iteration headroom) |
| 1× 80GB-class | Single-GPU (70B QLoRA tight, 32B comfortable) |
| 1× 40-79GB-class | Mid-range (32B QLoRA, 13B QLoRA) |
| 1× 24-39GB-class | Dev-grade (13B QLoRA, 7B full FT) |
| 1× 12-23GB-class | Workstation (7B QLoRA, 3B full FT) |
| 1× <11GB or none | Dev only |

Run on the actual server to see which tier the hardware supports.
