# 除法器设计说明

## 除法器接口说明
- 详见：[乘除法器接口说明](../INTERFACE.md#乘除法器接口说明)

## 部分行为说明
- **除0在LoongArch指令集中是未定义行为，在该除法器中采用了和risc-v相同的处理：商为0xFFFF_FFFF，余数与被除数相同**
- 除法器在CPU的EX、MEM两级同步进行计算，由EX级发送数据，MEM级接收结果。两级均需要等待握手完成才能进行数据传输。除法器在status=0(IDLE)时准备好接收数据；在status=1(BUSY)时进行计算，clk_count记录计算状态，当clk_count=32时计算完成，结果有效。

## 特殊说明
- Div.v由chisel elaborate生成，其中包含少量中间信号，源码位于`src/main/scala/divider.scala`