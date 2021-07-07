
import Vue from 'vue';
import JSTool from "./JSTool.js";

class Socket {
    static sendEvents = []
    sendData(data) {
        const sendEvents = Socket.sendEvents;
        try {
            sendEvents.forEach(el => {
                if (el) el(data)
            });
        } catch (error) {
            console.log(error)
        }
    }
    registerSendEvent(func) {
        if (!JSTool.isFunction(func)) {
            return false
        }
        Socket.sendEvents.push(func)
    }
}
export default new Socket();