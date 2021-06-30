<template>
  <div class="list" :style="{display: isShow ? 'flex' : 'none'}">
    <div
      class="row-wrap"
      v-for="(item, idx) in items"
      :key="idx"
      :id="'row-id-' + idx"
      @click="clickRow(item)"
    >
      <div class="row" v-for="(rowItem, rowIdx) in item.rowItems" :key="rowIdx">
        <div
          class="col"
          v-for="(colItem, colIdx) in rowItem.colItems"
          :key="colIdx"
          :style="{width: colItem.percent,
          color: colItem.color,
          'border-right': colIdx < rowItem.colItems.length - 1 ? '1px solid #999' : 'none',
          'background-color1': colItem.backgroundColor}"
        >{{colItem.title}}</div>
      </div>
      <div class="row-line"></div>
    </div>
  </div>
</template>
<script>
import DataTask from "../data/DataTask.js";
import ScrollOp from "../base/ScrollOp.js";
import HtmlWindow from "../base/HtmlWindow.js";
import Dom from "../base/Dom.js";
import JSTool from "../base/JSTool.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      items: [],
      allowAutoScroll: true,
      isShow: false
    };
  },
  created() {
    ScrollOp.registerScrollEvent(e => {
      const bodyRect = HtmlWindow.client();
      const bodyScrollTop =
        window.pageYOffset || document.documentElement.scrollTop;
      const bodyScrollHeight =
        document.body.scrollHeight || document.documentElement.scrollHeight;
      // const rowDomId = "row-id-" + (this.items.length - 1);
      // const rowDomRect = HtmlWindow.clientRealRect(
      //   Dom.getElementById(rowDomId)
      // );
      if (
        bodyScrollTop >=
        bodyScrollHeight - bodyRect.height - 0
      ) {
        this.allowAutoScroll = true;
      } else {
        this.allowAutoScroll = false;
      }
      // console.log(
      //   "bodyScrollTop",
      //   bodyScrollTop,
      //   "bodyScrollHeight",
      //   bodyScrollHeight,
      //   "bodyH",
      //   bodyRect.height,
      //   this.allowAutoScroll
      // );
    });
  },
  computed: {},
  mounted() {},
  methods: {
    show() {
      this.isShow = true;
    },
    hide() {
      this.isShow = false;
    },
    // 滚动期间不允许追加数据  监听onscroll,
    addItem(item, limitCount, removePercent) {
      if (!JSTool.isJson(item)) return;
      JSTool.debounce(() => {
        DataTask.addAndCleanItems(this.items, item, limitCount, removePercent);
        this.$nextTick(() => {
          const rowDomId = "row-id-" + (this.items.length - 1);
          // const rowDom = Dom.getElementById(rowDomId);
          // var listDom = Dom.getElementById("list");

          // let rowDomRect = HtmlWindow.clientRealRect(rowDom);
          // let listDomRect = HtmlWindow.clientRealRect(listDom);
          // const clientHeight = listDom.clientHeight;
          // const scrollHeight = listDom.scrollHeight;
          // let bodyRect = HtmlWindow.client();
          // const bodyScrollTop =
          //   window.pageYOffset || document.documentElement.scrollTop;
          // const bodyScrollHeight =
          //   document.body.scrollHeight || document.documentElement.scrollHeight;
          // console.log(elRect.bottom, bodyRect.height)

          // console.log(
          //   'bodyScrollTop',
          //   bodyScrollTop,
          //   'bodyScrollHeight',
          //   bodyScrollHeight,
          //   "bodyH",
          //   bodyRect.height,
          //   // "topH",
          //   // listDomRect.top,
          //   // "bottomH",
          //   // listDomRect.bottom,
          //   // "listH",
          //   // listDomRect.height
          // );

          if (this.allowAutoScroll) {
            ScrollOp.scrollDomToBottomById(rowDomId);
          }
        });
      }, 200);
    },
    clickRow(item) {
      item.clickRow(item);
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.list {
  margin: 0px;
  padding: 0px;
  width: 60%;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  // background-color: orange;
  border-left: 1px solid #999;
  border-right: 1px solid #999;
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
.row-line {
  margin: 0px;
  padding: 0px;
  height: 1px;
  width: 100%;
  background-color: #999;
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