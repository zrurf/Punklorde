# 项目架构

项目基于Flutter开发，同时使用Rust（基于FRB，Flutter Rust Bridge）和GO（基于CGO）完成了部分模块。

三者的关系是：`Flutter -> Rust -> GO`