<template>
  <div :class="['apps-wrap', `${appsWrapAnimateClass}`]">
    <div class="bg-wrap" @click="clickBg"></div>
    <div :class="['apps', `${appsAnimateClass}`]">
      <div class="apps-header">
        <div class="apps-header-title">筛选</div>
      </div>
      <div
        class="apps-content"
        :style="{
          'border-top': layoutConfig.border,
          'border-bottom': layoutConfig.border,
        }"
      >
        <div
          class="apps-row"
          v-for="(item, idx) in items"
          :key="idx"
          @click="selectRow(item)"
          :style="{
            'border-bottom': idx == items.length - 1 ? '' : layoutConfig.border,
            color: item.selected
              ? colorConfig.selectColor
              : colorConfig.defaultColor,
          }"
        >
          {{ item.appName }}
        </div>
      </div>
      <div class="apps-header" @click="selectAll">
        <div class="apps-header-title">选择全部</div>
      </div>
    </div>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import DataTask from "../data/DataTask.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      appsWrapAnimateClass: "",
      appsAnimateClass: "",
      isShow: false,
      items: [],
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
    show(listId) {
      if (this.isShow) {
        return;
      }
      this.appsWrapAnimateClass = "apps-wrap-show";
      this.appsAnimateClass = "apps-show";
      this.isShow = true;
      this.reloadItems(listId);
    },
    hide() {
      if (!this.isShow) {
        return;
      }
      this.appsWrapAnimateClass = "apps-wrap-hidden";
      this.appsAnimateClass = "apps-hidden";
      this.isShow = false;
      setTimeout(() => {
        this.appsWrapAnimateClass = "";
        this.appsAnimateClass = "";
      }, 200);
    },
    fetchIsShow() {
      return this.isShow;
    },
    reloadItems(listId) {
      const originSelect = DataTask.fetchSelectAppItem();
      let res = DataTask.fetchAllSecItems(listId);
      res = res ? res : [];
      let fundCliItem = null;
      const appIds = [];
      let resItems = [];
      res.forEach((el) => {
        const appItem = el.appDataItem.appItem;
        const appId = appItem.appId;
        if (appId && appIds.indexOf(appId) < 0) {
          appIds.push(appId);
          appItem.selected =
            originSelect && originSelect.appId
              ? originSelect.appId == appId
              : false;
          if (appId == "a_socket") {
            fundCliItem = appItem;
          } else {
            resItems.push(appItem);
          }
        }
      });
      if (fundCliItem) {
        resItems = [fundCliItem].concat(resItems);
      }
      this.items = resItems;
    },
    clickBg() {
      this.hide();
    },
    selectRow(item) {
      DataTask.selectAppItem(item);
      this.$emit("selectAppItem", item);
      this.hide();
    },
    selectAll() {
      DataTask.selectAppItem(null);
      this.$emit("selectAll");
      this.hide();
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.apps-wrap {
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
.apps-wrap-show {
  //蒙版出现
  animation: animate-apps-wrap-show 0.2s linear;
  animation-fill-mode: forwards;
}
@keyframes animate-apps-wrap-show {
  0% {
    opacity: 0;
    transform: scale(1);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}
.apps-wrap-hidden {
  //蒙版消失
  animation: animate-apps-wrap-hidden 0.2s linear;
}
@keyframes animate-apps-wrap-hidden {
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
.apps {
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
.apps-show {
  //弹窗出现
  animation: animate-apps-show 0.2s linear;
  animation-fill-mode: forwards;
}
@keyframes animate-apps-show {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
.apps-hidden {
  //弹窗消失
  animation: animate-apps-hidden 0.2s linear;
}
@keyframes animate-apps-hidden {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  100% {
    transform: scale(0);
    opacity: 0;
  }
}
.apps-header {
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
.apps-header-title {
  width: 100%;
}
.apps-header :hover {
  background-color: #efeff4;
}
.apps-content {
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  overflow-y: scroll;
  overflow-x: hidden;
}
.apps-content :hover {
  background-color: #efeff4;
}
.apps-row {
  margin: 0px;
  padding: 3px 5px;
  width: 100%;
}
</style>