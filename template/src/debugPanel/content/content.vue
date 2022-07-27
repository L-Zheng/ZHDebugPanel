<template>
  <div
    class="content"
    id="content"
    :style="{
      top: layoutConfig.optionH + 'px',
      // 'margin': layoutConfig.optionH + 'px' + ' 0px' + ' 0px' + ' 0px',
      width: layoutConfig.contentW,
      height: contentPercentH,
      border: layoutConfig.border,
    }"
  >
    <!-- <List v-for="(item, idx) in items" :key="idx" :ref="item.listId" :listH="contentH"></List> -->

    <List
      ref="log-list"
      :listId="'log-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="network-list"
      :listId="'network-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="storage-list"
      :listId="'storage-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="memory-list"
      :listId="'memory-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="exception-list"
      :listId="'exception-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="exceptionWeb-list"
      :listId="'exceptionWeb-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="webSocket-list"
      :listId="'webSocket-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="eventSource-list"
      :listId="'eventSource-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="leaks-list"
      :listId="'leaks-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="crash-list"
      :listId="'crash-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="memoryWarning-list"
      :listId="'memoryWarning-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="timeline-list"
      :listId="'timeline-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="mpApiCaller-list"
      :listId="'mpApiCaller-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="im-list"
      :listId="'im-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
    <List
      ref="sdkError-list"
      :listId="'sdkError-list'"
      :listWrapH="contentH"
      :listH="listH"
    ></List>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import HtmlWindow from "../base/HtmlWindow.js";
import ListConfig from "../data/ListConfig.js";
import List from "../content/list.vue";
var vm = {
  name: "app",
  components: {
    List,
  },
  props: {
    items: {
      type: Array,
      required: true,
      default: function () {
        return [];
      },
    },
  },
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      contentH: 0,
      listH: 0,
      contentPercentH: 0,
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.getContentH();
  },
  computed: {},
  mounted() {
    // 此代码无效
    // window.οnresize = function() {
    // }
    window.addEventListener(
      "resize",
      () => {
        this.getContentH();
      },
      false
    );
  },
  methods: {
    showList(ref) {
      this.items.forEach((item) => {
        const list = this.$refs[item.listId];
        if (list) {
          list.hide();
        }
      });
      this.$refs[ref].show();
    },
    getContentH() {
      // return '80%'
      const bodyRect = HtmlWindow.client();
      const windowH = bodyRect.height;
      const otherH = this.layoutConfig.listOptionH + this.layoutConfig.optionH;
      this.contentH = windowH - otherH - 3;
      this.listH = this.contentH - this.layoutConfig.searchH;
      this.contentPercentH =
        ((this.contentH * 1.0) / (windowH * 1.0)) * 100 + "%";
      return this.contentPercentH;
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.content {
  margin: 0px;
  padding: 0px;
  position: fixed;
  left: 0px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  overflow-y: scroll;
}
</style>
