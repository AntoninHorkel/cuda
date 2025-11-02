# Resources

- [Original cuda_ioctl_sniffer](https://github.com/geohot/cuda_ioctl_sniffer)
- [Forked cuda_ioctl_sniffer](https://github.com/mdaiter/cuda_ioctl_sniffer)
- [YouTube: George Hotz | Programming | aside: nvidia open source kernel driver | geohot/cuda_ioctl_sniffer](https://youtu.be/oVUK1ychsb4?si=FGAL0LeAFF2tlBkj)
- [YouTube: George Hotz | Programming | aside: a look into NVIDIA open source drivers | part2 cuda_ioctl_sniffer](https://youtu.be/CE_72X3Wh_U?si=slEtN9drQIIeqpHg)

- <Dread onion url>/post/b2a0fc81f18dbd6f2068

## Cubin

- [NVidia sass disassembler](https://github.com/redplait/denvdis) ([DeepWiki](https://deepwiki.com/redplait/denvdis) is helpfull)
- [Parser in LibreCuda](https://github.com/mikex86/LibreCuda/blob/7470f81a5c910c3b2c6e0088fb07d55338b5041d/driverapi/src/librecuda.cpp#L944-L1379)
- [Rust cudaparsers](https://github.com/VivekPanyam/cudaparsers)
- [Decoding CUDA Binary - File Format](https://zenodo.org/record/2339027/files/decoding-cuda-binary-file-format.pdf)
- [zhihu](https://zhuanlan.zhihu.com/p/1961519233591674250)
- [zhihu](https://zhuanlan.zhihu.com/p/13790390704)
- [fatbin zhihu](https://zhuanlan.zhihu.com/p/29424681490)

## Kernels

- [Memcpy kernels in LibreCuda](https://github.com/mikex86/LibreCuda/blob/master/driverapi/kernels/memcpy/memcpy.cu)
- [GPU kernel in Zig](https://github.com/Snektron/shallenge/blob/cb8fdb4b89068b1d542cecbdd2f082fb3019385c/src/main.zig#L70-L100)

Build kernel.zig for sm_80 GPU:
`zig build-lib -dynamic -target nvptx64-cuda-none -mcpu sm_80 -femit-asm -fno-emit-bin -fno-ubsan-rt kernel.zig`

# TODO

- [ ] Base driver connection, story points: 2/5
- [ ] Cubin and fatbin (ELF) parser, story points: 4/5
- [ ] Submit kernels to cmd queue and launch, story points: 4/5
- [ ] CLI argument parser, story points: 2/5
- [ ] C API bindings, story points: 1/5
- [ ] Helper cubin kernels (memcpy...), story points: 2/5
- [ ] Docs, story points: 5/5
- [ ] Kernel pipeline similar to rendergrapth
