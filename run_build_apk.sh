#!/bin/bash

# --- 颜色定义 (让输出更好看) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 1. 参数检查 ---
BUILD_TYPE=$1

if [ -z "$BUILD_TYPE" ]; then
    echo -e "${RED}❌ 错误: 请指定构建类型 (release 或 debug)${NC}"
    echo "用法: ./run_build_apk.sh <release|debug>"
    exit 1
fi

echo -e "${YELLOW}🚀 开始构建 Flutter APK...${NC}"
echo "构建类型: $BUILD_TYPE"

# 使用 set -e 确保如果 flutter 命令出错，脚本会立即停止
set -e

if [ "$BUILD_TYPE" == "release" ]; then
    echo -e "${GREEN}▶ 正在执行 Release 打包 (包含详细日志)...${NC}"
    # Release 模式通常用于发版，建议加上 --verbose 查看日志
    flutter build apk --release --verbose
    
elif [ "$BUILD_TYPE" == "debug" ]; then
    echo -e "${GREEN}▶ 正在执行 Debug 打包...${NC}"
    flutter build apk --debug --verbose
    
else
    echo -e "${RED}❌ 错误: 未知的构建类型 '$BUILD_TYPE'${NC}"
    echo "用法: ./run_build_apk.sh <release|debug>"
    exit 1
fi

# 如果脚本能运行到这里，说明没有报错 (因为上面加了 set -e)
echo -e "${GREEN}✅ 构建成功!${NC}"