#!/bin/bash

#
# 

Usage(){
    echo `basename $0` "[tarfile] [pack num]"
    echo "      [tarfile] : "
    echo "      [pack num]: "
    exit 1
}

print_env(){
    echo "TEMP_DIR: ${TEMP_DIR}"
    echo "PRIVATE_KEY: ${PRIVATE_KEY}"
    echo "ROOT_DIR: ${ROOT_DIR}"
    echo "SOURCE_DIR: ${SOURCE_DIR}"
    echo "PACK_NUM: ${PACK_NUM}"
    echo "MANIFEST: ${MANIFEST}"
    echo "VERSION:${VERSION}"
    echo "pseq=${pseq}"
    echo "OUTPUT_HEADER: ${OUTPUT_HEADER}"
    echo "OUTPUT_TAIL: ${OUTPUT_TAIL}"
}

OPENSSL=openssl
TEMP_DIR=${WORKSPACE}/tmp/pack_source
PRIVATE_KEY=OpenBMC.priv
ROOT_DIR=`dirname "${0}"`
SOURCE_DIR=""
PACK_NUM=3
MANIFEST="${TEMP_DIR}/MANIFEST"
VERSION=""
OUTPUT_HEADER=test
OUTPUT_TAIL=static.mtd.tar

# ==== check env ====
# openssl util
which ${OPENSSL} 1>/dev/null
if [ "$?" != "0" ];then
    echo "This program need openssl utils, please install..."
    echo "sudo apt install openssl"
    exit 1
fi
# private key
if [ ! -f "${ROOT_DIR}/${PRIVATE_KEY}" ];then
    echo "Cannot find private key: ${PRIVATE_KEY}"
    exit 1
fi
if [ ! -f "$1" ];then
    Usage
    exit 1
fi
# reset temp dir
if [ -e "${TEMP_DIR}" ];then
    rm -rf "${TEMP_DIR}"
fi
mkdir -p ${TEMP_DIR}
# untar
tar -xf "$1" -C "${TEMP_DIR}"
SOURCE_DIR=`dirname "$1"`
rm -f ${SOURCE_DIR}/${OUTPUT_HEADER}*

shift
if [ -n "$1" ];then
    PACK_NUM="$1"
fi
pseq=`seq -s " " 1 "$PACK_NUM"`
if [ "$?" != "0" ];then
    echo "[pack num] must be a number"
    Usage
    exit 1
fi
# solve relative path
cd ${ROOT_DIR}
ROOT_DIR=$(pwd)
cd - 1>/dev/null
cd ${SOURCE_DIR}
SOURCE_DIR=$(pwd)

# ==== get version ====
VERSION=`grep -o "version=.*" ${MANIFEST}`
print_env

# sign and pack
flist=""
cd ${TEMP_DIR}
for i in $(seq 1 "$PACK_NUM");
do
    ver="${VERSION}-${i}"
    sed -i "s/version=.*/${ver}/g" ${MANIFEST}
    openssl dgst -sha256 -sign ${ROOT_DIR}/${PRIVATE_KEY} -out ${MANIFEST}.sig ${MANIFEST}
    #print_env
    #exit
    output=${SOURCE_DIR}/${OUTPUT_HEADER}_${i}.${OUTPUT_TAIL}
    flist="${flist} ${output}"
    tar -cf ${SOURCE_DIR}/${OUTPUT_HEADER}_${i}.${OUTPUT_TAIL} .
done
if [ "$?" != "0" ];then
    echo "tar file error..."
    exit 1
fi
#rm -r ${TEMP_DIR}
echo "repack finished..."
echo "out files:${flist}"

