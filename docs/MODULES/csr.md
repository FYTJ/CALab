# 控制状态寄存器(CSR)设计说明

## 接口说明

详见[控制状态寄存器(CSR)接口说明](../INTERFACE.md#控制状态寄存器(CSR)接口说明)

## 部分行为说明

- 当前实现了CRMD、PRMD、ECFG、ESTAT、ERA、BADV、EENTRY、SAVE0~3、TID、TCFG、TVAL、TICLR控制状态寄存器，对于CSR指令而言，读写方式与寄存器堆相同(同步写、异步读)。对于异常(含中断)的处理，与CPU有专门的数据和控制通路接口。
- 特别地，某些CSR目前用wire类型实现，具体原因请参见课程教科书。
- csr_tid_tid的初值、csr_estat_is[9:2]、csr_estat_is[12]目前暂时置为0。
- **当访问硬件未实现的CSR时，读动作返回全0，写动作不对寄存器产生任何影响**
