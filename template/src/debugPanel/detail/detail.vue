<template>
  <div
    class="detail"
    :style="{
      top: layoutConfig.optionH + 'px',
      width: layoutConfig.detailW,
      height: contentPercentH,
      border: layoutConfig.border,
    }"
  >
    <div
      class="option-wrap"
      :style="{
        'border-bottom': items.length == 0 ? '' : layoutConfig.border,
      }"
    >
      <div
        class="title-wrap"
        v-for="(item, idx) in items"
        :key="idx"
        @click="clickIndex(idx)"
        :style="{
          color: item.selected
            ? colorConfig.selectColor
            : colorConfig.defaultColor,
        }"
      >
        <span>{{ item.title }}</span>
      </div>
    </div>
    <span class="content-html" v-if="layoutConfig.useHtml" v-html="selectItem.contentHtml">
    </span>
    <pre v-else
      class="content"
      :style="{
        color: colorConfig.defaultColor,
      }"
      >{{ selectItem.content }}</pre
    >
    <div class="bottom-wrap" :style="{
        'background-color': colorConfig.bgColor,
    }">
        <div
        class="bottom-title-wrap"
        v-for="(item, index) in bottomOptions"
        :key="index"
        :style="{
          'background-color': item.highlight ? colorConfig.highlightColor : '',
          color: item.selected
            ? colorConfig.selectColor
            : colorConfig.defaultColor,
        }"
        @click="clickBottomOption(item)"
      >
        <div :class="`iconfont ${item.icon}`"></div>
      </div>
    </div>
  </div>
</template>
<script>
import JSTool from "../base/JSTool.js";
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import HtmlWindow from "../base/HtmlWindow.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      contentPercentH: "",
      highlight: false,
      secItem: null,
      items: [],
      lastSelectIdx: 0,
      selectItem: {},
      timer: null,
      bottomOptions: []
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.configBottomOptionItems();
  },
  computed: {},
  mounted() {
    this.getContentH();
    window.addEventListener(
      "resize",
      () => {
        this.getContentH();
      },
      false
    );
  },
  methods: {
    getContentH() {
      const bodyRect = HtmlWindow.client();
      const windowH = bodyRect.height;
      const otherH = this.layoutConfig.optionH;
      this.contentH = windowH - otherH - 10;
      this.contentPercentH =
        ((this.contentH * 1.0) / (windowH * 1.0)) * 100 + "%";
      return this.contentPercentH;
    },
    reloadItems(secItem) {
      const items = secItem.detailItems;
      if (!JSTool.isArray(items)) return;
      if (secItem != this.secItem) {
        this.selectItem = {content: '载入中...', contentHtml: '载入中...'}
      }
      this.secItem = secItem;
      clearTimeout(this.timer);
      // 然后又创建一个新的 setTimeout, 这样就能保证interval 间隔内如果时间持续触发，就不会执行 fn 函数
      this.timer = setTimeout(() => {
        this.items = items;
        this.clickIndex(this.lastSelectIdx);
        this.$nextTick(() => {});
      }, 150);
    },
    clickIndex(index) {
      if (index >= this.items.length) {
        index = 0;
      }
      this.items.forEach((el) => {
        el.selected = false;
      });
      this.items[index].selected = true;
      this.lastSelectIdx = index;
      this.selectItem = this.items[index];
    },
    configBottomOptionItems(){
      this.bottomOptions = [
        {
          icon: "icon-copy",
          highlight: false,
          click: () => {
            if (this.secItem) {
              this.secItem.pasteboardCopy(this.secItem);
            }
          },
        },
      ]
    },
    clickBottomOption(item) {
      item.highlight = true;
      setTimeout(() => {
        item.highlight = false;
      }, 200);
      item.click();
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.detail {
  margin: 0px;
  padding: 0px;
  position: fixed;
  right: 10px;
  // background-color: cyan;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}
.option-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
  // background-color: cyan;
}
.title-wrap {
  // height: 100%;
  margin: 5px 0px;
  padding: 0px 5px;
  // background-color: orange;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.content {
  margin: 1%;
  padding: 0px;
  width: 98%;
  height: 100%;
  font-family: normal;
  white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  word-wrap: break-word;
  overflow-x: scroll;
  overflow-y: auto;
}
.content-html{
  margin: 1%;
  padding: 0px;
  width: 98%;
  height: 100%;
  font-family: normal;
  // white-space: pre-line;
  word-wrap: break-word;
  overflow-x: scroll;
  overflow-y: auto;
}
.bottom-wrap{
  margin: 0px;
  padding: 0px;
  width: 100%;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
}
.bottom-title-wrap {
  padding: 10px;
  margin: 0px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
</style>
