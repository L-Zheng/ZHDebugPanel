
import Vue from 'vue';
import JSTool from "../base/JSTool.js";

class DataTask {
    /* 数据结构
 @{
     @"appId": ZHDPAppDataItem
     @"appId": ZHDPAppDataItem
   }

 ZHDPAppDataItem
     ZHDPAppItem *appItem;
     NSMutableArray <ZHDPListSecItem *> *logItems;
     NSMutableArray <ZHDPListSecItem *> *networkItems;
     NSMutableArray <ZHDPListSecItem *> *imItems;
     NSMutableArray <ZHDPListSecItem *> *storageItems;
 */
    static AllMap = {}
    fetchAllAppDataItems() {
        const map = DataTask.AllMap
        const keys = Object.keys(map)
        const res = []
        keys.forEach(el => {
            res.push(map[el])
        });
        return res
    }
    fetchAppDataItem(appItem){
        if (!JSTool.isJson(appItem)) return
        const appId = appItem.appId;
        if (!appId || !JSTool.isString(appId)) return

        var appDataItem = DataTask.AllMap[appId]
        if (!appDataItem) {
            appDataItem = {
                appItem: appItem, 
                logItems: [],
                networkItems: [],
                storageItems: [],
                memoryItems: [],
                exceptionItems: [],
                imItems: [],
                sdkErrorItems: [],
            }
            DataTask.AllMap[appId] = appDataItem
        }
        return appDataItem;
    }
    cleanAllItems(items) {
        if (!JSTool.isArray(items)) return
        items.splice(0, items.length);
    }
    addAndCleanItems(items, item, limitCount, removePercent) {
        if (!JSTool.isArray(items) || !item) return
        items.push(item);
        if (items.length > limitCount) {
            const removeCount = Math.floor(items.length * removePercent);
            if (removeCount < 0) removeCount = 0;
            if (removeCount < items.length) {
                items.splice(0, removeCount);
            }
        }
    }
}
export default new DataTask();