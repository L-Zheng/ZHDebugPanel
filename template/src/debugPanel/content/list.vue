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
import Mouse from "../base/Mouse.js";
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
      items_temp: [],
      allowAutoScroll: true,
      scrollStatus: 0,
      isShow: false,
      mouseScrollTimer: null
    };
  },
  created() {
    // 监听手机端的touch滑动事件
    // https://blog.csdn.net/For_My_Own_Voice/article/details/81537292
    // h5 监听滚动结束
    // https://www.baidu.com/s?wd=h5%20%E7%9B%91%E5%90%AC%E6%BB%9A%E5%8A%A8%E7%BB%93%E6%9D%9F&rsv_spt=1&rsv_iqid=0xbd0068860000f2b7&issp=1&f=8&rsv_bp=1&rsv_idx=2&ie=utf-8&tn=baiduhome_pg&rsv_enter=1&rsv_dl=tb&rsv_sug3=27&rsv_sug1=16&rsv_sug7=100&rsv_sug2=0&rsv_btype=i&inputT=9932&rsv_sug4=9933
    // https://blog.csdn.net/guohao326/article/details/94636502
    ScrollOp.registerScrollEvent(e => {
      return;
      clearTimeout(this.timer);
      this.scrolling = true;
      this.timer = setTimeout(() => {
        this.scrolling = false;
        this.items_temp.forEach(el => {
          el();
        });
        this.items_temp.splice(0, this.items_temp.length);
      }, 300);
      const bodyRect = HtmlWindow.client();
      const bodyScrollTop =
        window.pageYOffset || document.documentElement.scrollTop;
      const bodyScrollHeight =
        document.body.scrollHeight || document.documentElement.scrollHeight;
      // const rowDomId = "row-id-" + (this.items.length - 1);
      // const rowDomRect = HtmlWindow.clientRealRect(
      //   Dom.getElementById(rowDomId)
      // );
      if (bodyScrollTop >= bodyScrollHeight - bodyRect.height - 0) {
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
    Mouse.registerMouseScrollEvent(e => {
      e = e || window.event;
      //先判断浏览器IE，谷歌滑轮事件 e.wheelDelta
      //Firefox滑轮事件 e.detail
      const offset = e.wheelDelta || e.detail;
      if (!e.wheelDelta) return;
      this.scrollStatus = 1;
      this.updateScrollAuto();
      if (offset > 0) {
        //当滑轮向上滚动时
        console.log("滑轮向上滚动");
      }
      if (offset < 0) {
        //当滑轮向下滚动时
        console.log("滑轮向下滚动");
      }
    });
  },
  computed: {},
  mounted() {},
  methods: {
    updateScrollAuto(){
    if (this.scrollStatus != 0) {
        this.allowAutoScroll = false;
        return;
    }
    },
    show() {
      this.isShow = true;
    },
    hide() {
      this.isShow = false;
    },
    // 滚动期间不允许追加数据  监听onscroll,
    addItem(item, limitCount, removePercent) {
      if (!JSTool.isJson(item)) return;
      const addIn = () => {
        DataTask.addAndCleanItems(this.items, item, limitCount, removePercent);
        this.scrollToBottomAuto();
      };
      if (this.scrolling) {
        this.items_temp.push(addIn);
        return;
      }
      addIn();
    },
    scrollToBottomAuto() {
      JSTool.debounce(() => {
        this.$nextTick(() => {
          const rowDomId = "row-id-" + (this.items.length - 1);
          if (this.allowAutoScroll) {
            ScrollOp.scrollDomToBottomById(rowDomId);
          }
        });
      });
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