# net 提供的状态查询命令
- print(net.getState())
- print(net.getMcc())
- print(net.getMnc())
- print(net.getLac())
- print(net.getCi())
- print(net.getRssi())
- print(net.getCell())
- print(net.getCellInfo())
- print(net.getCellInfoExt())
- print(net.getTa())
- print(net.getUserSocketSta())
- print(net.getCgatt())

# sim 提供的状态查询命令
- print(sim.geticcid())
- print(sim.getimsi())
- print(sim.getMcc())
- print(sim.getMnc())
- print(sim.getstatus())

# AT 指令支持
## 例如:
- sendat("AT+CSQ")