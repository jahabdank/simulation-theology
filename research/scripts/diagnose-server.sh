#!/usr/bin/env bash
#
# diagnose-server.sh — capability assessment for a GPU server
#
# Purpose: produce a comprehensive read-only diagnostic of a Linux GPU server,
# so the requester can decide what fine-tuning / inference work the hardware
# can support for the Simulation Theology alignment-validation research (F-009).
#
# SAFETY: this script is strictly read-only. It does NOT install anything,
# does NOT modify any files, does NOT change any system configuration. It only
# runs read-only queries (nvidia-smi, lscpu, free, df, dpkg/rpm -q, etc.) and
# Python introspection (`python3 -c "import torch; ..."` — read-only).
#
# Auto-detects Ubuntu/Debian vs Fedora/RHEL/CentOS and runs the right package
# manager queries. Tested against Ubuntu 20.04/22.04/24.04, Debian 11/12,
# Fedora 38/39/40, RHEL 8/9, Rocky/AlmaLinux. Should work on any reasonable
# modern distro.
#
# Usage:
#   bash diagnose-server.sh > diagnostic-$(hostname)-$(date +%Y%m%d).txt 2>&1
#
# The "2>&1" merges stderr into stdout so any errors from missing tools are
# captured in the output too. The output file is plain text; section headers
# are markdown-style for easy reading.
#
# Run as any user — root not required. Some sections (NVLink, package lists)
# may show extra detail when run as root, but the script works fine without.
#

# Don't use `set -e` — we want the script to continue even when individual
# checks fail (e.g., a tool not installed). Don't use `set -u` either, since
# we deliberately probe environment variables that may be unset.

# -------- Helper functions ---------------------------------------------------

# Print a section header with markdown-style formatting.
section() {
    echo
    echo "================================================================"
    echo "## $1"
    echo "================================================================"
}

subsection() {
    echo
    echo "--- $1 ---"
}

# Run a command, gracefully handling its absence or failure.
# Args:
#   $1 — command (with arguments) as a string
#   $2 — optional description (defaults to the command)
try_run() {
    local cmd="$1"
    local desc="${2:-$cmd}"
    local first_word
    first_word=$(echo "$cmd" | awk '{print $1}')

    subsection "$desc"
    if command -v "$first_word" >/dev/null 2>&1; then
        # Use eval so we can pass complex commands with pipes, variable refs, etc.
        eval "$cmd" 2>&1 || echo "(command exited with non-zero status)"
    else
        echo "(command not found: $first_word)"
    fi
}

# Check if a Python package is importable, print version if yes.
# Args:
#   $1 — package import name
#   $2 — optional Python interpreter (default: python3)
check_python_pkg() {
    local pkg="$1"
    local pyexec="${2:-python3}"
    if command -v "$pyexec" >/dev/null 2>&1; then
        local result
        result=$("$pyexec" -c "
import importlib
try:
    m = importlib.import_module('$pkg')
    v = getattr(m, '__version__', 'unknown version')
    print(f'  $pkg: {v}')
except ImportError:
    print(f'  $pkg: NOT INSTALLED')
except Exception as e:
    print(f'  $pkg: ERROR ({type(e).__name__}: {e})')
" 2>&1)
        echo "$result"
    fi
}

# -------- Header -------------------------------------------------------------

echo "================================================================"
echo "ST Alignment Research — GPU Server Capability Diagnostic"
echo "================================================================"
echo "Generated: $(date)"
echo "Hostname:  $(hostname 2>/dev/null || echo 'unknown')"
echo "User:      $(whoami)"
echo "Script:    $(realpath "$0" 2>/dev/null || echo "$0")"
echo

# -------- 1. OS / Kernel -----------------------------------------------------

section "1. Operating System & Kernel"

try_run "uname -a" "Kernel and architecture"
try_run "cat /etc/os-release" "OS distribution (os-release)"
try_run "lsb_release -a" "LSB release info (if available)"
try_run "uptime" "Uptime and load"

# Detect distro family for downstream package-manager queries.
DISTRO_FAMILY="unknown"
if [ -f /etc/debian_version ]; then
    DISTRO_FAMILY="debian"
elif [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ] || [ -f /etc/rocky-release ] || [ -f /etc/almalinux-release ]; then
    DISTRO_FAMILY="redhat"
fi

# Some modern distros use only /etc/os-release; check ID there too.
if [ "$DISTRO_FAMILY" = "unknown" ] && [ -f /etc/os-release ]; then
    . /etc/os-release 2>/dev/null
    case "${ID_LIKE:-${ID:-}}" in
        *debian*|*ubuntu*) DISTRO_FAMILY="debian" ;;
        *rhel*|*fedora*|*centos*|*rocky*|*alma*) DISTRO_FAMILY="redhat" ;;
    esac
fi

echo
echo "Detected distribution family: $DISTRO_FAMILY"

# -------- 2. Hardware: CPU & RAM ---------------------------------------------

section "2. Hardware: CPU & RAM"

try_run "lscpu" "CPU info"
try_run "nproc --all" "Total logical CPUs (threads)"
try_run "grep -c ^processor /proc/cpuinfo" "Logical processors (alternative)"
try_run "free -h" "Memory summary (human-readable)"
try_run "free -b | head -2" "Memory summary (bytes, for parsing)"
echo
subsection "NUMA topology (matters for multi-GPU NCCL performance)"
try_run "numactl --hardware" "NUMA hardware (if numactl installed)"
try_run "lscpu -e" "CPU layout extended"

# -------- 3. Storage ---------------------------------------------------------

section "3. Storage"

try_run "df -hT" "Disk usage (all mounted filesystems, with type)"
echo
subsection "Filesystem free-space spotlight (where models / training data live)"
for mnt in / /home /tmp /opt /data /scratch /mnt /workspace; do
    if [ -d "$mnt" ]; then
        df -h "$mnt" 2>/dev/null | tail -1 | awk -v m="$mnt" '{printf "  %-15s  %s available out of %s (%s used)\n", m, $4, $2, $5}'
    fi
done

try_run "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE" "Block devices"
try_run "df -i" "Inode usage (training jobs can fill inodes)"
echo
subsection "NFS / network filesystem mounts"
mount 2>/dev/null | grep -E '(nfs|cifs|sshfs|fuse)' || echo "  (no network filesystems found)"

# -------- 4. NVIDIA GPU Hardware ---------------------------------------------

section "4. NVIDIA GPU Hardware"

if command -v nvidia-smi >/dev/null 2>&1; then
    try_run "nvidia-smi" "GPU status (full)"
    try_run "nvidia-smi -L" "GPU list with UUIDs"
    try_run "nvidia-smi --query-gpu=index,name,memory.total,memory.free,memory.used,driver_version,compute_cap,utilization.gpu,temperature.gpu,power.draw,power.limit --format=csv" "GPU summary CSV"
    try_run "nvidia-smi -q -d MEMORY,UTILIZATION,TEMPERATURE,POWER,CLOCK,COMPUTE,PIDS,SUPPORTED_CLOCKS,PERFORMANCE" "Detailed GPU query"
    try_run "nvidia-smi topo --matrix" "GPU topology (NVLink / PCIe paths between GPUs)"
    try_run "nvidia-smi nvlink --status" "NVLink status (per-GPU)"
    try_run "nvidia-smi nvlink --capabilities" "NVLink capabilities"
    echo
    subsection "Currently running GPU compute applications"
    nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv 2>/dev/null || echo "  (no compute apps running, or query unsupported)"
    echo
    subsection "GPU persistence mode (affects performance startup latency)"
    nvidia-smi -q | grep -A1 "Persistence Mode" 2>/dev/null | head -20
else
    echo "  ⚠ nvidia-smi NOT FOUND — no NVIDIA GPU drivers detected."
    echo "  Either: (a) no NVIDIA GPU on this host, (b) drivers not installed,"
    echo "  or (c) drivers installed but /usr/bin/nvidia-smi not in PATH."
fi

# -------- 5. CUDA / cuDNN / NCCL / TensorRT ---------------------------------

section "5. CUDA Toolkit / cuDNN / NCCL / TensorRT"

try_run "nvcc --version" "CUDA compiler (nvcc) version"
echo
subsection "CUDA installation locations"
ls -la /usr/local/cuda* 2>/dev/null || echo "  (no /usr/local/cuda* found)"
echo
subsection "CUDA toolkit version (from version.txt or version.json)"
if [ -f /usr/local/cuda/version.txt ]; then
    cat /usr/local/cuda/version.txt
fi
if [ -f /usr/local/cuda/version.json ]; then
    cat /usr/local/cuda/version.json 2>/dev/null
fi
ls /usr/local/cuda*/version.* 2>/dev/null

echo
subsection "cuDNN version (header search)"
cudnn_headers=$(find /usr /opt -name "cudnn_version.h" 2>/dev/null)
if [ -n "$cudnn_headers" ]; then
    echo "$cudnn_headers" | while read -r f; do
        echo "Found: $f"
        grep -E "CUDNN_(MAJOR|MINOR|PATCHLEVEL)" "$f" 2>/dev/null
    done
else
    echo "  (cudnn_version.h not found in /usr or /opt)"
fi

echo
subsection "NCCL version (header search)"
nccl_headers=$(find /usr /opt -name "nccl.h" 2>/dev/null)
if [ -n "$nccl_headers" ]; then
    echo "$nccl_headers" | while read -r f; do
        echo "Found: $f"
        grep -E "NCCL_(MAJOR|MINOR|PATCH|VERSION_CODE)" "$f" 2>/dev/null | head -10
    done
else
    echo "  (nccl.h not found in /usr or /opt)"
fi

echo
subsection "TensorRT (header / library search)"
tensorrt_headers=$(find /usr /opt -name "NvInfer.h" 2>/dev/null | head -3)
if [ -n "$tensorrt_headers" ]; then
    echo "  TensorRT detected:"
    echo "$tensorrt_headers"
else
    echo "  (TensorRT not found)"
fi

try_run "ldconfig -p 2>/dev/null | grep -E 'cudnn|nccl|cublas|cusparse|cusolver' | head -20" "CUDA libraries in linker cache"

# -------- 6. Python Environment ---------------------------------------------

section "6. Python Environment"

subsection "Python interpreters available"
for v in python python3 python3.8 python3.9 python3.10 python3.11 python3.12 python3.13; do
    if command -v "$v" >/dev/null 2>&1; then
        echo "  $v: $(command -v "$v") — $($v --version 2>&1)"
    fi
done

try_run "python3 --version" "Default python3 version"
try_run "python3 -c 'import sys; print(sys.executable); print(sys.version); print(sys.prefix)'" "Default python3 details"
try_run "python3 -m pip --version" "pip version"
try_run "which conda mamba micromamba" "conda / mamba / micromamba locations"

if command -v conda >/dev/null 2>&1; then
    subsection "Conda environments"
    conda env list 2>&1 || true
fi

# -------- 7. ML/AI Python Packages ------------------------------------------

section "7. Key ML/AI Python Packages (in default python3)"

# Each package is checked individually so missing ones don't block the rest.
echo "Critical packages for fine-tuning + evaluation:"
for pkg in torch transformers accelerate peft trl bitsandbytes datasets evaluate; do
    check_python_pkg "$pkg"
done

echo
echo "Inference-optimization packages:"
for pkg in vllm flash_attn xformers triton; do
    check_python_pkg "$pkg"
done

echo
echo "Distributed-training and large-scale packages:"
for pkg in deepspeed fairscale torch_xla; do
    check_python_pkg "$pkg"
done

echo
echo "Experiment-tracking / dev-tools:"
for pkg in wandb tensorboard mlflow jupyter ipykernel; do
    check_python_pkg "$pkg"
done

echo
echo "Quantization-helpers:"
for pkg in auto_gptq optimum awq autoawq llama_cpp; do
    check_python_pkg "$pkg"
done

echo
subsection "PyTorch CUDA availability check (the load-bearing test)"
python3 - <<'PYEOF' 2>&1
try:
    import torch
    print(f'PyTorch version:    {torch.__version__}')
    print(f'CUDA available:     {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'CUDA version:       {torch.version.cuda}')
        print(f'cuDNN version:      {torch.backends.cudnn.version()}')
        print(f'GPU count:          {torch.cuda.device_count()}')
        print(f'NCCL available:     {torch.distributed.is_nccl_available()}')
        for i in range(torch.cuda.device_count()):
            props = torch.cuda.get_device_properties(i)
            print(f'  GPU {i}: {props.name}')
            print(f'    Total memory:        {props.total_memory / 1024**3:.2f} GB')
            print(f'    Compute capability:  {props.major}.{props.minor}')
            print(f'    Multi-processors:    {props.multi_processor_count}')
            print(f'    Memory-bus width:    {getattr(props, "memory_bus_width", "n/a")}')
    else:
        print('  PyTorch sees no CUDA devices. Either GPU not visible or drivers missing.')
except ImportError as e:
    print(f'PyTorch NOT INSTALLED in default python3: {e}')
except Exception as e:
    print(f'PyTorch CUDA check raised exception: {type(e).__name__}: {e}')
PYEOF

echo
subsection "bitsandbytes 4-bit quantization check (load-bearing for QLoRA)"
python3 - <<'PYEOF' 2>&1
try:
    import bitsandbytes
    print(f'bitsandbytes version: {bitsandbytes.__version__}')
    # bnb requires a CUDA context; check it can find GPU
    import torch
    if torch.cuda.is_available():
        # bnb >= 0.41 has a more robust check
        try:
            from bitsandbytes.nn import Linear4bit
            print('  Linear4bit class importable — 4-bit quantization should work.')
        except ImportError as e:
            print(f'  Linear4bit not importable: {e}')
    else:
        print('  CUDA unavailable — bnb installed but cannot run 4-bit ops.')
except ImportError:
    print('  bitsandbytes NOT INSTALLED — required for QLoRA 4-bit fine-tuning.')
except Exception as e:
    print(f'  bitsandbytes check raised: {type(e).__name__}: {e}')
PYEOF

# -------- 8. Network & Hugging Face Hub --------------------------------------

section "8. Network & Hugging Face Hub Access"

try_run "ip a 2>/dev/null | grep -E 'inet ' | grep -v '127.0.0.1'" "Network interfaces (non-loopback)"
try_run "ip route show default" "Default route"
echo
subsection "Connectivity tests (ping + HTTP)"
try_run "ping -c 2 -W 3 huggingface.co" "Hugging Face Hub ping"
try_run "ping -c 2 -W 3 download.pytorch.org" "PyTorch downloads ping"
try_run "ping -c 2 -W 3 github.com" "GitHub ping"

echo
subsection "HTTP reachability (status code)"
for host in huggingface.co github.com download.pytorch.org pypi.org; do
    if command -v curl >/dev/null 2>&1; then
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "https://$host" 2>/dev/null || echo "fail")
        echo "  https://$host → HTTP $code"
    fi
done

echo
subsection "DNS resolution"
try_run "getent hosts huggingface.co" "Resolve huggingface.co"

echo
subsection "Hugging Face cache environment"
echo "  HF_HOME:            ${HF_HOME:-(not set, defaults to ~/.cache/huggingface)}"
echo "  HF_HUB_CACHE:       ${HF_HUB_CACHE:-(not set)}"
echo "  TRANSFORMERS_CACHE: ${TRANSFORMERS_CACHE:-(not set)}"
echo "  HF_DATASETS_CACHE:  ${HF_DATASETS_CACHE:-(not set)}"

# Check the default cache directory
default_hf_cache="$HOME/.cache/huggingface"
if [ -d "$default_hf_cache" ]; then
    echo "  Default cache dir EXISTS: $default_hf_cache ($(du -sh "$default_hf_cache" 2>/dev/null | cut -f1) used)"
else
    echo "  Default cache dir does not exist yet: $default_hf_cache"
fi

# -------- 9. Useful Tools ----------------------------------------------------

section "9. Useful Tools (for ML workflows)"

for tool in git wget curl rsync tmux screen htop nvtop gpustat docker podman nvidia-docker singularity apptainer jupyter make gcc g++ openssh-server; do
    if command -v "$tool" >/dev/null 2>&1; then
        ver=$("$tool" --version 2>&1 | head -1 | tr -s ' ' || echo "")
        echo "  ✓ $tool: $(command -v "$tool")  ${ver:+($ver)}"
    else
        echo "  ✗ $tool: NOT INSTALLED"
    fi
done

# -------- 10. System Limits --------------------------------------------------

section "10. System Limits & Tuning"

try_run "ulimit -a" "Current user limits"
try_run "cat /proc/sys/fs/file-max" "Max open files (system-wide)"
try_run "sysctl vm.swappiness vm.overcommit_memory vm.overcommit_ratio kernel.shmmax 2>/dev/null" "VM tuning parameters"
try_run "cat /proc/sys/kernel/hostname" "Hostname (kernel)"

# -------- 11. Currently running processes -----------------------------------

section "11. Currently Running Processes (top consumers)"

subsection "Top 10 by memory"
ps aux --sort=-%mem 2>/dev/null | head -11

subsection "Top 10 by CPU"
ps aux --sort=-%cpu 2>/dev/null | head -11

# -------- 12. Distribution-Specific Package Checks --------------------------

section "12. Distribution-Specific Package Checks"

case "$DISTRO_FAMILY" in
    debian)
        echo "Detected Debian/Ubuntu — using dpkg"
        try_run "dpkg -l | grep -E '^ii' | grep -iE 'nvidia|cuda|cudnn|nccl|tensorrt' | head -40" "NVIDIA-related packages (dpkg)"
        try_run "dpkg -l | grep -iE 'python3?-(pip|venv|dev|distutils|setuptools|wheel)' | head" "Python dev packages"
        try_run "apt list --installed 2>/dev/null | grep -iE 'gcc|g\+\+|build-essential' | head" "Build tools"
        ;;
    redhat)
        echo "Detected RHEL/Fedora/Rocky/Alma — using rpm"
        try_run "rpm -qa | grep -iE 'nvidia|cuda|cudnn|nccl|tensorrt' | head -40" "NVIDIA-related packages (rpm)"
        try_run "rpm -qa | grep -iE 'python3?-(pip|virtualenv|devel|setuptools|wheel)' | head" "Python dev packages"
        try_run "rpm -qa | grep -iE 'gcc|gcc-c\+\+|make' | head" "Build tools"
        ;;
    *)
        echo "Unknown distribution family — skipping package manager checks."
        echo "Run 'cat /etc/os-release' to see the OS and request specific package queries."
        ;;
esac

# -------- 13. Filesystem permissions ----------------------------------------

section "13. Filesystem Permissions for Common Cache Paths"

for path in "$HOME" "$HOME/.cache" "$HOME/.cache/huggingface" "/tmp" "/scratch" "/data" "/opt" "/workspace" "/mnt"; do
    if [ -d "$path" ]; then
        perms=$(stat -c '%A' "$path" 2>/dev/null)
        owner=$(stat -c '%U:%G' "$path" 2>/dev/null)
        free=$(df -h "$path" 2>/dev/null | tail -1 | awk '{print $4}')
        writable=$(test -w "$path" && echo "writable" || echo "NOT writable by current user")
        echo "  $path: $perms $owner — $free free — $writable"
    fi
done

# -------- 14. Containerization ----------------------------------------------

section "14. Containerization (Docker / Podman / Singularity / Apptainer)"

try_run "docker --version" "Docker"
try_run "docker info 2>&1 | head -25" "Docker config (if installed and running)"
try_run "podman --version" "Podman"
try_run "singularity --version" "Singularity"
try_run "apptainer --version" "Apptainer"
try_run "nvidia-container-cli --version" "NVIDIA Container CLI"
try_run "nvidia-container-cli info 2>&1 | head -25" "NVIDIA Container Toolkit info"

# -------- 15. Capability summary --------------------------------------------

section "15. Capability Summary (auto-detected)"

# Try to extract GPU count, model, and memory size for an automated summary.
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_COUNT=$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l)
    GPU_MODELS=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')
    # Memory in MiB, take the first GPU's value (assume homogeneous)
    GPU_MEM_MIB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    GPU_MEM_GB=$((${GPU_MEM_MIB:-0} / 1024))
else
    GPU_COUNT=0
    GPU_MODELS="(no GPUs detected)"
    GPU_MEM_GB=0
fi

# Total RAM in GB
TOTAL_RAM_GB=$(free -g 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "?")

# Total disk free space at /
FREE_DISK_GB=$(df -BG / 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G' || echo "?")

# CUDA / PyTorch availability
CUDA_AVAILABLE="unknown"
if command -v python3 >/dev/null 2>&1; then
    CUDA_AVAILABLE=$(python3 -c "import torch; print('yes' if torch.cuda.is_available() else 'no')" 2>/dev/null || echo "no PyTorch")
fi

cat <<SUMMARY

System summary:
  Distribution:    $DISTRO_FAMILY
  Total RAM:       ${TOTAL_RAM_GB} GB
  Free disk (/):   ${FREE_DISK_GB} GB
  GPU count:       $GPU_COUNT
  GPU model(s):    $GPU_MODELS
  GPU memory:      ${GPU_MEM_GB} GB per GPU
  PyTorch+CUDA:    $CUDA_AVAILABLE

Capability assessment for ST alignment-validation research (F-009):

SUMMARY

# Heuristic assessment based on GPU memory and count.
# Note on thresholds: nvidia-smi reports usable memory in MiB. A "12 GB" card
# typically reports ~12,000 MiB → 11 GB by integer division. We map nameplate
# tiers to slightly-lower observed values:
#   nameplate 80GB → observed ≥75 GB
#   nameplate 40GB → observed ≥39 GB
#   nameplate 24GB → observed ≥22 GB
#   nameplate 12GB → observed ≥11 GB
if [ "$GPU_COUNT" = "0" ]; then
    cat <<'NOGPU'
  ⚠ No GPUs detected. This server cannot support fine-tuning or efficient
    inference of large models. Useful for: data preparation, evaluation
    pipeline development against API-served models, lightweight tasks.
NOGPU
elif [ "$GPU_COUNT" -ge 8 ] && [ "$GPU_MEM_GB" -ge 75 ]; then
    cat <<'TIER2'
  ✓ Frontier-class cluster (≥8 GPUs ≥80GB-class each):
    Capable of: 405B QLoRA fine-tune, 70B full BF16 fine-tune, 671B inference (4-bit).
    Sufficient for F-009 Tier 2 (8× H200) headline experiments.
TIER2
elif [ "$GPU_COUNT" -ge 2 ] && [ "$GPU_MEM_GB" -ge 75 ]; then
    cat <<'TIER1A'
  ✓ Strong dual-GPU server (2× 80GB-class):
    Capable of: 70B QLoRA fine-tune (4-bit), 70B inference (4-bit), 32B full BF16,
    13B full fine-tune, comfortable iteration headroom.
    Sufficient for F-009 Tier 1 hardware iteration acceleration.
TIER1A
elif [ "$GPU_COUNT" -ge 1 ] && [ "$GPU_MEM_GB" -ge 75 ]; then
    cat <<'TIER1B'
  ✓ Single-GPU server (1× 80GB-class):
    Capable of: 70B QLoRA (tight), 32B QLoRA comfortable, 8B full fine-tune,
    fast 70B inference (4-bit).
    Sufficient for F-009 Tier 1 single-GPU work.
TIER1B
elif [ "$GPU_COUNT" -ge 1 ] && [ "$GPU_MEM_GB" -ge 39 ]; then
    cat <<'TIER1C'
  ✓ Mid-range single-GPU (1× 40-79GB-class):
    Capable of: 32B QLoRA (4-bit), 13B QLoRA, 7B full fine-tune,
    13B inference comfortable.
    Sufficient for F-009 Tier 1 partial work.
TIER1C
elif [ "$GPU_COUNT" -ge 1 ] && [ "$GPU_MEM_GB" -ge 22 ]; then
    cat <<'DEV1'
  ◐ Dev-grade single GPU (1× 24-39GB-class):
    Capable of: 13B QLoRA, 7B full fine-tune, 7B inference fast.
    Useful for F-009 US-1 dev environment + 7B step-change test
    (better than the A3500's 12GB-class).
DEV1
elif [ "$GPU_COUNT" -ge 1 ] && [ "$GPU_MEM_GB" -ge 11 ]; then
    cat <<'DEV2'
  ◐ Constrained single GPU (1× 12-23GB-class):
    Capable of: 7B QLoRA (4-bit), 7B inference (4-bit), 3B full fine-tune.
    Equivalent to F-009 US-1 A3500 dev environment scale.
DEV2
else
    cat <<'TINY'
  ⚠ Limited GPU memory (<11GB-class):
    Capable of: development only, very small models (3B and below).
    Not suitable for ST fine-tuning experiments at meaningful scale.
TINY
fi

cat <<'CLOSING'

For F-009 alignment-validation research, please share this output with
Josef. The diagnostic informs which tier the hardware can support and
which fine-tuning experiments are feasible without cloud spend.
CLOSING

echo
echo "================================================================"
echo "End of diagnostic — $(date)"
echo "================================================================"
