
import Vue from 'vue';
import JSTool from "./JSTool.js";
import Dom from "./Dom.js";
import smoothscroll from 'smoothscroll-polyfill';
// kick off the polyfill!
smoothscroll.polyfill();

class ScrollOp {
    static scrollEvents = []
    listenScrollEvent() {
        //监听滚动事件
        window.onscroll = e => {
            // console.log(e)
            const scrollEvents = ScrollOp.scrollEvents;
            try {
                scrollEvents.forEach(el => {
                    if (el) el(e)
                });
            } catch (error) {
                console.log(error)
            }
        };
    }
    registerScrollEvent(func) {
        if (!JSTool.isFunction(func)) {
            return false
        }
        ScrollOp.scrollEvents.push(func)
    }
    //滚动相关
    scrollToOffsetY(y, animate = false) {
        window.scroll({ top: y, behavior: animate ? 'smooth' : 'auto' })
        // window.document.body.scrollTop = y;
    }
    // https://blog.csdn.net/qq_35366269/article/details/97236793
    //滚动元素到顶部
    scrollDomToTopById(domId, animate = true) {
        this.scrollDomById(domId, 'start', 'nearest', animate)
    }
    //滚动元素到底部
    scrollDomToBottomById(domId, animate = true) {
        this.scrollDomById(domId, 'end', 'nearest', animate)
    }
    scrollDomById(domId, verticalAlign = "start", horizontalAlign = "nearest", animate = true) {
        if (!JSTool.isString(domId) || !domId) return;
        const dom = Dom.getElementById(domId)
        if (!dom) return;
        // verticalAlign : "start", "center", "end", "nearest"[默认值]
        // horizontalAlign : "start", "center", "end", "nearest"[默认值]
        dom.scrollIntoView({
            block: verticalAlign,
            behavior: animate ? "smooth" : "auto", //"instant"
            inline: horizontalAlign
        })
    }
}
export default new ScrollOp();