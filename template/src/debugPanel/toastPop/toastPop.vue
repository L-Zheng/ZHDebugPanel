<template>
  <div
    :class="['pop-wrap', `${popWrapAnimationClass}`]"
    :style="{
      top: -layoutConfig.optionH + 'px',
      height: layoutConfig.optionH + 'px',
    }"
  >
    <div
      class="pop"
      :style="{
        color: colorConfig.selectColor,
        height: layoutConfig.optionH + 'px',
        'border-radius': layoutConfig.optionH * 0.5 + 'px',
      }"
    >
      <span>{{ title }}</span>
    </div>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      popWrapAnimationClass: "",
      title: "",
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
  },
  computed: {},
  mounted() {},
  methods: {
    show(title) {
      this.title = title;
      this.popWrapAnimationClass = "pop-wrap-show";
      setTimeout(() => {
        this.hide();
      }, 1500);
    },
    hide() {
      this.popWrapAnimationClass = "pop-wrap-hide";
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.pop-wrap {
  z-index: 10000;
  position: fixed;
  width: 100%;
  left: 0px;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
}
.pop {
  background-color: white;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  padding: 0px 20px;
}
.pop-wrap-show {
  //弹窗出现
  animation: animate-pop-wrap-show 0.2s linear;
  animation-fill-mode: forwards;
}
@keyframes animate-pop-wrap-show {
  0% {
    // transform: scale(0);
    opacity: 1;
    top: -40;
  }
  100% {
    // transform: scale(1);
    opacity: 1;
    top: 0;
  }
}
.pop-wrap-hide {
  //弹窗出现
  animation: animate-pop-wrap-hide 0.2s linear;
  animation-fill-mode: forwards;
}
@keyframes animate-pop-wrap-hide {
  0% {
    // transform: scale(0);
    opacity: 1;
    top: 0;
  }
  100% {
    // transform: scale(1);
    opacity: 1;
    top: -40;
  }
}
</style>