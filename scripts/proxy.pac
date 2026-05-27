function FindProxyForURL(url, host) {
    // 本地地址直连
    if (isPlainHostName(host) ||
        host === '127.0.0.1' ||
        host === 'localhost' ||
        host === '::1' ||
        host.indexOf('192.168.') === 0 ||
        host.indexOf('10.') === 0 ||
        host.indexOf('172.16.') === 0 ||
        host.indexOf('172.30.') === 0)
        return 'DIRECT';

    // .cn 域名直连
    if (dnsDomainIs(host, '.cn') ||
        dnsDomainIs(host, '.com.cn') ||
        dnsDomainIs(host, '.net.cn') ||
        dnsDomainIs(host, '.org.cn'))
        return 'DIRECT';

    // 国内常用服务直连
    var china_domains = [
        '.baidu.com', '.bdimg.com', '.bdstatic.com',
        '.qq.com', '.gtimg.com', '.qpic.cn', '.tencent.com',
        '.weixin.com', '.wx.qq.com',
        '.taobao.com', '.tmall.com', '.alibaba.com', '.alicdn.com',
        '.aliyun.com', '.alipay.com',
        '.jd.com', '.360buy.com', '.jdpay.com',
        '.163.com', '.126.com', '.netease.com',
        '.sina.com.cn', '.sinaimg.cn', '.weibo.com',
        '.sohu.com', '.sogou.com',
        '.zhihu.com', '.bilibili.com', '.hdslb.com',
        '.douyin.com', '.iesdouyin.com',
        '.meituan.com', '.dianping.com',
        '.xiaohongshu.com',
        '.csdn.net',
        '.cnblogs.com',
        '.oschina.net', '.gitee.com',
        '.ctrip.com', '.qunar.com',
        '.cctv.com', '.xinhuanet.com', '.people.com.cn',
        '.gov.cn', '.edu.cn',
        '.rust-lang.org', '.crates.io',  // Rust 镜像
        '.docker.com', '.docker.io',     // Docker 镜像
        '.npmjs.org', '.npmjs.com',       // npm 镜像
        '.python.org', '.pypi.org',       // PyPI 镜像
        '.githubassets.com',
        '.fastgit.org',                   // GitHub 镜像
    ];

    for (var i = 0; i < china_domains.length; i++) {
        if (dnsDomainIs(host, china_domains[i]))
            return 'DIRECT';
    }

    // 走代理
    return 'PROXY 127.0.0.1:9910';
}
