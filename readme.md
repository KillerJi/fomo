# fomo3d_contract

## contract

dev endpoint: `http://18.180.227.173:8545/`

### fomo3d `0x45Ee616978281b2222E0c24F40F25696bf171E0c`

**Function**

- key_init_price():查询第一把key的价格

- key_final_price():查询当前key的价格

- key_increasing_price():查询每一把key的增长价格间距

- rounds:查询回合轮数

- start_time(uint256):查询某一轮的开始时间
    * uint256: 回合轮数

- end_time(uint256):查询某一轮的结束时间
    * uint256: 回合轮数

- team(address, uint256): 查询用户阵容
    * address: 用户地址
    * uint256: 回合轮数
    > 0 队伍一 | 1 队伍二 | 2 队伍三

- setActionTime(uint256): 设置第一轮开始时间（只有owner可以设置）
    * uint256: 第一轮开始时间戳（s）

- nonceOf(address): 获取某个地址的nonce值
    * address: 输入地址

- vaultBuy(uint256, uint256 , address,): 用户使用bnb购买key
    * uint256: 购买数量
    * uint256: 阵容(取值：0 队伍一 | 1 队伍二 | 2 队伍三)
    * address: 邀请用户的地址

- vaultBuy(uint256, uint256 , address, uint256,
    address, uint8, bytes32, bytes32): 用户使用国库的余额购买key
    * uint256: 购买数量
    * uint256: 阵容
    * address: 购买用户的地址
    * uint256: 购买用户的nonce值
    * address: 邀请用户的地址
    * uint8: v
    * bytes32: r
    * bytes32: s

- claim(address, uint256, uint256, uint8, bytes32, bytes32) 用户提取余额
    * address: 用户地址
    * uint256: claim数量
    * uint256: 用户nonce值
    * uint8: v
    * bytes32: r
    * bytes32: s

**Event**

```solidity
event BuyKey(
        address account,
        uint256 bnbvalue,
        uint256 buy_num,
        Group team,
        uint256 rounds,
        Way buyway,(购买方式 取值0:Bnb  1:Vault)
        address invite_address
    );
event Claim(address account, uint256 claimvalue);
event SetActionTime(uint256 time);
```

