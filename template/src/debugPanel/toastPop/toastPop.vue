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
      @click="popClick"
      :style="{
        color: textColor,
        height: layoutConfig.optionH + 'px',
        'border-radius': layoutConfig.optionH * 0.5 + 'px',
      }"
    >
      <span class="content">{{ title }}</span>
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
      textColor: '',
      clickOp: null,
      timer: null
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.textColor = this.colorConfig.selectColor;
  },
  computed: {},
  mounted() {},
  methods: {
    show(title, clickOp = null, type = 'default') {
      const logTypeColor = {
        'default': '#0CC82E',
        'log': '#000000',
        'info': '#000000',
        'debug': '#000000',
        'warning': '#FFD700',
        'error': '#DC143C'
      }
      this.clickOp = clickOp;
      this.textColor = logTypeColor[type] 
      this.title = title;
      if (!this.timer) {
        this.popWrapAnimationClass = "pop-wrap-show";
      }else{
        clearTimeout(this.timer)
      }
      this.timer = setTimeout(() => {
        this.hide();
        this.timer = null
      }, 1500);
    },
    hide() {
      this.popWrapAnimationClass = "pop-wrap-hide";
    },
    popClick(){
      if (this.clickOp) {
        this.clickOp()
      }
      this.clickOp = null
      this.hide()
    }
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
.content{
  white-space:pre-wrap;
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