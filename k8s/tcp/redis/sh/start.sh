#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
cd $DIR
export LD_LIBRARY_PATH=$DIR:$LD_LIBRARY_PATH

# conf=./nodes.conf
# hosts=./hosts

hosts=/etc/hosts
conf=/var/lib/redis/nodes.conf

newip=$(cat $hosts|grep redis-app|awk '{print $1}')
[ "$newip"x != ""x ] || {  echo "hosts里没有找到redis-app的ip,退出" && exit 1; }

ckeckConf(){
    [ -f "$1" ] || { echo "集群配置文件nodes.conf不存在,集群初始化中..."  && return; }
    

    echo "检查nodes.conf文件内容..."
    arr="$(cat $1|grep -E "master|slave"|awk '{print $1}')"
    len=$(echo  "${arr}" | wc -l)
    echo -e "$len条clusterid,如下: \n""${arr}"
    [ "$len" -ne 1 ] || { echo "集群配置文件clusterid数目不对,请到nfs服务器核查node.conf文件,退出" && exit 1; }


    myselfid=$(cat $1 |grep myself|awk '{print $1}')
    [ "$myselfid"x != ""x ] || {  echo "nodes.conf里没有找到myselfid,退出" && exit 1; }
     echo "把新ip写入自身clusterid文件内..."
    echo $newip > $PWD/$myselfid 
    echo "k8s重启后: $myselfid -> $newip";

    for i in ${arr};
    do
        [ -f "./$i" ] || { echo "没有./$i这个目录" && continue; }

        checkip=$(cat ./$i)
        [ "$checkip"x != ""x ] || { echo "clusterid文件内容为空" && continue; }

        echo "执行命令:ping -c1 $checkip"
        $DIR/ping -c1 $checkip
        [ $? -ne 1 ] || { echo "ping $newip 结果返回ip不通" && continue; }

        oldip=$(cat $1 |grep -E "^$i"|awk '{print $2}'|cut -d ":" -f1)
        [ "$oldip"x != ""x ] || { echo "clusterid在nodes.conf里没有搜索到ip,退出" && exit 1; }

        echo "oldip:$oldip =========== newip:$checkip"
        sed -i "s/$oldip/$checkip/g" $1
        [ $? -ne 0 ] || { echo "完成替换,clusterid:$i === ip:$checkip" && continue; }     

    done
    
    echo "配置文件nodes.conf,检查完毕..."
}

echo "$newip 开始检查配置文件nodes.conf"
ckeckConf  $conf

[ "$(which redis-server)"x != ""x ] || { echo "找不到redis-server,退出" && exit 1; }
echo "开始启动服务...."
echo "执行命令:redis-server $1 --cluster-announce-ip $newip"
redis-server $1 --cluster-announce-ip $newip
