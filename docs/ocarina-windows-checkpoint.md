# Ocarina Windows shader checkpoint

This checkpoint restores native texture gather forms used by Ocarina and preserves proven per-tap offsets through predicated lowering. A captured compute shader previously emitted 24 gathers but lost constant offsets on eight of them; fresh lowering now retains offsets on all 24. Depth-comparison gathers, packed F16 results, LEA.HI subtraction and U32 surface reduction operations are also supported by the captured forms.

The Windows changes protect standard-library min/max calls from Windows macros. Sampled-texture frame capture support remains opt-in.

Validation performed:

- Windows x64 Release `yuzu` and `shader-sweep` targets built with clang-cl and 12 jobs.
- Two full native captures (630 and 626 files) pass native-to-Maxwell lowering.
- The four originally rejected shaders compile using their captured environments and pass `spirv-val --target-env vulkan1.2`.
- Negative local checks reject clobbered gather offsets, changed predicates and incoming control flow after offset definitions.

The game scene is visible in user testing. Brightness fluctuations and low sustained frame rate remain unresolved. A later timing capture shows a median 5.59 GiB/s of GPU buffer downloads during 21 steady-state windows; this is a performance lead, not a validated optimization. No change to buffer download or synchronization policy is included.

Start a low-overhead performance session from the repository root:

```powershell
.\tools\windows\run-oot-performance.ps1 -Profile
```

Logs are stored under `artifacts/oot-performance/`. Frame and native shader dumps are disabled by this launcher. Existing serialized shader cache records can still produce old PTP warnings at startup; corrected fresh lowering uses different runtime pipeline hashes.

This checkpoint includes ports of Lichii commits a4cc1e680f, 18e4efbbb8, 4435506c96 and 3df1a0e6aa on top of 35c043b3ef. It does not include later remote branch changes. Native instruction encoding references are Mesa NAK `sm70_encode.rs` and the existing Maxwell translator.
