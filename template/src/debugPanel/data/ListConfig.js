
class ListConfig {
  constructor() { }
  refreshListIds() {
    return [{
      listId: 'storage-list',
      sendType: 1,
      sendDeleteType: 10,
      sendDeleteDataKey: 'deleteSecItems'
    }, {
      listId: 'memory-list',
      sendType: 2,
      sendDeleteType: 20,
      sendDeleteDataKey: 'deleteSecItems'
    }]
  }
  fetchItems() {
    return [
      {
        title: "Log",
        selected: false,
        listId: "log-list",
        itemsFunc: appDataItem => {
          return appDataItem.logItems;
        },
        limitCount: 10000,
        removePercent: 0.5
      },
      {
        title: "Network",
        selected: false,
        listId: "network-list",
        itemsFunc: appDataItem => {
          return appDataItem.networkItems;
        },
        limitCount: 200,
        removePercent: 0.5
      },
      {
        title: "Storage",
        selected: false,
        listId: "storage-list",
        itemsFunc: appDataItem => {
          return appDataItem.storageItems;
        },
        limitCount: 200,
        removePercent: 0.5
      },
      {
        title: "Memory",
        selected: false,
        listId: "memory-list",
        itemsFunc: appDataItem => {
          return appDataItem.memoryItems;
        },
        limitCount: 200,
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
        title: "Timeline",
        selected: false,
        listId: "timeline-list",
        itemsFunc: appDataItem => {
          return appDataItem.timelineItems;
        },
        limitCount: 100,
        removePercent: 0.5
      },
      {
        title: "MpApiCaller",
        selected: false,
        listId: "mpApiCaller-list",
        itemsFunc: appDataItem => {
          return appDataItem.mpApiCallerItems;
        },
        limitCount: 1000,
        removePercent: 0.5
      },
      {
        title: "IM",
        selected: false,
        listId: "im-list",
        itemsFunc: appDataItem => {
          return appDataItem.imItems;
        },
        limitCount: 200,
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
