#!/usr/bin/env python3
"""Smoke test for the F-009 fine-tuning environment.

Exercises the full QLoRA path on a Qwen 2.5 (or compatible) model:
  1. Load tokenizer + model in NF4 4-bit (bitsandbytes)
  2. Forward pass + generate (sanity)
  3. Wrap with LoRA adapter (peft)
  4. Run a few SFT steps on synthetic data (trl)
  5. Save adapter, reload, verify

If this passes, the env is ready for real fine-tuning work at this scale.
Run with the `st-ft` conda env active.

Usage:
  python smoke-test-env.py                                 # default 0.5B
  python smoke-test-env.py --model Qwen/Qwen2.5-1.5B-Instruct
  python smoke-test-env.py --model Qwen/Qwen2.5-7B-Instruct
"""

import argparse
import time
import torch
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
)
from peft import (
    LoraConfig,
    get_peft_model,
    prepare_model_for_kbit_training,
    PeftModel,
)
from trl import SFTTrainer, SFTConfig
from datasets import Dataset


DEFAULT_MODEL = "Qwen/Qwen2.5-0.5B-Instruct"


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument(
        "--model", default=DEFAULT_MODEL,
        help=f"HF model ID to test (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--output-dir", default="/tmp/st-ft-smoke",
        help="Where to put the adapter checkpoint (default: /tmp/st-ft-smoke)",
    )
    args = parser.parse_args()

    MODEL = args.model
    OUTPUT_DIR = args.output_dir
    ADAPTER_DIR = f"{OUTPUT_DIR}/adapter"
    t0 = time.time()
    print("=" * 60)
    print("ST fine-tuning env smoke test")
    print("=" * 60)
    print(f"Model: {MODEL}")
    print()

    # 1. Load tokenizer + 4-bit model
    print("[1/5] Loading tokenizer + model (NF4 4-bit)...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    bnb = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
    )
    model = AutoModelForCausalLM.from_pretrained(
        MODEL,
        quantization_config=bnb,
        device_map="auto",
        dtype=torch.bfloat16,
    )
    print(
        f"  loaded in {time.time()-t0:.1f}s; "
        f"VRAM allocated: {torch.cuda.memory_allocated()/1e9:.2f} GB"
    )

    # 2. Forward pass / generate
    print("[2/5] Forward pass + generate...")
    prompt = "What is two plus two?"
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        out = model.generate(**inputs, max_new_tokens=20, do_sample=False)
    generated = tokenizer.decode(out[0], skip_special_tokens=True)
    print(f"  prompt : {prompt}")
    print(f"  output : {generated[:120]!r}")

    # 3. Wrap with LoRA
    print("[3/5] Adding LoRA adapter...")
    model = prepare_model_for_kbit_training(model)
    lora = LoraConfig(
        r=8,
        lora_alpha=16,
        target_modules=["q_proj", "v_proj"],
        lora_dropout=0.0,
        bias="none",
        task_type="CAUSAL_LM",
    )
    model = get_peft_model(model, lora)
    trainable, total = model.get_nb_trainable_parameters()
    print(
        f"  trainable: {trainable:,} / {total:,} "
        f"({100*trainable/total:.3f}%)"
    )

    # 4. Synthetic data + short SFT run
    print("[4/5] Running 10-step SFT on synthetic data...")
    pairs = [(1, 1), (2, 3), (4, 5), (7, 2), (6, 6),
             (3, 4), (8, 1), (9, 9), (5, 5), (2, 2)]
    samples = [
        {
            "text": (
                f"<|im_start|>user\nWhat is {a}+{b}?<|im_end|>\n"
                f"<|im_start|>assistant\n{a+b}<|im_end|>"
            )
        }
        for a, b in pairs
    ]
    ds = Dataset.from_list(samples)

    sft_config = SFTConfig(
        output_dir=OUTPUT_DIR,
        max_steps=10,
        per_device_train_batch_size=2,
        gradient_accumulation_steps=1,
        learning_rate=2e-4,
        bf16=True,
        logging_steps=2,
        save_strategy="no",
        report_to="none",
        max_length=128,
    )
    trainer = SFTTrainer(
        model=model,
        args=sft_config,
        train_dataset=ds,
        processing_class=tokenizer,
    )
    result = trainer.train()
    print(f"  final loss: {result.training_loss:.4f}")

    # 5. Save adapter, reload to verify
    print("[5/5] Save and reload adapter...")
    model.save_pretrained(ADAPTER_DIR)

    # Free current model before reloading
    del model, trainer
    torch.cuda.empty_cache()

    base = AutoModelForCausalLM.from_pretrained(
        MODEL,
        quantization_config=bnb,
        device_map="auto",
        dtype=torch.bfloat16,
    )
    _reloaded = PeftModel.from_pretrained(base, ADAPTER_DIR)
    print(f"  adapter saved to {ADAPTER_DIR} and reloaded successfully")

    # Final summary
    print()
    print("=" * 60)
    print(f"ALL CHECKS PASSED in {time.time()-t0:.1f}s total")
    print(f"Peak VRAM: {torch.cuda.max_memory_allocated()/1e9:.2f} GB")
    print("=" * 60)


if __name__ == "__main__":
    main()
