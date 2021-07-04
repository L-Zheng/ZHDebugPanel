<template>
  <div class="main-wrap">
    <Option :items="optionItems" @clickOptionItem="clickOptionItem"></Option>
    <Detail ref="detail"></Detail>
    <Content :items="optionItems" ref="content"></Content>
  </div>
</template>

<script>
import Vue from "vue";

import ScrollOp from "./debugPanel/base/ScrollOp.js";
import Mouse from "./debugPanel/base/Mouse.js";
import DataTask from "./debugPanel/data/DataTask.js";
import ListConfig from "./debugPanel/data/ListConfig.js";

import Option from "./debugPanel/option/option.vue";
import Content from "./debugPanel/content/content.vue";
import Detail from "./debugPanel/detail/detail.vue";
function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {
    Option,
    Content,
    Detail
  },
  props: {},
  data() {
    return {
      optionItems: []
    };
  },
  created() {
    this.configVue();
    ScrollOp.listenScrollEvent();
    Mouse.listenMouseEvent()
    this.optionItems = ListConfig.fetchItems();
  },
  computed: {},
  mounted() {
    setTimeout(() => {
      this.clickOptionItem(this.optionItems[0]);
      // 建立socket连接 开始接收数据
      this.startTimer();
    }, 1000);
  },
  methods: {
    configVue() {
      Vue.config.errorHandler = (oriFunc => {
        return function(err, vm, info) {
          /**发送至Vue*/
          if (oriFunc) oriFunc.call(null, err, vm, info);
          /**发送至WebView*/
          if (window.onerror) window.onerror.call(null, err);
        };
      })(Vue.config.errorHandler);
    },
    clickOptionItem(item) {
      if (item.selected) return
      this.optionItems.forEach(el => {
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
        appItem.appId = "App";
        appItem.appName = "App";
        // 构造数据
        const secItem = {
          enterMemoryTime: new Date().getTime(),
          open: true,
          colItems: [],
          rowItems: [
            {
              colItems: [
                {
                  title: "aa" + second,
                  percent: "80%",
                  color: "red",
                  backgroundColor: "red"
                },
                {
                  title: "bb" + second,
                  percent: "20%",
                  color: "black",
                  backgroundColor: "blue"
                }
              ]
            }
          ],
          detailItems: [
            {
              title: second,
              content: "描述" + second,
              selected: true
            },
            {
              title: second,
              content: "描述" + second,
              selected: false
            }
          ],
          clickRow: secItem => {
            this.$refs.detail.reloadItems(secItem.detailItems);
          },
          pasteboardBlock: () => {}
        };
        // 追加数据
        this.addData("log-list", appItem, secItem);
      }, 400);
    },
    addData(listId, appItem, secItem) {
      let listMap = null;
      const items = this.optionItems;
      items.forEach(el => {
        if (el.listId == listId) {
          listMap = el
        }
      });
      if (!listMap) return;

      // 追加到全局数据管理
      const appDataItem = DataTask.fetchAppDataItem(appItem);
      secItem.appDataItem = appDataItem;
      DataTask.addAndCleanItems(
        listMap.itemsFunc(appDataItem),
        secItem,
        listMap.limitCount,
        listMap.removePercent
      );
      // console.log(DataTask.fetchAppDataItem(appItem).logItems);

      // 如果当前列表正在显示，刷新列表
      this.$refs.content.$refs[listId].addSecItem(
        secItem,
        listMap.limitCount,
        listMap.removePercent
      );
    }
  }
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
