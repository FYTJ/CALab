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
- 中断判断位于ID级，例外提交位于WB级。当WB级提交例外时，所有流水级(除WB)外的**ex_flush**信号全部拉高，此时所有流水级均被冲刷，同时WB级不进行写寄存器堆操作，**且ID级不进行写CSR操作**。
- **has_exception**信号表示当前级内发生了异常。该信号会随着流水级传递至WB，从而引发异常的处理逻辑。
- **this_flush**信号表示该级内指令将会被冲刷，因此不参与任何数据发送与接收，包括EX级调用乘除法器以及MEM级访存。
    - **this_flush**信号拉高的可能原因如下：
        - 该指令在上一级发生了异常，则传递到之后流水级就不应该进行执行
        - 该指令在当前级内发生了异常，同样不应参与执行
        - **该指令之后的指令发生了异常，则该指令将会被冲刷，因此不应参与执行**，此时虽然该指令未触发异常，但与异常指令同等看待
    - 应注意this_flush与has_exception的区别：**has_exception拉高，表明该指令触发了异常；this_flush拉高时，该指令可能出现在异常指令之后**。
- **next_flush**信号表示下一流水级内的指令将被冲刷。
- **特殊的逻辑复用：**虽然ertn指令并非一个异常，但在ID级将inst_ertn指令加入this_flush和has_exception逻辑中，其原因如下：
    - 当处理ertn指令时，CPU将跳回用户态进行执行，该行为和触发异常进入内核态的行为相似
    - 当出现ertn指令时，ertn指令之后的所有指令均需要被冲刷，并且将停止一切写寄存器和握手行为，该行为与触发异常时所需的冲刷控制相似