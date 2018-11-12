# zGameWare正在整理中尚未正式开源，敬请关注

# 什么是 zGameWare？

zGameWare是一款跨平台2d游戏的制作中间件，它内置了并行化和多线程渲染框架，100%兼容fpc+lazarus和delphi xe10.1.2及以上版本。

底层api支持各类渲染引擎，内置强大工具链，高级几何系统，导航网络，音频，核心规则，人工智能，大型资源包，内置跨平台ffmpeg支持

**渲染器支持**
- zGameWare内置软件渲染器，软件渲染器支持HPC服务器，跨平台
- h.264内置推流渲染器，渲染到服务器推流协议，跨平台，在HPC实现可编程视频推流，无需显卡支持
- PXL，asphyre的跨平台渲染库，https://sourceforge.net/projects/asphyre/
- GLScene，知名opengl库，http://glscene.sourceforge.net/wikka/
- vulkan，pascal圈最前沿的vulkan渲染引擎，https://github.com/BeRo1985/pasvulkan
- FMX，delphi XE内置的多平台渲染框架，https://www.embarcadero.com/
- LUX，来自日本的中山教授基于DelphiXE所开发的3d渲染库，https://github.com/LUXOPHIA/
- castle-engine，跨平台3d引擎，https://castle-engine.io/

**高级渲染支持**
- 2D-HDR，只支持glscene渲染库
- 跨平台影子效果支持
- 跨平台叠影效果支持
- 几何绘图支持（TPoly,TVec2List）
- 多线程渲染支持
- 并行化渲染支持
- 渲染池支持（面向UI的渲染技术）
- 粒子系统支持
- 序列帧系统支持

**音频引擎支持**
- bass，跨平台音频引擎库，http://www.un4seen.com/
- fmx，fmx内置的mediaplayer库，https://www.embarcadero.com/

**基础几何库**
- 常用2d算法库
- 常用3d算法库
- 常用2d几何相交检测库
- 2d凸包及凹包支持
- 2d绝对坐标系支持(TVecList)
- 2d尺度坐标系支持(TPoly)
- 纹理排序(Texture Atlas)

**游戏AI支持**
- pascal原生导航网络，并行化神经链条，路径优化决策
- 基于随机森林的复杂AI决策
- 基于KDTree的复杂AI决策

**光栅库**
- 内存光栅库技术（Alpha混合处理支持，灰度支持，并行化缩放，反走样缩放，抗锯齿处理）
- 内置序列帧光栅库
- 内置JpegLS无损压缩（支持，灰度，RGB，RGBA三种光栅压缩模式）

**数据**
- 内置支持ZDB数据库.OX格式
- 内置支持大规模文件包.OX格式
- zlib内置压缩
- BRRC梯度压缩
- deflate哈弗吗压缩
- coreCipher并行加解密库 https://github.com/PassByYou888/CoreCipher
- 中心数据库
- 服务器通讯系统 https://github.com/PassByYou888/ZServer4D

**物理**
- 角色运动支持
- 弹道运动支持
- 碰撞检测支持（**直接2d算法库即可**）
- **暂时不支持外部物理引擎**

**脚本系统**
- 脚本系统在系统工程非常坑，不内置具体脚本语言，建议自行做脚本系统开发，下列指出三个方向
- 脚本方向1，**THashTextEngine，数据块形式的脚本系统**，强烈建议使用该模式制作游戏需要的脚本，易于开发和维护
- 脚本方向2，**Json，Json格式形式的脚本系统**，强烈建议使用该模式制作游戏需要的脚本，易于开发和维护
- 脚本方向3，**zExpression，表达式形式的脚本系统**，强烈建议使用该模式制作游戏需要的脚本，易于开发和维护
- **由于脚本引擎的技术技术陷阱实在太多了，不建议使用任何三方脚本引擎**

**工具链**
- 序列帧工具（支持从淘宝购买的大部分动画资源驱动）
- Photoshop分层展开器（基于Photoshop的UI设计到引擎驱动）
- 游戏UI布局设计器
- 光栅纹理转换工具
- 大批量文件打包工具
- 跨平台字体生成器
- 纹理打包排序工具(Texture Atlas)
- Sepia色彩空间系批量处理工具
- 色差均衡批化量处理工具
- 抗锯齿批量处理工具
- Tile地图编辑器（素材资源来自Warcaft3）
- Brush地图编辑器（素材资源来自魔兽世界）
- 部分从淘宝可购买的素材转换工具
- 反走样字体生成工具
- 2d骨骼动画工具

**技术文档**
- FMX渲染器的优化指南
- GLscene渲染器的优化指南
- bass部署指南
- HDR对于画质的神奇提升
- 多线程后台渲染技术指南

**示范游戏**

无