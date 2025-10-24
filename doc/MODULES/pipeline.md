# 流水线设计说明

## 概览
- 五级流水线CPU，包含IF、ID、EX、MEM、WB五个阶段

## 流水控制
- 详见[流水级间接口说明](../INTERFACE.md#流水级间接口说明)

## 部分操作码说明
```verilog
assign load_op = {inst_st_w, inst_st_h, inst_st_b, inst_ld_hu, inst_ld_bu, inst_ld_w, inst_ld_h, inst_ld_b};
```

## 特殊行为说明

### 乘除法器
- 乘除法器的计算结果不参与旁路。在ID级设置信号mul_div_hazzard，该信号拉高表示读取未写回的乘除法结果，此时应该进行阻塞等待。