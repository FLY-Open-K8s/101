# 1. -v 格式
docker run -d --name docker-volume-v -v /home:/data:ro,rslave nginx
# 如果主机上没有/test目录，则默认创建此目录
docker run -d --name docker-volume-v2 -v /test:/data nginx

# 2. --mount格式
docker run -d --name docker-volume-mount --mount type=bind,source=/home,target=/data,readonly,bind-propagation=rslave nginx

# 3. 匿名数据卷
# 会主机上默认创建目录：/var/lib/docker/volumes/{volume-id}/_data进行映射；
docker run –d --name docker-volume-anonymous -v /data3 nginx

# 4. 命名数据卷：如果当前找不到nas1卷，会创建一个默认类型(local)的卷。
docker run –d --name docker-volume-named -v nas1:/data3 nginx

# 5. 数据卷的挂载传播
# 表示：主机/home下面挂载的目录，在容器/data下面可用，反之可行；
docker run –d -v /home:/data:shared nginx
# 表示：主机/home下面挂载的目录，在容器/data下面可用，反之不行；
docker run –d -v /home:/data:slave nginx
