<template>
  <div
    class="list-option"
    :style="{
      height: layoutConfig.listOptionH + 'px', 
      width: layoutConfig.contentW, 
      'background-color': colorConfig.bgColor, 
       'border-right': layoutConfig.border, 
       'border-left': layoutConfig.border
    }"
  >
    <div
      class="title-wrap"
      v-for="(item, index) in items"
      :key="index"
      :style="{
          'background-color': item.highlight ? colorConfig.highlightColor: '',
          color: item.selected ? colorConfig.selectColor : colorConfig.defaultColor,
        }"
      @click="clickTitle(item)"
    >
      <span :class="`iconfont ${item.icon}`"></span>
    </div>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
var vm = {
  name: "app",
  components: {},
  props: {
    items: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    }
  },
  data() {
    return {
      layoutConfig: {},
      colorConfig: {}
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
  },
  computed: {},
  mounted() {},
  methods: {
    clickTitle(item) {
      item.highlight = true;
      setTimeout(() => {
        item.highlight = false;
      }, 200);
      item.click();
      // this.$emit("clickOptionItem", item);
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.list-option {
  opacity: 0.7;
  position: fixed;
  left: 0px;
  bottom: 0px;
  margin: 0px;
  padding: 0px;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
}
.title-wrap {
  width: 100%;
  height: 100%;
  padding: 0px;
  margin: 0px;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
}
</style>