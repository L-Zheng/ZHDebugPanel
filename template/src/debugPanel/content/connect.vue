<template>
  <div :class="['connect-wrap', `${connectWrapAnimateClass}`]">
    <div class="bg-wrap"></div>
    <div :class="['connect', `${connectAnimateClass}`]">
      <div class="input-wrap">
      <input
        class="input"
        ref="input"
        type="text"
        placeholder="粘贴链接地址(ws://xxx.xxx), 允许访问剪切板以自动填充"
      />
      </div>
      <div class="connect-header" @click="startConnect">
          <div class="connect-text">点击建立连接</div>
      </div>
    </div>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import DataTask from "../data/DataTask.js";
import JSTool from "../base/JSTool.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      connectWrapAnimateClass: "",
      connectAnimateClass: "",
      isShow: false,
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
  },
  computed: {},
  mounted() {},
  methods: {
    // 当此页面显示时  list列表监听到鼠标滚动 直接return 不予处理
    show() {
      if (this.isShow) {
        return;
      }
      this.connectWrapAnimateClass = "connect-wrap-show";
      this.connectAnimateClass = "connect-show";
      this.isShow = true;
      setTimeout(() => {
        navigator.clipboard.readText().then((e) => {
          // console.log('clipboard', e)
          if (e && JSTool.isString(e)) {
            this.$refs.input.value = e;
            this.$nextTick(() => {
                this.startConnect()
            });
          }
        }).catch(err => {
          this.$emit('clipboardPermiss', false)
          console.log('clipboard', err)
        })
      }, 200);
    },
    hide() {
      if (!this.isShow) {
        return;
      }
      this.connectWrapAnimateClass = "connect-wrap-hidden";
      this.connectAnimateClass = "connect-hidden";
      this.isShow = false;
      setTimeout(() => {
        this.connectWrapAnimateClass = "";
        this.connectAnimateClass = "";
      }, 200);
    },
    startConnect() {
      const res = this.$refs.input.value;
      if (!res || res.indexOf('ws://') == -1) {
          return
      }
      this.$emit("startConnect", res);
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.connect-wrap {
  position: fixed;
  top: 0px;
  left: 0px;
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  transform: scale(0);
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.connect-wrap-show {
  //蒙版出现
  animation: animate-connect-wrap-show 0.2s linear;
  animation-fill-mode: forwards;
}
@keyframes animate-connect-wrap-show {
  0% {
    opacity: 0;
    transform: scale(1);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}
.connect-wrap-hidden {
  //蒙版消失
  animation: animate-connect-wrap-hidden 0.2s linear;
}
@keyframes animate-connect-wrap-hidden {
  0% {
    opacity: 1;
    transform: scale(1);
  }
  100% {
    opacity: 0;
    transform: scale(1);
  }
}
.bg-wrap {
  position: absolute;
  top: 0px;
  left: 0px;
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  opacity: 0.3;
  background-color: black;
}
.connect {
  z-index: 1000;
  margin: 0px;
  padding: 0px;
  width: 40%;
  max-height: 50%;
  background-color: white;
  border-radius: 10px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
}
.connect-show {
  //弹窗出现
  animation: animate-connect-show 0.2s linear;
  animation-fill-mode: forwards;
}
@keyframes animate-connect-show {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
.connect-hidden {
  //弹窗消失
  animation: animate-connect-hidden 0.2s linear;
}
@keyframes animate-connect-hidden {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  100% {
    transform: scale(0);
    opacity: 0;
  }
}
.input-wrap{
    margin: 0px;
    padding: 0px;
    width: 100%;
    height: 50px;
  display: flex;
  flex-direction: row;
  justify-content: center;
  align-items: center;
}
.input{
    margin: 10px 10px;
    padding: 0px;
    width: 100%;
    height: 30px;
}
.connect-header {
  margin: 0px;
  padding: 5px 0px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  text-align: center;
}
.connect-header :hover {
  background-color: #efeff4;
}
.connect-text{
    width: 100%;
}
</style>