<template>
  <div
    class="list-wrap"
    :id="listId + '-wrap'"
    :style="{ display: isShow ? 'flex' : 'none' }"
  >
    <div
      class="input-wrap"
      :id="listId + 'input-wrap'"
      :style="{
        width: layoutConfig.contentW,
        top: searchTop + 'px',
        height: layoutConfig.searchH + 'px',
      }"
    >
    <div class="listCount" :style="{
        height: layoutConfig.searchH + 'px',
        color: colorConfig.selectColor,
      }">{{items ? items.length + '' : ''}}</div>
      <input
        class="input"
        ref="input"
        type="text"
        placeholder="输入以查找"
        v-on:input="inputChange"
      />
      <div
        :style="{
          width: '100%',
          'border-bottom': layoutConfig.border,
        }"
      ></div>
    </div>
    <div
      class="list"
      :id="listId"
      :style="{
        'margin-top': layoutConfig.searchH + 'px',
        height: listH + 'px',
      }"
    >
      <div
        class="row-wrap"
        v-for="(item, idx) in items"
        :key="idx"
        :id="listId + '-row-wrap-id-' + idx"
        @click="clickRow(item)"
      >
        <span class="iconfont icon-iconfontshanchu6 row-delete"
        v-if="showDeleteIcon()"
        @click="clickDeleteRow(item, idx)"
        :style="{
          'background-color': deleteRowHighlight
            ? colorConfig.highlightColor
            : colorConfig.bgColor,
        }"></span>
      
        <div
          class="row"
          v-for="(rowItem, rowIdx) in item.rowItems"
          :key="rowIdx"
          :style="{
            'border-bottom': layoutConfig.border,
          }"
        >
          <div class="row-content" v-if="layoutConfig.useHtml">
            <span
              class="col-html"
              v-for="(colItem, colIdx) in rowItem.colItems"
              v-html="getColItemTitleHtml(colItem)"
              :key="colIdx"
              :style="{
                'padding-top': '0%',
                'padding-bottom': '0%',
                'padding-left': '1%',
                'padding-right': '1%',
                width: `${colItem.percent * 100 - 2}%`,
                color: colItem.color,
                'border-right':
                  colIdx < rowItem.colItems.length - 1
                    ? '1px solid #999'
                    : 'none',
                'background-color1': colItem.backgroundColor,
              }"
              >
            </span>
          </div>
          <div class="row-content" v-else>
          <pre
            class="col"
            v-for="(colItem, colIdx) in rowItem.colItems"
            :key="colIdx"
            :style="{
              'padding-top': '0%',
              'padding-bottom': '0%',
              'padding-left': '1%',
              'padding-right': '1%',
                width: `${colItem.percent * 100 - 2}%`,
              color: colItem.color,
              'border-right':
                colIdx < rowItem.colItems.length - 1
                  ? '1px solid #999'
                  : 'none',
              'background-color1': colItem.backgroundColor,
            }"
            >{{ getColItemTitle(colItem) }}
          </pre>
          </div>
        </div>
      </div>
    </div>
    <ListOption :items="listOptionItems"></ListOption>
    <Apps
      ref="apps"
      @selectAppItem="selectAppItem"
      @selectAll="selectAll"
    ></Apps>
  </div>
</template>
<script>
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import DataTask from "../data/DataTask.js";
import ScrollOp from "../base/ScrollOp.js";
import Mouse from "../base/Mouse.js";
import HtmlWindow from "../base/HtmlWindow.js";
import Dom from "../base/Dom.js";
import JSTool from "../base/JSTool.js";
import ToastTool from "../base/ToastTool.js";
import MySocket from "../base/Socket.js";
import ListOption from "../content/listOption.vue";
import Apps from "./apps.vue";
import ListConfig from "../data/ListConfig.js";
var vm = {
  name: "app",
  components: {
    ListOption,
    Apps,
  },
  props: {
    listWrapH: {
      type: Number,
      required: false,
      default: 0,
    },
    listH: {
      type: Number,
      required: false,
      default: 0,
    },
    listId: {
      type: String,
      required: true,
      default: "",
    },
  },
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      listOptionItems: {},
      items: [],
      items_temp: [],
      removeItems_temp: [],
      allowScrollAuto: true,
      scrollStatus: 0,
      isShow: false,
      scrollEndTimer: null,
      mouseScrollEndTimer: null,
      execScrollTimer: null,
      removeSecItemTimer: null,
      reloadListFrequentlyTimer: null,
      addSecItemFrequentlyTimer: null,
      originLocationIdx: -1,
      searchTop: 0,
      searchKeyword: null,
      deleteRowHighlight: false,
      autoDeleteEnable: false
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.createListOptionItems();
    // 监听手机端的touch滑动事件
    // https://blog.csdn.net/For_My_Own_Voice/article/details/81537292
    // h5 监听滚动结束
    // https://www.baidu.com/s?wd=h5%20%E7%9B%91%E5%90%AC%E6%BB%9A%E5%8A%A8%E7%BB%93%E6%9D%9F&rsv_spt=1&rsv_iqid=0xbd0068860000f2b7&issp=1&f=8&rsv_bp=1&rsv_idx=2&ie=utf-8&tn=baiduhome_pg&rsv_enter=1&rsv_dl=tb&rsv_sug3=27&rsv_sug1=16&rsv_sug7=100&rsv_sug2=0&rsv_btype=i&inputT=9932&rsv_sug4=9933
    // https://blog.csdn.net/guohao326/article/details/94636502
    ScrollOp.registerScrollEvent((e) => {
      this.scrollStart(e);
    });
    Mouse.registerMouseScrollEvent((e) => {
      this.mouseScrollStart(e);
    });
  },
  computed: {},
  mounted() {
    this.searchTop = HtmlWindow.clientRealRect(
      Dom.getElementById("content")
    ).top;
  },
  methods: {
    inputChange() {
      const res = this.$refs.input.value;
      this.searchKeyword = res ? res : null;
      this.reloadListWhenSearch();
    },
    showDeleteIcon(){
      const fetchRes = this.checkSpecialList();
      return fetchRes ? true : false
    },
    selectAppItem(item) {
      console.log(item)
      let title = item.appItem ? item.appItem.appName : ''
      title = title + (item.page ? item.page : '')
      title = title + (item.outputItem ? item.outputItem.desc : '')
      this.updateListOptionItemsTitle(0, title);
      this.reloadListWhenSelectApp();
    },
    selectAll() {
      const count = this.listOptionItems.length;
      for (let index = 0; index < count; index++) {
        const el = this.listOptionItems[index];
        el.title = "";
        el.selected = false;
      }
      this.reloadListWhenSelectApp();
    },
    selectListOptionItems(idx, selected) {
      const count = this.listOptionItems.length;
      for (let index = 0; index < count; index++) {
        if (index == idx) {
          const el = this.listOptionItems[index];
          el.selected = selected;
        }
      }
    },
    updateListOptionItemsTitle(idx, title) {
      const count = this.listOptionItems.length;
      for (let index = 0; index < count; index++) {
        if (index == idx) {
          const el = this.listOptionItems[index];
          el.title = title;
          if (title) {
            el.selected = true;
          }
        }
      }
    },
    createListOptionItems() {
      // 事件要防抖
      let items = [
        {
          icon: "icon-shaixuan",
          title: "",
          selected: false,
          highlight: false,
          click: () => {
            this.$refs.apps.show(this.listId);
          },
        },
        {
          icon: "icon-shuaxin",
          title: "",
          selected: false,
          highlight: false,
          click: () => {
            this.reloadListWhenRefresh();
          },
        },
        {
          icon: "icon-iconfontshanchu6",
          title: "",
          selected: false,
          highlight: false,
          click: () => {
            this.deleteStore(this.items)
            this.removeSecItems(this.items);
          },
        },
      ];
      if (this.allowAutoDelete()) {
        const cIdx = items.length
        items.push({
          icon: "icon-shanchu",
          title: "",
          selected: false,
          highlight: false,
          click: () => {
            this.autoDeleteEnable = !this.autoDeleteEnable;
            this.selectListOptionItems(cIdx, this.autoDeleteEnable)
            // 弹窗提示
            ToastTool.show(`自动清理-已${this.autoDeleteEnable ? '开启' : '关闭'}`)
          },
        })
      }
      items = items.concat([
        {
          icon: "icon-56zhiding",
          title: "",
          selected: false,
          highlight: false,
          click: () => {
            this.scrollListToTopCode();
          },
        },
        {
          icon: "icon-56zhiding-copy",
          title: "",
          selected: false,
          highlight: false,
          click: () => {
            this.scrollListToBottomCode();
          },
        },
      ])
      this.listOptionItems = items
    },
    getColItemTitle(colItem) {
      return colItem.title;
      // if (JSTool.isArray(title) || JSTool.isObject(title)) {
      //   return JSON.stringify(title, null, 2);
      // }
      return title;
    },
    getColItemTitleHtml(colItem) {
      return colItem.titleHtml;
    },
    mouseScrollStart(e) {
      if (!this.isShow) return;
      if (this.$refs.apps.fetchIsShow()) return;
      e = e || window.event;
      //先判断浏览器IE，谷歌滑轮事件 e.wheelDelta
      //Firefox滑轮事件 e.detail
      const offset = e.wheelDelta || e.detail;
      if (!e.wheelDelta) return;
      this.scrollStatus = 1;
      this.updateScrollAuto();
      clearTimeout(this.mouseScrollEndTimer);
      this.mouseScrollEndTimer = setTimeout(() => {
        this.mouseScrollEnd();
      }, 300);
      // if (offset > 0) {
      //   console.log("滑轮向上滚动");
      // }
      // if (offset < 0) {
      //   console.log("滑轮向下滚动");
      // }
    },
    mouseScrollEnd() {
      this.scrollStatus = 0;
      this.updateScrollAuto();
      this.updateSecItemWhenScrollEnd();
    },
    scrollStart(e) {
      return;
      if (!this.isShow) return;
      this.scrollStatus = 1;
      clearTimeout(this.scrollEndTimer);
      this.scrollEndTimer = setTimeout(() => {
        this.scrollEnd();
      }, 300);
      // const bodyRect = HtmlWindow.client();
      // const bodyScrollTop =
      //   window.pageYOffset || document.documentElement.scrollTop;
      // const bodyScrollHeight =
      //   document.body.scrollHeight || document.documentElement.scrollHeight;
      // const rowDomId = "row-wrap-id-" + (this.items.length - 1);
      // const rowDomRect = HtmlWindow.clientRealRect(
      //   Dom.getElementById(rowDomId)
      // );
    },
    scrollEnd() {},
    show() {
      if (this.isShow) {
        return;
      }
      this.isShow = true;
      this.$nextTick(() => {
        this.scrollToOriginLocation();
        this.reloadListWhenShow();
      });
    },
    hide() {
      if (!this.isShow) {
        return;
      }
      this.calculateOriginLocationIdx();
      this.isShow = false;
    },
    verifyFilterCondition(secItem) {
      if (!secItem) {
        return false;
      }

      // 筛选appId
      const cAppItem = secItem.appDataItem.appItem;
      const filterItem = DataTask.fetchSelectAppItem();
      const selectAppItem = (filterItem && filterItem.appItem) ? filterItem.appItem : null
      if (cAppItem && selectAppItem) {
        if (selectAppItem.appId != cAppItem.appId) {
          return false;
        }
      }
      // 筛选page
      const selectPage = filterItem ? filterItem.page : null;
      const cPage = secItem.filterItem.page;
      if (selectPage && selectPage.length > 0) {
          if (!cPage || cPage.length == 0 ||
              selectPage != cPage) {
              return false;
          }
      }
          
      // 筛选日志类型
      const selectType = (filterItem && filterItem.outputItem) ? filterItem.outputItem.type : 0;
      if (selectType != 0 &&
          selectType != secItem.filterItem.outputItem.type) {
          return false;
      }
    
      // 筛选搜索关键字
      const keyword = this.searchKeyword;
      if (!keyword) {
        return true;
      }
      // 搜索某一组
      let colItems = secItem.colItems;
      for (let index = 0; index < colItems.length; index++) {
        const el = colItems[index];
        if (el.title) {
          if (el.title.toLowerCase().indexOf(keyword.toLowerCase()) != -1) {
            return true;
          }
        }
      }
      // 搜索某一行
      const rowItems = secItem.rowItems;
      for (let index = 0; index < rowItems.length; index++) {
        const el1 = rowItems[index];
        colItems = el1.colItems;
        for (let j = 0; j < colItems.length; j++) {
          const el2 = colItems[j];
          if (el2.title) {
            if (el2.title.toLowerCase().indexOf(keyword.toLowerCase()) != -1) {
              return true;
            }
          }
        }
      }
      return false;
    },
    filterItems(secItems) {
      if (!secItems || !JSTool.isArray(secItems)) {
        return [];
      }
      const resItems = [];
      secItems.forEach((element) => {
        if (this.verifyFilterCondition(element)) {
          resItems.push(element);
        }
      });
      return resItems;
    },
    fetchAllItems() {
      const res = DataTask.fetchAllSecItems(this.listId);
      return res ? res : [];
    },
    updateSecItemWhenScrollEnd() {
      if (this.scrollStatus != 0) return;
      this.addSecItemInstant()
    },
    // 滚动期间不允许追加数据  监听onscroll,
    addSecItem(secItem, limitCount, removePercent) {
      if (!this.isShow) return;
      if (!JSTool.isJson(secItem)) return;
      const addIn = () => {
        if (this.verifyFilterCondition(secItem)) {
          DataTask.addAndCleanItems(
            this.items,
            secItem,
            limitCount,
            removePercent
          );
        }
      };
      if (this.scrollStatus != 0) {
        this.items_temp.push(addIn);
        return;
      }

      this.items_temp.push(addIn);
      this.addSecItemFrequently()

      // addIn();
      // this.reloadList();
    },
    addSecItemFrequently(){
      clearTimeout(this.addSecItemFrequentlyTimer);
      this.addSecItemFrequentlyTimer = setTimeout(() => {
        this.addSecItemInstant();
      }, 250);
    },
    addSecItemInstant(){
      const arr = this.items_temp;
      if (arr.length <= 0) return;
      arr.forEach((el) => {
        el();
      });
      this.items_temp.splice(0, this.items_temp.length);
      this.reloadList();
    },
    removeSecItems(secItems) {
      if (
        !secItems ||
        !JSTool.isArray(secItems) ||
        secItems.length == 0
      ) {
        return;
      }
      this.removeItems_temp = this.removeItems_temp.concat(secItems);
      this.removeSecItemFrequently();
    },
    /*
    removeSecItem(secItem) {
      if (!secItem || !JSTool.isJson(secItem) || this.items.length == 0) return;
      if (this.items.indexOf(secItem) != -1) {
        this.removeItems_temp.push(secItem);
        this.removeSecItemFrequently();
      }
    },
    */
    clearAllSecItems() {
      // 清理全局数据
      let listMap = null;
      const items = ListConfig.fetchItems();
      items.forEach((el) => {
        if (el.listId == this.listId) {
          listMap = el;
        }
      });
      if (!listMap) return [];

      const appDataItems = DataTask.fetchAllAppDataItems()
      appDataItems.forEach((el) => {
        DataTask.cleanAllItems(listMap.itemsFunc(el));
      });

      if (this.items.length == 0) return;
      this.items.splice(0, this.items.length);
      this.allowScrollAuto = true;
      this.reloadList();
    },
    removeSecItemFrequently() {
      clearTimeout(this.removeSecItemTimer);
      this.removeSecItemTimer = setTimeout(() => {
        this.removeSecItemInstant();
      }, 250);
    },
    removeSecItemInstant() {
      if (this.removeItems_temp.length == 0) {
        return;
      }
      let listMap = null;
      const items = ListConfig.fetchItems();
      items.forEach((el) => {
        if (el.listId == this.listId) {
          listMap = el;
        }
      });
      if (!listMap) return;

      const arr = this.removeItems_temp;
      arr.forEach((el) => {
        const items = listMap.itemsFunc(el.appDataItem)
        let removeI = items.indexOf(el) 
        if (removeI != -1) {
          items.splice(removeI, 1)
        }

        removeI = this.items.indexOf(el);
        if (removeI != -1) {
          this.items.splice(removeI, 1);
        }
      });
      this.removeItems_temp.splice(0, this.removeItems_temp.length);
      this.reloadList();
    },
    deleteStore(secItems){
      if (!secItems || secItems.length == 0 ) {
        return
      }
      const fetchRes = this.checkSpecialList();
      if (!fetchRes) {
        return
      }
      const newSecItems = []
      secItems.forEach(secItem => {
        newSecItems.push({
          colItems: secItem.colItems,
          rowItems: secItem.rowItems
        })
      });
      // 向原生发送socket 删除该条memory storage
      const dataKey = fetchRes.sendDeleteDataKey
      const sendData = {
        msgType: 9,
        msgSubType: fetchRes.sendDeleteType
      }
      sendData[dataKey] = newSecItems;
      // console.log(JSON.parse(JSON.stringify(sendData)))
      MySocket.sendData(JSON.parse(JSON.stringify(sendData)));
    },
    autoDelete(){
      if (!this.autoDeleteEnable || !this.allowAutoDelete()) {
        return
      }
      let deleteItems = this.filterItems(this.fetchAllItems()); 
      if (this.items.length > 0) {
        deleteItems = deleteItems.concat(this.items)
      }
      this.removeSecItems(deleteItems) 
      this.allowScrollAuto = true;
    },
    allowAutoDelete(){
      return (this.checkSpecialList() ? false : true)
    },
    reloadListWhenSelectApp() {
      let fetchRes = this.checkSpecialList();
      if (fetchRes) {
        this.clearAllSecItems()
      }
      this.reloadListWhenShow();
    },
    reloadListWhenSearch() {
      this.reloadListWhenShow(true);
    },
    reloadListWhenCloseSearch() {
      this.reloadListWhenShow(true);
    },
    reloadListWhenRefresh() {
      let fetchRes = this.checkSpecialList();
      if (fetchRes) {
        this.clearAllSecItems();
        MySocket.sendData({
          msgType: 9,
          msgSubType: fetchRes.sendType,
        });
        return;
      }
      this.reloadListWhenShow();
    },
    checkSpecialList() {
      let fetchRes = null;

      const listIds = ListConfig.refreshListIds();
      for (let index = 0; index < listIds.length; index++) {
        const el = listIds[index];
        if (el.listId == this.listId) {
          fetchRes = el;
          break;
        }
      }
      return fetchRes;
    },
    reloadListWhenShow(isSearch = false) {
      if (isSearch){
        this.items = this.filterItems(this.fetchAllItems());
        this.reloadList();
        return;
      }
      let fetchRes = this.checkSpecialList();
      if (fetchRes) {
        this.reloadListWhenRefresh();
        return;
      }
      this.items = this.filterItems(this.fetchAllItems());
      this.reloadList();
    },
    reloadListFrequently() {
      clearTimeout(this.reloadListFrequentlyTimer);
      this.reloadListFrequentlyTimer = setTimeout(() => {
        this.reloadList();
      }, 150);
    },
    reloadList() {
      if (!this.allowScrollAuto) {
        return;
      }
      this.$nextTick(() => {
        this.scrollListToBottomAuto();
      });
    },
    calculateListTopAdjoinDom() {
      // 计算list上边相邻组件的位置
      return HtmlWindow.clientRealRect(
        Dom.getElementById(this.listId + "input-wrap")
      );
    },
    calculateScroll() {
      const rowDomRect =
        this.items.length <= 0
          ? { bottom: 0 }
          : HtmlWindow.clientRealRect(
              Dom.getElementById(
                this.listId + "-row-wrap-id-" + (this.items.length - 1)
              )
            );

      const opAdjoinRect = this.calculateListTopAdjoinDom();
      const listRect = HtmlWindow.clientRealRect(
        Dom.getElementById(this.listId)
      );
      // 浏览器向上滑动为负值
      const listWrapH = this.listWrapH;
      // const listH = listWrapH - this.calculateListTopAdjoinDom().height;
      const listH = this.listH;
      const listOffSetTopY = -(listRect.top - opAdjoinRect.bottom);
      let listOffSetBottomY = 0;
      if (rowDomRect.bottom - opAdjoinRect.bottom <= listH) {
        listOffSetBottomY = 0;
      } else {
        listOffSetBottomY = rowDomRect.bottom - opAdjoinRect.bottom - listH;
      }
      const listContentH = listOffSetTopY + listH + listOffSetBottomY;
      // console.log(
      //   'listRectTop',
      //   listRect.top,
      //   'opAdjoinRectBottom',
      //   opAdjoinRect.bottom,
      //   'listH: ',
      //   listH,
      //   'listWrapH: ',
      //   listWrapH,
      //   'listOffSetTopY: ',
      //   listOffSetTopY,
      //   'listOffSetBottomY: ',
      //   listOffSetBottomY,
      //   'listContentH: ',
      //   listContentH,
      //   listContentH == listOffSetTopY + listOffSetBottomY + listH
      // );
      return {
        listH,
        listWrapH,
        listOffSetTopY,
        listOffSetBottomY,
        listContentH,
      };
    },
    calculateOriginLocationIdx() {
      // console.log("calculateOriginLocationIdx 1", this.listId);
      if (this.allowScrollAuto || this.items.length <= 0) {
        this.originLocationIdx = -1;
        return;
      }
      const {
        listH,
        listWrapH,
        listOffSetTopY,
        listOffSetBottomY,
        listContentH,
      } = this.calculateScroll();

      // console.log("calculateOriginLocationIdx 2", this.listId);
      if (listContentH <= 0 || listH <= 0) {
        this.originLocationIdx = -1;
        return;
      }
      // console.log("calculateOriginLocationIdx 3", this.listId);
      if (listContentH <= listH) {
        this.originLocationIdx = -1;
        return;
      }
      // console.log("calculateOriginLocationIdx 4", this.listId);
      const opAdjoinRect = this.calculateListTopAdjoinDom();
      const totalCount = this.items.length;
      let targetIdx = -1;
      for (let idx = 0; idx < totalCount; idx++) {
        if (idx >= totalCount - 1) {
          continue;
        }
        const rowDomRect = HtmlWindow.clientRealRect(
          Dom.getElementById(this.listId + "-row-wrap-id-" + idx)
        );
        const nextRowDomRect = HtmlWindow.clientRealRect(
          Dom.getElementById(this.listId + "-row-wrap-id-" + (idx + 1))
        );
        // console.log(
        //   idx,
        //   rowDomRect.top,
        //   opAdjoinRect.bottom,
        //   rowDomRect.top - opAdjoinRect.bottom
        // );
        if (rowDomRect.top - opAdjoinRect.bottom >= 0) {
          targetIdx = idx;
          break;
        }
        if (
          rowDomRect.top - opAdjoinRect.bottom < 0 &&
          nextRowDomRect.top - opAdjoinRect.bottom >= 0
        ) {
          targetIdx = idx;
          break;
        }
      }
      console.log("targetIdx", targetIdx);
      this.originLocationIdx = targetIdx;
    },
    scrollToOriginLocation() {
      if (this.items.length <= 0) {
        return;
      }
      let targetIdx = this.originLocationIdx;
      if (targetIdx == -1) {
        targetIdx = this.items.length - 1;
      }
      const rowDomId = this.listId + "-row-wrap-id-" + targetIdx;
      ScrollOp.scrollDomToTopById(rowDomId, false);
    },
    updateScrollAuto() {
      if (this.scrollStatus != 0) {
        this.allowScrollAuto = false;
        // console.log('allowScrollAuto 1', this.allowScrollAuto);
        return;
      }
      if (this.items.length <= 0) {
        this.allowScrollAuto = true;
        // console.log('allowScrollAuto 2', this.allowScrollAuto);
        return;
      }
      const {
        listH,
        listWrapH,
        listOffSetTopY,
        listOffSetBottomY,
        listContentH,
      } = this.calculateScroll();
      if (listContentH <= 0 || listH <= 0) {
        this.allowScrollAuto = true;
        // console.log('allowScrollAuto 3', this.allowScrollAuto);
        return;
      }
      if (listContentH <= listH) {
        this.allowScrollAuto = true;
        // console.log('allowScrollAuto 4', this.allowScrollAuto);
        return;
      }
      if (listOffSetTopY >= listContentH - listH - 10) {
        this.allowScrollAuto = true;
        // console.log('allowScrollAuto 5', this.allowScrollAuto);
        return;
      }
      this.allowScrollAuto = false;
      // console.log('allowScrollAuto 6', this.allowScrollAuto);
    },
    scrollListToBottomAuto() {
      // console.log('scrollListToBottomAuto')
      this.cancelScrollEvent();
      this.execScrollTimer = setTimeout(() => {
        // console.log('scrollListToBottomAutoInternal')
        this.scrollListToBottomAutoInternal();
      }, 150);
    },
    scrollListToBottomAutoInternal() {
      if (!this.allowScrollAuto || this.scrollStatus != 0) {
        return;
      }
      this.scrollListToBottomInstant();
    },
    scrollListToBottomCode() {
      this.cancelScrollEvent();
      this.execScrollTimer = setTimeout(() => {
        this.scrollListToBottomInstant();
      }, 100);
    },
    scrollListToBottomInstant() {
      this.allowScrollAuto = true;
      if (this.items.length <= 0) return;
      const rowDomId = this.listId + "-row-wrap-id-" + (this.items.length - 1);
      ScrollOp.scrollDomToBottomById(rowDomId);
    },
    scrollListToTopCode() {
      this.cancelScrollEvent();
      this.execScrollTimer = setTimeout(() => {
        this.scrollListToTopInstant();
      }, 100);
    },
    scrollListToTopInstant() {
      if (this.items.length <= 0) return;
      const rowDomId = this.listId + "-row-wrap-id-" + 0;
      ScrollOp.scrollDomToBottomById(rowDomId);

      const {
        listH,
        listWrapH,
        listOffSetTopY,
        listOffSetBottomY,
        listContentH,
      } = this.calculateScroll();
      if (listContentH <= 0 || listH <= 0) {
        this.allowScrollAuto = true;
        return;
      }
      if (listContentH <= listH) {
        this.allowScrollAuto = true;
        return;
      }
      this.allowScrollAuto = false;
    },
    scrollAnimated(){
      const fetchRes = this.checkSpecialList();
      return fetchRes ? false : true
    },
    cancelScrollEvent() {
      clearTimeout(this.execScrollTimer);
    },
    clickRow(item) {
      item.clickRow(item);
    },
    clickDeleteRow(item, idx) {
      // this.deleteRowHighlight = true;
      // setTimeout(() => {
      //   this.deleteRowHighlight = false;
      // }, 200);
      if (item) {
        this.deleteStore([item])
        this.removeSecItems([item])
      }
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.list-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  // background-color: orange;
}
.listCount{
  position: absolute;
  top: 0px;
  right: 0px;
  padding-right: 5px;
}
.input-wrap {
  z-index: 99;
  margin: 0px;
  padding: 0px;
  position: fixed;
  left: 0px;
  top: 0px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  overflow: hidden;
}
.input {
  margin: 0px;
  padding: 0px 0px 0px 5px;
  width: 100%;
  height: 100%;
  border-width: 0px;
  // border: '0px solid #999';
}
.list {
  margin-right: 0px;
  margin-bottom: 0px;
  margin-left: 0px;
  padding: 0px;
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}
.row-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
  position: relative;
}
.row-wrap :active {
  background-color: #efeff4;
}
.row-wrap :hover {
  background-color: #efeff4;
}
.row-delete{
  position: absolute;
  right: 0px;
  bottom: 0px;
  padding: 5px;
  opacity: 0.5;
}
.row {
  margin: 0px;
  padding: 0px;
  width: 100%;
}
.row-content{
  margin: 0px;
  padding: 0px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: stretch;
  justify-content: flex-start;
}
.col {
  margin: 0px;
  font-family: normal;
  white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  word-wrap: break-word;
}
.col-html {
  margin: 0px;
  font-family: normal;
  // white-space: pre-wrap;
  // white-space: -moz-pre-wrap;
  // white-space: -pre-wrap;
  // white-space: -o-pre-wrap;
  word-wrap: break-word;
}
// pre标签默认样式
.pre-default {
  display: block;
  font-family: monospace;
  white-space: pre;
  margin: 1em 0px;
}
/*
white-space: pre，white-space的值描述：

normal：默认。空白会被浏览器忽略。
pre：空白会被浏览器保留。其行为方式类似 HTML 中的 <pre>标签。
nowrap：文本不会换行，文本会在在同一行上继续，直到遇到 <br> 标签为止。
pre-wrap：保留空白符序列，但是正常地进行换行。
pre-line：合并空白符序列，但是保留换行符。
inherit：规定应该从父元素继承 white-space 属性的值。
*/
</style>