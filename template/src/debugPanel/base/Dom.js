
import Vue from 'vue';
import JSTool from "./JSTool.js";

class Dom {
    getElementById(Id) {
        if (!JSTool.isString(Id) || !Id) return null;
        return window.document.getElementById(Id)
    }
}
export default new Dom();