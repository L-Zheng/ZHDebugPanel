
class ListConfig {
    constructor() { }
    fetchItems() {
        return [
            {
                title: "Log",
                selected: false,
                listId: "log-list",
                itemsFunc: appDataItem => {
                  return appDataItem.logItems;
                },
                limitCount: 100,
                removePercent: 0.5
            },
            {
                title: "Network",
                selected: false,
                listId: "network-list",
                itemsFunc: appDataItem => {
                  return appDataItem.networkItems;
                },
                limitCount: 100,
                removePercent: 0.5
            },
            {
                title: "Storage",
                selected: false,
                listId: "storage-list",
                itemsFunc: appDataItem => {
                  return appDataItem.storageItems;
                },
                limitCount: 100,
                removePercent: 0.5
            },
            {
                title: "Memory",
                selected: false,
                listId: "memory-list",
                itemsFunc: appDataItem => {
                  return appDataItem.memoryItems;
                },
                limitCount: 100,
                removePercent: 0.5
            },
            {
                title: "Exception",
                selected: false,
                listId: "exception-list",
                itemsFunc: appDataItem => {
                  return appDataItem.exceptionItems;
                },
                limitCount: 100,
                removePercent: 0.5
            },
            {
                title: "IM",
                selected: false,
                listId: "im-list",
                itemsFunc: appDataItem => {
                  return appDataItem.imItems;
                },
                limitCount: 100,
                removePercent: 0.5
            },
            {
                title: "SDK Error",
                selected: false,
                listId: "sdkError-list",
                itemsFunc: appDataItem => {
                  return appDataItem.sdkErrorItems;
                },
                limitCount: 100,
                removePercent: 0.5
            }
        ];
    }
}
export default new ListConfig();
