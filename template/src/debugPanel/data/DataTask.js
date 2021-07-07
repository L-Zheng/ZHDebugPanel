
import Vue from 'vue';
import JSTool from "../base/JSTool.js";
import ListConfig from "./ListConfig.js";

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
    static selectAppItemMap = null
    fetchAllAppDataItems() {
        const map = DataTask.AllMap
        const keys = Object.keys(map)
        let res = []
        keys.forEach(el => {
            res.push(map[el])
        });
        return res
    }
    fetchAllSecItems(listId) {
        let listMap = null;
        const items = ListConfig.fetchItems();
        items.forEach(el => {
            if (el.listId == listId) {
                listMap = el
            }
        });
        if (!listMap) return [];

        const map = DataTask.AllMap
        const keys = Object.keys(map)
        let res = []
        keys.forEach(el => {
            res = res.concat(listMap.itemsFunc(map[el]))
        });
        // 按照进入内存的时间 升序排列
        res.sort((a, b) => { return a.enterMemoryTime - b.enterMemoryTime });

        return res
    }
    fetchAppDataItem(appItem) {
        if (!JSTool.isJson(appItem)) return null
        const appId = appItem.appId;
        if (!appId || !JSTool.isString(appId)) return null

        var appDataItem = DataTask.AllMap[appId]
        if (!appDataItem) {
            appDataItem = {
                appItem: appItem,
                logItems: [],
                networkItems: [],
                storageItems: [],
                memoryItems: [],
                timelineItems: [],
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
    selectAppItem(appItem) {
        DataTask.selectAppItemMap = appItem
    }
    fetchSelectAppItem() {
        return DataTask.selectAppItemMap
    }
}
export default new DataTask();