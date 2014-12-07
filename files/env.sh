export CLUSTER_DIR=$(readlink -f `dirname $0`)
export K8SFS_FILES=$CLUSTER_DIR/k8sfs/files
export SSH_CA=$CLUSTER_DIR/ca/ssh
export ETCD_PEER_CA=$CLUSTER_DIR/ca/etcd/peer
export ETCD_CLIENT_CA=$CLUSTER_DIR/ca/etcd/client
export CEPH_CA=$CLUSTER_DIR/ca/ceph
