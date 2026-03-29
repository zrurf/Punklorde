# 畅课 Tronclass
> **AKA:** *学在重邮*

## 签到流程

### 雷达签到
雷达签到应该是最容易被破解的了，只需要将虚拟的坐标提交上去即可。

但是tronclass的雷达签到相当雷霆，不知道是哪个牛逼人写的，返回值里有`distance`字段，即提交的坐标点到签到中心点的距离。所以我们甚至不需要手动选点，直接随机提交两个点，然后用两圆相交法即可求出真正的签到点。

## 鸣谢
签到逻辑：[https://github.com/KrsMt-0113/XMU-Rollcall-Bot](https://github.com/KrsMt-0113/XMU-Rollcall-Bot)