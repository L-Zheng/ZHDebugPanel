
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
        title: "Console",
        selected: false,
        listId: "log-list",
        itemsFunc: appDataItem => {
          return appDataItem.logItems;
        },
        limitCount: 1000,
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
        title: "ExceptionWeb",
        selected: false,
        listId: "exceptionWeb-list",
        itemsFunc: appDataItem => {
          return appDataItem.exceptionWebItems;
        },
        limitCount: 200,
        removePercent: 0.5
      },
      {
        title: "WebSocket",
        selected: false,
        listId: "webSocket-list",
        itemsFunc: appDataItem => {
          return appDataItem.webSocketItems;
        },
        limitCount: 200,
        removePercent: 0.5
      },
      {
        title: "EventSource",
        selected: false,
        listId: "eventSource-list",
        itemsFunc: appDataItem => {
          return appDataItem.eventSourceItems;
        },
        limitCount: 200,
        removePercent: 0.5
      },
      {
        title: "内存泄漏",
        selected: false,
        listId: "leaks-list",
        itemsFunc: appDataItem => {
          return appDataItem.leaksItems;
        },
        limitCount: 50,
        removePercent: 0.5
      },
      {
        title: "崩溃",
        selected: false,
        listId: "crash-list",
        itemsFunc: appDataItem => {
          return appDataItem.crashItems;
        },
        limitCount: 50,
        removePercent: 0.5
      },
      {
        title: "内存警告",
        selected: false,
        listId: "memoryWarning-list",
        itemsFunc: appDataItem => {
          return appDataItem.memoryWarningItems;
        },
        limitCount: 50,
        removePercent: 0.5
      },
      {
        title: "渲染时间线",
        selected: false,
        listId: "timeline-list",
        itemsFunc: appDataItem => {
          return appDataItem.timelineItems;
        },
        limitCount: 100,
        removePercent: 0.5
      },
      {
        title: "API调用",
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
        title: "SDK报错",
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
