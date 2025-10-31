# 流水线设计说明

## 概览
- 五级流水线CPU，包含IF、ID、EX、MEM、WB五个阶段

## 流水控制
- 详见[流水级间接口说明](../INTERFACE.md#流水级间接口说明)

## 部分操作码说明
```verilog
assign mem_op = {inst_st_w, inst_st_h, inst_st_b, inst_ld_hu, inst_ld_bu, inst_ld_w, inst_ld_h, inst_ld_b};
```

## 部分行为说明

### 乘除法器
- 乘除法器的计算结果不参与旁路。在ID级设置信号mul_div_stall，该信号拉高表示读取未写回的乘除法结果，此时应该进行阻塞等待。

### CSR读写指令
- CSR的读取和写入指令均在ID阶段完成。
- CSR的读数据不参与旁路。在ID级设置信号csr_stall，信号含义与前者相同。

### 例外处理
- 当前支持例外包括：ADEF, ALE, SYS, BRK, INE, INT。具体含义和例外类型编码请参考[《龙芯架构参考手册 卷一：基础架构》](https://loongson.github.io/LoongArch-Documentation/README-CN.html)P115-116
- 中断判断位于ID级，例外提交位于WB级。当WB级提交例外时，所有流水级(除WB)外的**ex_flush**信号全部拉高，此时所有流水级均被冲刷，同时WB级不进行写寄存器操作。
- 对于带有**has_exception**标记的指令，不参与任何数据发送与接收，包括EX级调用乘除法器以及MEM级访存。