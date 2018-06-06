#!/bin/bash
set -e
ROOTPATH=$(cd "$(dirname "$0")"; pwd)

declare -A deploy_dns_map=(
    ["h5-dianshang"]="mall.womaoapp.com"
    ["h5-sup"]="admin.sup.womaoapp.com"
    ["h5-car"]="admin.busiz.womaoapp.com"
    ["fl-open-web"]="openapi.womaoapp.com"
    ["dubbo-admin"]="manage.womaoapp.com"
    ["fwas-operations-admin"]="api.busiz.womaoapp.com api.sup.womaoapp.com"
    ["qmall"]="api.womaoapp.com"
    ["h5-yinqing"]="admin.engine.womaoapp.com"
    ["fas-complaints-admin"]="api.engine.womaoapp.com"
    ["fwas-circle-admin"]="api.engine.womaoapp.com"
    ["fwas-crowd-admin"]="api.engine.womaoapp.com"
    ["fwas-finance-admin"]="api.engine.womaoapp.com"
    ["fwas-label-admin"]="api.engine.womaoapp.com"
    ["fwas-member-admin"]="api.engine.womaoapp.com"
    ["fwas-message-admin"]="api.engine.womaoapp.com"
    ["fwas-pay-admin"]="api.engine.womaoapp.com"
    ["fwas-privilege-admin"]="api.engine.womaoapp.com"
    ["fwas-rewardconfiguration-admin"]="api.engine.womaoapp.com"
    ["fwas-sbu-admin"]="api.engine.womaoapp.com"
    ["fwas-security-admin"]="api.engine.womaoapp.com"
    ["fwas-share-admin"]="api.engine.womaoapp.com"
    ["fwas-splitaccount-admin"]="api.engine.womaoapp.com"
    ["fwas-wishinglamp-admin"]="api.engine.womaoapp.com"
)



declare -A deploy_ingress_path_map=(
    ["h5-dianshang"]="/"
    ["h5-sup"]="/"
    ["h5-car"]="/"
    ["fl-open-web"]="/"
    ["dubbo-admin"]="/dubbo-admin"
    ["fwas-operations-admin"]="/fwas-operations-admin"
    ["qmall"]="/qmall"
    ["h5-yinqing"]="/"
    ["fas-complaints-admin"]="/fas-complaints-admin"
    ["fwas-circle-admin"]="/fwas-circle-admin"
    ["fwas-crowd-admin"]="/fwas-crowd-admin"
    ["fwas-finance-admin"]="/fwas-finance-admin"
    ["fwas-label-admin"]="/fwas-label-admin"
    ["fwas-member-admin"]="/fwas-member-admin"
    ["fwas-message-admin"]="/fwas.message.admin"
    ["fwas-pay-admin"]="/fwas-pay-admin"
    ["fwas-privilege-admin"]="/fwas-privilege-admin"
    ["fwas-rewardconfiguration-admin"]="/fwas-rewardConfiguration-admin"
    ["fwas-sbu-admin"]="/fwas-sbu-admin"
    ["fwas-security-admin"]="/fwas-security-admin"
    ["fwas-share-admin"]="/fwas.share.admin"
    ["fwas-splitaccount-admin"]="/fwas-splitAccount-admin"
    ["fwas-wishinglamp-admin"]="/fwas-wishingLamp-admin"
)

declare -A qa_dnselb_map=(
)

declare -A release_dnselb_map=(
    ["api.womaoapp.com"]="10.4.255.200"
    ["womaoapp.com"]="10.4.123.198"
    ["openapi.womaoapp.com"]="10.4.138.112"
    ["admin.sup.womaoapp.com"]="10.4.100.108"
    ["admin.busiz.womaoapp.com"]="10.4.78.22"
    ["api.busiz.womaoapp.com"]="10.4.252.87"
    ["api.sup.womaoapp.com"]="10.4.192.127"
    ["admin.engine.womaoapp.com"]="10.4.138.121"
    ["api.engine.womaoapp.com"]="10.4.117.113"
    ["manage.womaoapp.com"]=""
)

declare -A online_dnselb_map=(
    ["api.womaoapp.com"]="10.3.43.197"
    ["womaoapp.com"]="10.3.169.44"
    ["openapi.womaoapp.com"]="10.3.195.89"
    ["admin.sup.womaoapp.com"]="10.3.89.77"
    ["admin.busiz.womaoapp.com"]="10.3.21.53"
    ["api.busiz.womaoapp.com"]="10.3.19.153"
    ["api.sup.womaoapp.com"]="10.3.162.221"
    ["admin.engine.womaoapp.com"]="10.3.131.172"
    ["api.engine.womaoapp.com"]="10.3.61.121"
    ["manage.womaoapp.com"]="10.3.11.168"
)
#获取环境与编包服务名称
export environment=$1
if [ "qa"x != "${environment}"x ] && [ "release"x != "${environment}"x ] && [ "online"x != "${environment}"x  ];then
    echo "第一个参数请输入部署环境名称！例如：qa, release, online"
    exit
fi
case ${environment} in
    "qa")
        export deploy_dns_pre="qa"
    ;;
    "release")
        declare -A dns_elb_map=()
        for map_key in ${!release_dnselb_map[@]}
        do
            dns_elb_map[${map_key}]=${release_dnselb_map[${map_key}]}
        done
        export deploy_dns_pre="release."
    ;;
    "online")
        declare -A dns_elb_map=()
        for map_key in ${!online_dnselb_map[@]}
        do
            dns_elb_map[${map_key}]=${online_dnselb_map[${map_key}]}
        done
        export deploy_dns_pre=""
    ;;
    *)
        echo "第一个参数请输入部署环境名称！例如：qa, release, online"
        exit
    ;;
esac

export deploy_group_sp=$2
##########deploy_group_sp=$2############
if [ "eg"x != "${deploy_group_sp}"x ] && [ "bs"x != "${deploy_group_sp}"x  ] && [ "sl"x != "${deploy_group_sp}"x  ] && [ "bc"x != "${deploy_group_sp}"x ] && [ "ds"x != "${deploy_group_sp}"x ] && [ "es"x != "${deploy_group_sp}"x ] && [ "gm"x != "${deploy_group_sp}"x ] && [ "."x != "${deploy_group_sp}"x ];then
        echo "请输入应用组名称！例如：引擎engine:eg、电商business:bs、社交social:sl、区块链:bc、大数据:ds、搜索引擎:es、游戏:gm ，若是xxl等>用\'.\'代替 "
        exit
fi
case ${deploy_group_sp} in 
    "eg" )
        deploy_group=engine;
    ;;
    "bs" )
        deploy_group=business;
    ;;
    "sl" )
        deploy_group=social;
    ;;
    "bc" )
        deploy_group=blockchain;
    ;;
    "ds" )
        deploy_group=dashuju;
    ;;
    "es" )
        deploy_group=elasticsearch;
    ;;
    "gm" )
        deploy_group=game;
    ;;
    "." )
        deploy_group=manage;
    ;;   
    * )
        echo "请输入应用组名称！例如：引擎engine:eg、电商business:bs、社交social:sl、区块链:bc、大数据:ds、搜索引擎:es、游戏:gm "
        exit
    ;;  
esac 
export deploy_group_sp_pre=${deploy_group_sp}-
if [ "."x == "${deploy_group_sp}"x ];then
    deploy_group_sp_pre=""
fi
mkdir -p /home/k8s-yaml/ingress/${deploy_group}

export deploy_name=$3
##########deploy_name=$3########
if [ "."x == "${deploy_name}"x ] || [  ""x == "${deploy_name}"x ];then
    echo "请输入应用名称！"
    exit
fi
export deploy_dns_s=${deploy_dns_map[${deploy_name}]}
export ingress_path_s=${deploy_ingress_path_map[${deploy_name}]}
export deployment_name=${deploy_group_sp_pre}${deploy_name}
export service_port=8080
if [[ ${deploy_name} =~ "h5-" ]];then
    export service_port=80
fi

export dns_flag=$4
##########no_dns_flag=$3########
if [ "no_dns"x == "${dns_flag}"x ] || [  "no"x == "${dns_flag}"x ] || [  "n"x == "${dns_flag}"x ]|| [  "flase"x == "${dns_flag}"x ] || [ "."x == "${dns_flag}"x ];then
    dns_flag=None
    deploy_dns_s=None
fi

export elb_ip=$5
##########elb_ip=$3########
if [ "."x != "${elb_ip}"x ] && [  ""x != "${elb_ip}"x ];then
    dns_elb_map[${dns_flag}]=${elb_ip}
fi

###############创建ingress资源##################
function echo_path_for_one_host()
{
    echo ""  >   ${ingres_file_path}
    echo "apiVersion: extensions/v1beta1"                          >>  ${ingres_file_path}
    echo "kind: Ingress"                                           >>  ${ingres_file_path}
    echo "metadata:"                                               >>  ${ingres_file_path}
    echo "  annotations:"                                          >>  ${ingres_file_path}
    echo "    ingress.beta.kubernetes.io/role: data"               >>  ${ingres_file_path}
    echo "    ingress.kubernetes.io/secure-backends: \"false\""    >>  ${ingres_file_path}
    
    ########判断要不要对接elb#################
    if [ "qa"x != "${environment}"x ] &&  [ ""x != "${elb_ip}"x ];then
        echo "    kubernetes.io/elb.ip: ${elb_ip}"                 >>  ${ingres_file_path}
        echo "    kubernetes.io/elb.port: \"${elb_port}\""         >>  ${ingres_file_path}
    fi
    
    echo "  labels:"                                               >>  ${ingres_file_path}
    echo "    deploy-ingress: ${deployment_name}"                  >>  ${ingres_file_path}
    echo "    isExternal: \"true\""                                >>  ${ingres_file_path}
    echo "    zone: data"                                          >>  ${ingres_file_path}
    echo "  name: ${ingress_name}"                                 >>  ${ingres_file_path}
    echo "  namespace: default"                                    >>  ${ingres_file_path}
    echo "spec:"                                                   >>  ${ingres_file_path}
    echo "  rules:"                                                >>  ${ingres_file_path}
    echo "  - http:"                                               >>  ${ingres_file_path}
    echo "      paths:"                                            >>  ${ingres_file_path}
    
    for ingress_path in ${ingress_path_s}
    do
        echo "      - backend:"                                    >>  ${ingres_file_path}
        echo "          serviceName: ${deployment_name}"           >>  ${ingres_file_path}
        echo "          servicePort: ${service_port}"              >>  ${ingres_file_path}
        echo "        path: ${ingress_path}"                       >>  ${ingres_file_path}
    done
}
###############创建ingress资源###################  
function create_ingress()
{
    deploy_dns_s_len=${#deploy_dns_s[@]} 
    ingress_path_s_len=${#ingress_path_s[@]} 
    if [ ${ingress_path_s_len} -eq 0 ];then
        echo "该应用没有定义访问路径"
        return 0
    fi
    if [ ${deploy_dns_s_len} -eq 0 ];then
        deploy_dns_s=None
    fi

    ###########判断要不要加上多个域名 多个path########
    i=0
    for deploy_dns in ${deploy_dns_s}
    do
        export ingress_file_name=${deploy_name}.${deploy_dns}.yaml
        export ingres_file_path=/home/k8s-yaml/ingress/${deploy_group}/${ingress_file_name}
        echo -e "ingres_file_path is :\n               ${ingres_file_path}"
        if [ -f ${ingres_file_path} ];then
            rm -rf ${ingres_file_path}
        fi
        
        if [ ${i} -eq 0 ];then
            export ingress_name=${deploy_group_sp_pre}${deploy_name}-ingress 
            
        else 
            export ingress_name=${deploy_group_sp_pre}${deploy_name}-ingress-${i}
        fi
        
        export elb_ip=${dns_elb_map[${deploy_dns}]}
        export elb_port=80
        
        ##########创建ingress配置文件#######
        echo_path_for_one_host
        
        if [ "None"x != "${deploy_dns}"x ];then     
            echo "    host: ${deploy_dns_pre}${deploy_dns}"                             >>  ${ingres_file_path}
        fi
        let i=i+1
        
        ###########执行创建命令########
        set +e
        kubectl get ingress |grep "${ingress_name}"
        if [ $? == 0 ];then
            kubectl delete -f ${ingres_file_path}
        fi
        set -e
        kubectl create -f ${ingres_file_path}    
        echo -e "\n"
        
    done
}
create_ingress

