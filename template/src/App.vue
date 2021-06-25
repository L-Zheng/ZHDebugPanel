<template>
  <div class="main-wrap">
      <div style="width:150px;height:100px;background-color:green;">
      点我测试
      </div>
  </div>
</template>

<script>
import Vue from "vue";
function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {
  },
  data() {
    return {
    };
  },
  created() {
    this.configVue();
  },
  computed: {},
  mounted() {
  },
  methods: {
    configVue() {
      Vue.config.errorHandler = (oriFunc => {
        return function(err, vm, info) {
          /**发送至Vue*/
          if (oriFunc) oriFunc.call(null, err, vm, info);
          /**发送至WebView*/
          if (window.onerror) window.onerror.call(null, err);
        };
      })(Vue.config.errorHandler);
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.main-wrap {
  width: 100%;
  /* fallback */
  /* -webkit-overflow-scrolling: touch;  此句代码会导致webview的scroll的bounds【滑动bounds】会遮盖住fix定位的元素 */
  height: 100%;
  /* height: 100vh; 此句代码打开会导致window.onsroll事件不调用，iOS原生点击状态栏webview不会滚动  如果注释会影响评论弹窗的拖拽 */
  overflow: auto;
  position: relative;
  overflow-x: hidden !important;
}
</style>
