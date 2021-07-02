
import Vue from 'vue';
import JSTool from "./JSTool.js";

/**
 clientTop: 容器内部相对于容器本身的top偏移，== border-top-width
 clientWidth: 容器的窗口宽度【padding-left + width + padding-right】

 scrollTop、scrollLeft: 滚动容器 滚动的偏移量[真实内容超出padding外层的部分]
 scrollWidth：滚动容器【padding-left + 滚动内容width + padding-right】

 offsetTop: 该元素的boder外层 到 父元素的boder内层
 offsetWidth: 【border-left-width + padding-left + width + padding-right + border-right-width】
 */

// 为html注入全局方法
class HtmlWindow {
    //获取style
    getStyle(dom) {
        return window.getComputedStyle(dom, null);
    }
    getPropertyValue(dom, key) {
        return this.getStyle(dom).getPropertyValue(key)
    }

    //元素大小相关
    pageYOffset() {
        return window.pageYOffset
    }
    //元素相对body的原点的位置
    pointInBody(dom) {
        let l = 0, t = 0;
        while (dom) {
            l = l + dom.offsetLeft + dom.clientLeft;
            t = t + dom.offsetTop + dom.clientTop;
            dom = dom.offsetParent;
        }
        return { left: l, top: t };
    }
    //元素相对当前窗口的位置
    clientRect(dom) {
        // top 包含 margin 不包含 border padding
        // left 包含 margin 不包含 border padding
        // width 不包含 margin 包含 border padding
        // height 不包含 margin 包含 border padding
        return dom.getBoundingClientRect()
    }
    clientRealRect(dom) {
        const removePx = (num) => {
            let res = num.toString();
            if (res.indexOf('px') != -1) {
                res = res.replace(/px/g, '')
            }
            return parseFloat(res)
        }
        const styleValue = (key) => {
            return removePx(this.getPropertyValue(dom, key))
        }
        const domRect = this.clientRect(dom);
        return {
            top: domRect.top + styleValue('border-top-width') + styleValue('padding-top'),
            bottom: domRect.bottom + styleValue('border-bottom-width') + styleValue('padding-bottom'),
            left: domRect.left + styleValue('border-left-width') + styleValue('padding-left'),
            right: domRect.right - styleValue('border-right-width') + styleValue('padding-right'),
            width: domRect.width - styleValue('border-left-width') - styleValue('border-right-width') - styleValue('padding-left') - styleValue('padding-right'),
            height: domRect.height - styleValue('border-top-width') - styleValue('border-bottom-width') - styleValue('padding-top') - styleValue('padding-bottom')
        }
    }
    //window body 的宽高
    client() {
        // ie9 +  最新浏览器
        if (window.innerWidth != null) {
            return {
                width: window.innerWidth,
                height: window.innerHeight
            }
        }
        // 标准浏览器
        else if (document.compatMode === "CSS1Compat") {
            return {
                width: document.documentElement.clientWidth,
                height: document.documentElement.clientHeight
            }
        }
        // 怪异模式
        return {
            width: document.body.clientWidth,
            height: document.body.clientHeight
        }
    }
}
export default new HtmlWindow();