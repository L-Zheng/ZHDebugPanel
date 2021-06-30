
import Vue from 'vue';
import JSTool from "./JSTool.js";
import Dom from "./Dom.js";

class Mouse {
    static mouseEvents = []
    mouseResponse(e) {
        // console.log(e)
        const allEv = Mouse.mouseEvents;
        try {
            allEv.forEach(el => {
                if (el) el(e)
            });
        } catch (error) {
            console.log(error)
        }
    }
    listenMouseEvent() {
        //给页面绑定滑轮滚动事件 
        if (document.addEventListener) {//firefox 
            document.addEventListener('DOMMouseScroll', this.mouseResponse, false);
        }
        //滚动滑轮触发scrollFunc方法 //ie 谷歌 
        window.onmousewheel = document.onmousewheel = this.mouseResponse;
    }
    registerMouseScrollEvent(func) {
        if (!JSTool.isFunction(func)) {
            return false
        }
        Mouse.mouseEvents.push(func)
    }
}
export default new Mouse();