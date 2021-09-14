<template>
  <div :class="['apps-wrap', `${appsWrapAnimateClass}`]">
    <div class="bg-wrap" @click="clickBg"></div>
    <div :class="['apps', `${appsAnimateClass}`]">
      <div class="apps-header" :style="{
          'border-bottom': layoutConfig.border,
        }">
        <div class="apps-header-title">筛选</div>
      </div>
      <div class="apps-list-content">
        <div
        class="apps-content"
      >
      <div class="apps-row" :style="{
        'border-bottom': listItems_App.length == 0 ? '' : layoutConfig.border,
      }" @click="selectListAllApp()">选择全部</div>
        <div
          class="apps-row"
          v-for="(item, idx) in listItems_App"
          :key="'App-' + idx"
          @click="selectListApp(item)"
          :style="{
            'border-bottom': idx == listItems_App.length - 1 ? '' : layoutConfig.border,
            color: (listItem_App_Select ? (item.appItem.appId == listItem_App_Select.appItem.appId) : (selectItem && item.appItem.appId == selectItem.appItem.appId))
              ? colorConfig.selectColor
              : colorConfig.defaultColor,
          }"
        >
          {{ item.appItem.appName }}
        </div>
        </div>
        <div
        class="apps-content"
        :style="{
          'border-left': layoutConfig.border,
          'border-right': layoutConfig.border,
        }"
      >
      <div class="apps-row" :style="{
        'border-bottom': listItems_Page.length == 0 ? '' : layoutConfig.border,
      }" @click="selectListAllPage()">选择全部</div>
        <div
          class="apps-row"
          v-for="(item, idx) in listItems_Page"
          :key="'Page-' + idx"
          @click="selectListPage(item)"
          :style="{
            'border-bottom': idx == listItems_Page.length - 1 ? '' : layoutConfig.border,
            color: (listItem_Page_Select ? (item.appItem.appId == listItem_Page_Select.appItem.appId && item.page == listItem_Page_Select.page) : (selectItem && item.appItem.appId == selectItem.appItem.appId && item.page == selectItem.page))
              ? colorConfig.selectColor
              : colorConfig.defaultColor,
          }"
        >
          {{ item.page }}
        </div>
        </div>
        <div
        class="apps-content"
      >
      <div class="apps-row" :style="{
        'border-bottom': listItems_Type.length == 0 ? '' : layoutConfig.border,
      }" @click="selectListAllType()">选择全部</div>
        <div
          class="apps-row"
          v-for="(item, idx) in listItems_Type"
          :key="'Type-' + idx"
          @click="selectListType(item)"
          :style="{
            'border-bottom': idx == listItems_Type.length - 1 ? '' : layoutConfig.border,
            color: (listItem_Type_Select ? (item.type == listItem_Type_Select.type) : (selectItem && item.type == selectItem.outputItem.type))
              ? colorConfig.selectColor
              : colorConfig.defaultColor,
          }"
        >
          {{ item.desc }}
        </div>
        </div>
      </div>
      <div class="apps-header" :style="{
          'border-top': layoutConfig.border,
        }">
        <div class="apps-header-title" @click="selectAll">选择全部</div>
        <div class="apps-header-title" @click="clickSure">确定</div>
        <div class="apps-header-title" @click="clickCancel">取消</div>
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
      selectItem: {},
      listItems_App: [],
      listItems_Page: [],
      listItems_Type: [],
      listItem_App_Select: null,
      listItem_Page_Select: null,
      listItem_Type_Select: null
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.selectItem = DataTask.fetchSelectAppItem();
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
      let secItems = DataTask.fetchAllSecItems(listId);
      secItems = secItems ? secItems : [];
      const map = {}
      for (let i = 0; i < secItems.length; i++) {
        const secItem = secItems[i];
        const filterItem = secItem.filterItem;
        const appItem = filterItem.appItem;
        const appId = appItem.appId;
        if (!appId) {
          continue;
        }
        const listItem = map[appId]
        if (!listItem) {
          listItem = {}
          map[appId] = listItem
        }
        listItem.appItem = appItem
        if (!filterItem.page) {
          continue;
        }
        const subItems = listItem.pageFilterItems ? listItem.pageFilterItems : []
        let contain = false
        for (let j = 0; j < subItems.length; j++) {
          const filterItemTemp = subItems[j];
          if ((!filterItemTemp.page && !filterItem.page) || filterItemTemp.page == filterItem.page) {
              contain = true;
              break;
          }
        }
        if (contain) continue;
        subItems.push(filterItem)
        listItem.pageFilterItems = subItems;
      }
      let newListItems = []
      const listItems = []
      const keys = Object.keys(map)
      keys.forEach(el => {
          listItems.push(map[el])
      });
      let fundCliItem = null
      listItems.forEach(listItem => {
        if (listItem.appItem.appId == "a_socket") {
            fundCliItem = listItem;
        }else{
          newListItems.push(listItem)
        }
      });
      if (fundCliItem) {
        newListItems = [fundCliItem].concat(newListItems);
      }
      this.listItems_App = newListItems;
      this.listItems_Type = DataTask.fetchAllOuputItem()
    },
    selectListApp(item){
      this.listItem_App_Select = item;
      this.listItems_Page = item.pageFilterItems ? item.pageFilterItems : []
    },
    selectListAllApp(){
      this.listItem_App_Select = null
      this.listItems_Page = []
    },
    selectListPage(item){
      this.listItem_Page_Select = item;
    },
    selectListAllPage(){
      this.listItem_Page_Select = null;
    },
    selectListType(item){
      this.listItem_Type_Select = item;
    },
    selectListAllType(){
      this.listItem_Type_Select = null;

    },
    reloadItems11(listId) {
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
      this.selectListAllApp();
      this.selectListAllPage();
      this.selectListAllType();
      this.$emit("selectAll");
      this.hide();
    },
    clickSure(){
      const item = {}
      item.appItem = this.listItem_App_Select ? this.listItem_App_Select.appItem : null
      if (!item.appItem) {
          item.page = null;
      }else{
        if (!this.listItem_Page_Select) {
          item.page = null;
        }else{
            if (item.appItem.appId == this.listItem_Page_Select.appItem.appId) {
                item.page = this.listItem_Page_Select.page;
            }else{
                item.page = null;
            }
        }
      }
      item.outputItem = this.listItem_Type_Select;

      if (!item.appItem && !item.page && !item.outputItem) {
        this.selectAll()
        return
      }
      DataTask.selectAppItem(item);
      this.$emit("selectAppItem", item);
      this.hide();
    },
    clickCancel(){
      this.hide();
    }
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.apps-wrap {
  z-index: 100;
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
  margin: 0px;
  padding: 0px;
  width: 70%;
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
.apps-list-content{
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  margin: 0px;
  padding: 0px;
  overflow: hidden;
}
.apps-content {
  margin: 0px;
  padding: 0px;
  width: 33%;
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