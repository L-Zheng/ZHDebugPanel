<template>
  <div class="list-wrap" id="list-wrap" :style="{display: isShow ? 'flex' : 'none' }">
    <div class="list">
      <div
        class="row-wrap"
        v-for="(item, idx) in items"
        :key="idx"
        :id="'row-wrap-id-' + idx"
        @click="clickRow(item)"
      >
        <div
          class="row"
          v-for="(rowItem, rowIdx) in item.rowItems"
          :key="rowIdx"
          :style="{
      'border-bottom': layoutConfig.border
    }"
        >
          <div
            class="col"
            v-for="(colItem, colIdx) in rowItem.colItems"
            :key="colIdx"
            :style="{
              width: colItem.percent,
              color: colItem.color,
              'border-right': colIdx < rowItem.colItems.length - 1 ? '1px solid #999' : 'none',
              'background-color1': colItem.backgroundColor
              }"
          >{{colItem.title}}</div>
        </div>
      </div>
    </div>
    <ListOption :items="listOptionItems"></ListOption>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import DataTask from "../data/DataTask.js";
import ScrollOp from "../base/ScrollOp.js";
import Mouse from "../base/Mouse.js";
import HtmlWindow from "../base/HtmlWindow.js";
import Dom from "../base/Dom.js";
import JSTool from "../base/JSTool.js";
import ListOption from "../content/listOption.vue";
var vm = {
  name: "app",
  components: {
    ListOption
  },
  props: {
    listH: {
      type: Number,
      required: false,
      default: 0
    },
    listId: {
      type: String,
      required: true,
      default: ""
    }
  },
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      listOptionItems: {},
      items: [],
      items_temp: [],
      removeItems_temp: [],
      allowScrollAuto: true,
      scrollStatus: 0,
      isShow: false,
      scrollEndTimer: null,
      mouseScrollEndTimer: null,
      execScrollTimer: null,
      removeSecItemTimer: null,
      reloadListFrequentlyTimer: null
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.listOptionItems = [
      {
        icon: 'icon-shaixuan',
        highlight: false,
        click: () => {
          // 事件要防抖
        }
      },
      {
        icon: 'icon-chazhao',
        highlight: false,
        click: () => {}
      },
      {
        icon: 'icon-shuaxin',
        highlight: false,
        click: () => {}
      },
      {
        icon: 'icon-iconfontshanchu6',
        highlight: false,
        click: () => {}
      },
      {
        icon: 'icon-56zhiding',
        highlight: false,
        click: () => {}
      },
      {
        icon: 'icon-56zhiding-copy',
        highlight: false,
        click: () => {}
      }
    ]
    // 监听手机端的touch滑动事件
    // https://blog.csdn.net/For_My_Own_Voice/article/details/81537292
    // h5 监听滚动结束
    // https://www.baidu.com/s?wd=h5%20%E7%9B%91%E5%90%AC%E6%BB%9A%E5%8A%A8%E7%BB%93%E6%9D%9F&rsv_spt=1&rsv_iqid=0xbd0068860000f2b7&issp=1&f=8&rsv_bp=1&rsv_idx=2&ie=utf-8&tn=baiduhome_pg&rsv_enter=1&rsv_dl=tb&rsv_sug3=27&rsv_sug1=16&rsv_sug7=100&rsv_sug2=0&rsv_btype=i&inputT=9932&rsv_sug4=9933
    // https://blog.csdn.net/guohao326/article/details/94636502
    ScrollOp.registerScrollEvent(e => {
      this.scrollStart(e);
    });
    Mouse.registerMouseScrollEvent(e => {
      this.mouseScrollStart(e);
    });
  },
  computed: {},
  mounted() {},
  methods: {
    mouseScrollStart(e) {
      if (!this.isShow) return;
      e = e || window.event;
      //先判断浏览器IE，谷歌滑轮事件 e.wheelDelta
      //Firefox滑轮事件 e.detail
      const offset = e.wheelDelta || e.detail;
      if (!e.wheelDelta) return;
      this.scrollStatus = 1;
      this.updateScrollAuto();
      clearTimeout(this.mouseScrollEndTimer);
      this.mouseScrollEndTimer = setTimeout(() => {
        this.mouseScrollEnd();
      }, 300);
      // if (offset > 0) {
      //   console.log("滑轮向上滚动");
      // }
      // if (offset < 0) {
      //   console.log("滑轮向下滚动");
      // }
    },
    mouseScrollEnd() {
      this.scrollStatus = 0;
      this.updateScrollAuto();
      this.updateSecItemWhenScrollEnd();
    },
    scrollStart(e) {
      return;
      if (!this.isShow) return;
      this.scrollStatus = 1;
      clearTimeout(this.scrollEndTimer);
      this.scrollEndTimer = setTimeout(() => {
        this.scrollEnd();
      }, 300);
      // const bodyRect = HtmlWindow.client();
      // const bodyScrollTop =
      //   window.pageYOffset || document.documentElement.scrollTop;
      // const bodyScrollHeight =
      //   document.body.scrollHeight || document.documentElement.scrollHeight;
      // const rowDomId = "row-wrap-id-" + (this.items.length - 1);
      // const rowDomRect = HtmlWindow.clientRealRect(
      //   Dom.getElementById(rowDomId)
      // );
    },
    scrollEnd() {},
    show() {
      this.isShow = true;
    },
    hide() {
      this.isShow = false;
    },
    fetchAllItems() {
      return DataTask.fetchAllAppDataItems(this.listId);
    },
    updateSecItemWhenScrollEnd() {
      if (this.scrollStatus != 0) return;

      const arr = this.items_temp;
      if (arr.length <= 0) return;
      arr.forEach(el => {
        el();
      });
      this.items_temp.splice(0, this.items_temp.length);
      this.reloadList()
    },
    // 滚动期间不允许追加数据  监听onscroll,
    addSecItem(item, limitCount, removePercent) {
      if (!this.isShow) return;
      if (!JSTool.isJson(item)) return;
      // if (this.items.length > 30) return;
      const addIn = () => {
        DataTask.addAndCleanItems(this.items, item, limitCount, removePercent);
      };
      if (this.scrollStatus != 0) {
        this.items_temp.push(addIn);
        return;
      }
      addIn();
      this.reloadList();
    },
    removeSecItems(secItems) {
      if (
        !secItems ||
        !JSTool.isArray(secItems) ||
        secItems.length == 0 ||
        this.items.length == 0
      ) {
        return;
      }
      this.removeItems_temp = this.removeItems_temp.concat(secItems);
      this.removeSecItemFrequently();
    },
    removeSecItem(secItem) {
      if (!secItem || !JSTool.isJson(secItem) || this.items.length == 0) return;
      if (this.items.indexOf(secItem) != -1) {
        this.removeItems_temp.push(secItem);
        this.removeSecItemFrequently();
      }
    },
    clearSecItems() {
      if (this.items.length == 0) return;
      this.items.splice(0, this.items.length);
      this.allowScrollAuto = true;
      this.reloadList();
    },
    removeSecItemFrequently() {
      clearTimeout(this.removeSecItemTimer);
      this.removeSecItemTimer = setTimeout(() => {
        this.removeSecItemInstant();
      }, 250);
    },
    removeSecItemInstant() {
      if (this.removeItems_temp.length == 0) {
        return;
      }
      const arr = this.removeItems_temp;
      arr.forEach(el => {
        const removeI = this.items.indexOf(el);
        if (removeI != -1) {
          this.items.splice(removeI, 1);
        }
      });
      this.removeItems_temp.splice(0, this.removeItems_temp.length);
      this.reloadList();
    },
    reloadListWhenSelectApp() {
      this.reloadListWhenShow();
    },
    reloadListWhenSearch() {
      this.reloadListWhenShow();
    },
    reloadListWhenCloseSearch() {
      this.reloadListWhenShow();
    },
    reloadListWhenRefresh() {
      this.reloadListWhenShow();
    },
    reloadListWhenShow() {
      const items = this.fetchAllItems();
      if (!items) {
        items = [];
      }
      this.items = items;
      this.reloadList();
    },
    reloadListFrequently() {
      clearTimeout(this.reloadListFrequentlyTimer);
      this.reloadListFrequentlyTimer = setTimeout(() => {
        this.reloadList();
      }, 250);
    },
    reloadList() {
      if (!this.allowScrollAuto) {
        return;
      }
      this.$nextTick(() => {
        this.scrollListToBottomAuto();
      });
    },
    updateScrollAuto() {
      if (this.scrollStatus != 0) {
        this.allowScrollAuto = false;
        // console.log(this.allowScrollAuto, "1");
        return;
      }
      if (this.items.length <= 0) {
        this.allowScrollAuto = true;
        // console.log(this.allowScrollAuto, "2");
        return;
      }
      const rowDomRect = HtmlWindow.clientRealRect(
        Dom.getElementById("row-wrap-id-" + (this.items.length - 1))
      );
      const listRect = HtmlWindow.clientRealRect(
        Dom.getElementById("list-wrap")
      );
      const contentRect = HtmlWindow.clientRealRect(
        Dom.getElementById("content")
      );
      // 浏览器向上滑动为负值
      const listH = this.listH;
      const listOffSetTopY = -(listRect.top - contentRect.top);
      let listOffSetBottomY = 0;
      if (rowDomRect.bottom - contentRect.top <= listH) {
        listOffSetBottomY = 0;
      } else {
        listOffSetBottomY = rowDomRect.bottom - contentRect.top - listH;
      }
      const listContentH = listOffSetTopY + listH + listOffSetBottomY;
      // console.log(listH, listOffSetTopY, listOffSetBottomY, listContentH);
      if (listContentH <= 0 || listH <= 0) {
        this.allowScrollAuto = true;
        // console.log(this.allowScrollAuto, "3");
        return;
      }
      if (listContentH <= listH) {
        this.allowScrollAuto = true;
        // console.log(this.allowScrollAuto, "4");
        return;
      }
      if (listOffSetTopY >= listContentH - listH - 10) {
        this.allowScrollAuto = true;
        // console.log(this.allowScrollAuto, "5");
        return;
      }
      this.allowScrollAuto = false;
      // console.log(this.allowScrollAuto, "6");
    },
    scrollListToBottomAuto() {
      this.cancelScrollEvent();
      this.execScrollTimer = setTimeout(() => {
        this.scrollListToBottomAutoInternal();
      }, 250);
    },
    scrollListToBottomAutoInternal() {
      if (!this.allowScrollAuto || this.scrollStatus != 0) {
        return;
      }
      this.scrollListToBottomInstant();
    },
    scrollListToBottomCode() {
      this.cancelScrollEvent();
      this.execScrollTimer = setTimeout(() => {
        this.scrollListToBottomInstant();
      }, 250);
    },
    scrollListToBottomInstant() {
      this.allowScrollAuto = true;
      if (this.items.length <= 0) return;
      const rowDomId = "row-wrap-id-" + (this.items.length - 1);
      ScrollOp.scrollDomToBottomById(rowDomId);
    },
    scrollListToTopCode() {
      this.cancelScrollEvent();
      this.execScrollTimer = setTimeout(() => {
        this.scrollListToTopInstant();
      }, 250);
    },
    scrollListToTopInstant() {
      if (this.items.length <= 0) return;
      const rowDomId = "row-wrap-id-" + 0;
      ScrollOp.scrollDomToBottomById(rowDomId);
      const rowDomRect = HtmlWindow.clientRealRect(
        Dom.getElementById("row-wrap-id-" + (this.items.length - 1))
      );
      const listRect = HtmlWindow.clientRealRect(
        Dom.getElementById("list-wrap")
      );
      const contentRect = HtmlWindow.clientRealRect(
        Dom.getElementById("content")
      );
      // 浏览器向上滑动为负值
      const listH = this.listH;
      const listOffSetTopY = -(listRect.top - contentRect.top);
      let listOffSetBottomY = 0;
      if (rowDomRect.bottom - contentRect.top <= listH) {
        listOffSetBottomY = 0;
      } else {
        listOffSetBottomY = rowDomRect.bottom - contentRect.top - listH;
      }
      const listContentH = listOffSetTopY + listH + listOffSetBottomY;

      if (listContentH <= 0 || listH <= 0) {
        this.allowScrollAuto = true;
        return;
      }
      if (listContentH <= listH) {
        this.allowScrollAuto = true;
        return;
      }
      this.allowScrollAuto = false;
    },
    cancelScrollEvent() {
      clearTimeout(this.execScrollTimer);
    },
    clickRow(item) {
      item.clickRow(item);
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.list-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  // background-color: orange;
}
.list {
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}
.row-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
}
.row-wrap :active {
  background-color: #efeff4;
}
.row-wrap :hover {
  background-color: #efeff4;
}
.row {
  margin: 0px;
  padding: 0px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: stretch;
  justify-content: flex-start;
}
.col {
  margin: 0px;
  padding: 0px 5px;
}
</style>