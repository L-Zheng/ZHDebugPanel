<template>
  <div
    class="option"
    :style="{
      height: layoutConfig.optionH + 'px', 
      width: '100%', 
      'background-color': colorConfig.bgColor, 
      // 'border-bottom': layoutConfig.border
    }"
  >
    <div
      class="title-wrap"
      v-for="(item, index) in items"
      :key="index"
      :style="{
          'background-color': item.selected ? 'white' : '',
          color: item.selected ? colorConfig.selectColor : colorConfig.defaultColor,
        }"
      @click="clickTitle(item)"
    >
      <span>{{ item.title }}</span>
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
      required: true,
      default: function() {
        return [];
      }
    }
  },
  data() {
    return {
      layoutConfig:{},
      colorConfig: {},
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
      this.$emit("clickOptionItem", item);
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.option {
  position: fixed;
  top: 0px;
  left: 0px;
  margin: 0px;
  padding: 0px;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
}
.title-wrap {
  height: 100%;
  padding: 0px 5px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
</style>