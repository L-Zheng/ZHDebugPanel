<template>
  <div class="main-wrap">
    <ToastPop ref="toastPop"></ToastPop>
    <Option ref="option" :items="optionItems" @clickOptionItem="clickOptionItem"></Option>
    <Detail ref="detail"></Detail>
    <Content :items="optionItems" ref="content"></Content>
    <Connect
      ref="connect" @clipboardPermiss="clipboardPermiss" @startConnect="startConnect"
    ></Connect>
  </div>
</template>

<script>
import Vue from "vue";
import qs from "qs";

import MySocket from "./debugPanel/base/Socket.js";
import JSTool from "./debugPanel/base/JSTool.js";
import ScrollOp from "./debugPanel/base/ScrollOp.js";
import Mouse from "./debugPanel/base/Mouse.js";
import DataTask from "./debugPanel/data/DataTask.js";
import ListConfig from "./debugPanel/data/ListConfig.js";
import ToastTool from "./debugPanel/base/ToastTool.js";

import ToastPop from "./debugPanel/toastPop/toastPop.vue";
import Option from "./debugPanel/option/option.vue";
import Content from "./debugPanel/content/content.vue";
import Connect from "./debugPanel/content/connect.vue";
import Detail from "./debugPanel/detail/detail.vue";
function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {
    ToastPop,
    Option,
    Content,
    Connect,
    Detail,
  },
  props: {},
  data() {
    return {
      optionItems: [],
      socket: null,
    };
  },
  created() {
    this.configVue();
    ScrollOp.listenScrollEvent();
    Mouse.listenMouseEvent();
    ToastTool.registerToast((title, clickOp = null, type = 'default') => {
      this.$refs.toastPop.show(title, clickOp, type);
    })
    this.optionItems = ListConfig.fetchItems();
  },
  computed: {},
  mounted() {
    const isLocalTest = false
    if (isLocalTest) {
      setTimeout(() => {
        this.clickOptionItem(this.optionItems[0]);
        this.startTimer();
      }, 1000)
      return;
    }
      this.$refs.connect.show()
    setTimeout(() => {
      this.clickOptionItem(this.optionItems[0]);
      // 建立socket连接 开始接收数据
      // this.startTimer();
      // this.startConnectSocket();
    }, 1000);
    // this.$refs.toastPop.show("啊啊啊啊啊啊");
  },
  methods: {
    configVue() {
      Vue.config.errorHandler = ((oriFunc) => {
        return function (err, vm, info) {
          /**发送至Vue*/
          if (oriFunc) oriFunc.call(null, err, vm, info);
          /**发送至WebView*/
          if (window.onerror) window.onerror.call(null, err);
        };
      })(Vue.config.errorHandler);
    },
    getUrlParamsFromUrl(url) {
      var curUrl = url;
      if (!url) {
        // tslint:disable-next-line: strict-type-predicates
        if (typeof location === "object") {
          curUrl = location.href;
        } else {
          return {};
        }
      }
      var param = {};
      var reg = /(\?[^\?\#]*)/gi;
      var result = curUrl.match(reg);
      if (result) {
        result.forEach(function (str) {
          str = str.slice(1);
          param = Object.assign({}, param, qs.parse(str));
        });
        return param;
      } else return param;
    },
    readFile() {
      const selectedFile =
        "/Users/em/Desktop/My/Develop/Code/ZHCode/GitHubCode/ZHDebugPanel/template/release/pages.json";

      const input = window.document.getElementById("file-input");
      input.addEventListener(
        "change",
        () => {
          console.log("input.files", input.files[0]);
          const reader = new FileReader();
          reader.readAsText(input.files[0], "utf8"); // input.files[0]为第一个文件
          reader.onload = () => {
            console.log(
              "reader.result",
              reader.result,
              JSTool.dataType(reader.result)
            );
            console.log(JSON.parse(reader.result));
          };
        },
        false
      );
    },
    clipboardPermiss(permission){
      if (!permission) {
          this.$refs.toastPop.show("剪切板权限被禁止, 自动填充失败");
      }
    },
    startConnect(socketUrl){
      console.log('socketUrl', socketUrl)
      this.startConnectSocket(socketUrl)
    },
    startConnectSocket(socketUrl) {
      // const urlParams = this.getUrlParamsFromUrl();
      // // console.log(urlParams);
      // const socketUrl = urlParams["socketUrl"];
      if (!socketUrl) return;

      const socket = new WebSocket(socketUrl);
      socket.addEventListener("open", (msg) => {
        console.log("socket opened");
        this.$refs.toastPop.show("连接成功");
        socket.send(
          JSON.stringify({
            msgType: -1,
            clientId: "h5Client",
          })
        );
      this.$refs.connect.hide()
      });
      socket.addEventListener("close", (msg) => {
        this.$refs.toastPop.show("连接失败或关闭");
        console.log('socket close', msg)
      });
      socket.addEventListener("error", (msg) => {
        this.$refs.toastPop.show("连接错误");
        console.log('socket error', msg)
      });
      socket.addEventListener("message", (msg) => {
        let receiveData = msg.data;
        if (!JSTool.isString(receiveData)) {
          return;
        }
        receiveData = JSON.parse(receiveData);
        const msgType = receiveData.msgType;
        if (msgType != 8) {
          return;
        }
        const msgSubType = receiveData.msgSubType;
        if (msgSubType != 1 && msgSubType != 2) {
          return
        }
        // 清除日志信息
        if (msgSubType == 2) {
          // 如果当前列表正在显示，刷新列表
          const listItems = ListConfig.fetchItems()
          listItems.forEach(el => {
            this.$refs.content.$refs[el.listId].autoDelete();
          });
          return
        }
        const listData = receiveData.data;
        const listId = listData.listId;
        const secItem = listData.msg;
        const appItem = listData.appItem;
        // console.log(listId, secItem);
        if (!listId || !JSTool.isString(listId)) {
          return;
        }
        secItem.clickRow = (secItemTemp) => {
          this.$refs.detail.reloadItems(secItemTemp);
        };
        secItem.pasteboardCopy = (secItemTemp) => {
          this.copyToPasteboard(secItemTemp)
        };
        if (listId == 'exception-list' || listId == 'sdkError-list') {
          let targetOptionItem = null;
          this.optionItems.forEach(element => {
            if (element.listId == listId) {
              targetOptionItem = element
            }
          });
          if (targetOptionItem && !targetOptionItem.selected) {
            this.$refs.toastPop.show(`${appItem.appName}, 检测到异常`, () => {
                this.$refs.option.clickTitle(targetOptionItem)
            }, 'error');
          }
        }
        // 追加数据
        this.addData(listId, appItem, secItem);
      });
      // socket.close()
      // socket.send()
      this.socket = socket;

      MySocket.registerSendEvent((data) => {
        this.socket.send(JSON.stringify(data));
      });
    },
    clickOptionItem(item) {
      if (item.selected) return;
      this.optionItems.forEach((el) => {
        el.selected = false;
      });
      item.selected = true;
      this.$refs.content.showList(item.listId);
    },
    startTimer() {
      setInterval(() => {
        const second = new Date().getSeconds();
        // 哪个应用的数据
        const appItem = {};
        appItem.appId = "App-" +  + parseInt(Math.random() * 1000) % 6;
        appItem.appName = appItem.appId;
        // 构造数据
        const page = 'page-' + parseInt(Math.random() * 1000) % 11
        const logType = parseInt(Math.random() * 1000) % 5 + 1
        const logTypeDesc = {
          1: 'log',
          2: 'info',
          3: 'debug',
          4: 'warning',
          5: 'error'
        }[logType]
        const logTypeColor = {
          1: '#000000',
          2: '#000000',
          3: '#000000',
          4: '#FFD700',
          5: '#DC143C'
        }[logType]
        const secItem = {
          filterItem: {
            appItem: appItem,
            page: page,
            outputItem: {
              type: logType
            }
          },
          enterMemoryTime: new Date().getTime(),
          open: true,
          colItems: [],
          rowItems: [
            {
              colItems: [
                {
                  title: "aa" + second,
                  percent: "40%",
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: page,
                  percent: "20%",
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
                {
                  title: appItem.appName,
                  percent: "20%",
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
                {
                  title: logTypeDesc,
                  percent: "20%",
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
              ],
            },
          ],
          detailItems: [
            {
              title: second,
              content: "描述" + second,
              selected: false,
            },
            {
              title: second,
              content: "描述" + second,
              selected: false,
            },
            {
              title: second,
              content: "描述" + second,
              selected: false,
            },
            {
              title: second,
              content: "描述" + second,
              selected: false,
            },
          ],
          clickRow: (secItem) => {
            this.$refs.detail.reloadItems(secItem);
          },
          pasteboardCopy: (secItemTemp) => {
            this.copyToPasteboard(secItemTemp)
          }
        };
        // 追加数据
        this.addData("log-list", appItem, secItem);
      }, 400);
    },
    addData(listId, appItem, secItem) {
      let listMap = null;
      const items = this.optionItems;
      items.forEach((el) => {
        if (el.listId == listId) {
          listMap = el;
        }
      });
      if (!listMap) return;

      // 追加到全局数据管理
      const appDataItem = DataTask.fetchAppDataItem(appItem);
      if (appDataItem) {
        secItem.appDataItem = appDataItem;
        DataTask.addAndCleanItems(
          listMap.itemsFunc(appDataItem),
          secItem,
          listMap.limitCount,
          listMap.removePercent
        );
        // console.log(DataTask.fetchAppDataItem(appItem).logItems);
        // console.log(DataTask.fetchAllAppDataItems());

        // 如果当前列表正在显示，刷新列表
        this.$refs.content.$refs[listId].addSecItem(
          secItem,
          listMap.limitCount,
          listMap.removePercent
        );
      }
    },
    copyToPasteboard(secItemTemp){
      const detailItems = secItemTemp.detailItems;
      let res = "";
      detailItems.forEach((element) => {
        res += "\n\n" + element.title + ":\n" + element.content;
      });
      // res = res.replace(/\\/g, '')
      // 使用yarn serve调试状态下  此api不可用
      navigator.clipboard.writeText(res).then(
        function () {
          /* clipboard successfully set */
        },
        function () {
          /* clipboard write failed */
        }
      );
      this.$refs.toastPop.show("复制成功");
    }
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.main-wrap {
  width: 100%;
  /* fallback */
  /* -webkit-overflow-scrolling: touch;  此句代码会导致webview的scroll的bounds【滑动bounds】会遮盖住fix定位的元素 */
  height: 100%;
  /* height: 100vh; 此句代码打开会导致window.onsroll事件不调用，iOS原生点击状态栏webview不会滚动  如果注释会影响评论弹窗的拖拽 */
  overflow: auto;
  position: relative;
  overflow-x: hidden !important;
}
</style>
