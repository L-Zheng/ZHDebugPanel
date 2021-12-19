<template>
  <div
    class="detail"
    :style="{
      top: layoutConfig.optionH + 'px',
      width: layoutConfig.detailW,
      height: contentPercentH,
      border: layoutConfig.border,
    }"
  >
    <div
      class="option-wrap"
      :style="{
        'border-bottom': items.length == 0 ? '' : layoutConfig.border,
      }"
    >
      <div
        class="title-wrap"
        v-for="(item, idx) in items"
        :key="idx"
        @click="clickIndex(idx)"
        :style="{
          color: item.selected
            ? colorConfig.selectColor
            : colorConfig.defaultColor,
        }"
      >
        <span>{{ item.title }}</span>
      </div>
    </div>
    <!-- v-html="selectItem.contentHtml" -->
    <div class="content-html" v-if="selectItem.useHtml" v-html="selectItem.contentHtml">
      <!-- <p style="margin:0px;padding:0px;
      white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  word-wrap: break-word;">
        <span style="font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E; color: rgba(255, 255, 0, 1.0);">
          URL:
        </span>
        <span style="font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000;">
          https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
        </span>
      </p>
      <p style="margin:0px;padding:0px;
      white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  word-wrap: break-word;">
        <span style="font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;">
          Method:
        </span>
        <span style="font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000;">
          少时诵诗书所所阿法狗多多多多多多多多多
        </span>
      </p>
      <pre style="font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; 
      width:100%;
      margin:0px;
      padding:0px;
      white-space: pre-wrap; 
      white-space: -moz-pre-wrap; 
      white-space: -pre-wrap; 
      white-space: -o-pre-wrap; 
      word-wrap: break-word;
  overflow-x: scroll;
  overflow-y: scroll;">{{`{\n  \"datas\" : {\n    \"outsideTestList\" : [\n      {\n        \"id\" : 158553,\n        \"description\" : \"fix: \U5b89\U5353\U4fa7\U6ed1\U8fd4\U56de\U4fee\U6539\",\n        \"version\" : \"1.1.3\",\n        \"envVersion\" : \"trial\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/63738435428532228213756853.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T08:57:09+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : \"\",\n        \"md5\" : \"f791df1ef79a0c38f84acddad7b84f17\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T15:17:42+08:00\"\n      }\n    ],\n    \"insideTestList\" : [\n      {\n        \"id\" : 12850,\n        \"description\" : \"\",\n        \"version\" : \"1.0.0\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/6369188836445762501763538281.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2019-04-26T15:12:45+08:00\",\n        \"packSize\" : 0,\n        \"appVersion\" : null,\n        \"md5\" : \"dbaecab61ed575a48fcfec0e9b4733ed\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2019-04-26T15:12:45+08:00\"\n      },\n      {\n        \"id\" : 158552,\n        \"description\" : \"1\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/6373843530850078251838441440.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T08:55:09+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : null,\n        \"md5\" : \"f1ce5fcf9332bdad5d1fbf9ca57d1a88\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T08:55:09+08:00\"\n      },\n      {\n        \"id\" : 21814,\n        \"description\" : \"\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/636966463634352500508397342.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2019-06-20T16:52:44+08:00\",\n        \"packSize\" : 0,\n        \"appVersion\" : null,\n        \"md5\" : \"c250b152769761eb5bafef6924fa3a19\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2019-06-20T16:52:44+08:00\"\n      },\n      {\n        \"id\" : 171325,\n        \"description\" : \"111\",\n        \"version\" : \"11\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/637438234639198919428464905.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-12-17T17:37:44+08:00\",\n        \"packSize\" : 1711.97,\n        \"appVersion\" : null,\n        \"md5\" : \"2315f6985b042e87800f0589daad53f0\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-12-17T17:37:44+08:00\"\n      },\n      {\n        \"id\" : 79403,\n        \"description\" : \"\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/6371658350128087501243178509.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-02-06T10:58:21+08:00\",\n        \"packSize\" : 591.97000000000003,\n        \"appVersion\" : null,\n        \"md5\" : \"962d6f4321e29c5dc8e13671812a97ee\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-02-06T10:58:21+08:00\"\n      }\n    ],\n    \"AppletEntity\" : {\n      \"WealthId\" : null,\n      \"projectType\" : null,\n      \"status\" : 1,\n      \"url\" : null,\n      \"company\" : \"\U5929\U5929\U5c0f\U7a0b\U5e8f\",\n      \"companyNo\" : \"99fd97a920db491fbcaa3726ea0774ac\",\n      \"updateTime\" : \"2020-12-17T17:37:44+08:00\",\n      \"icon\" : \"https://j2.dfcfw.com/resource/uploadimg/86c9a39519d94df4a4e58199e741accd.png\",\n      \"appVersion\" : null,\n      \"isOfficial\" : 1,\n      \"version\" : null,\n      \"appName\" : \"\U57fa\U91d1FM\",\n      \"IsAllowCollect\" : false,\n      \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n      \"md5\" : null,\n      \"CompanyBaseSetting\" : {\n        \"DownloadUrl\" : \"https://j5.dfcfw.com/\",\n        \"RequestUrl\" : \"https://api.dongcaibaoxian.com\",\n        \"requestWhiteList\" : [\n          \"https://api.dongcaibaoxian.com\"\n        ],\n        \"UploadUrl\" : null,\n        \"uploadWhiteList\" : [\n\n        ],\n        \"downloadWhiteList\" : [\n          \"https://j5.dfcfw.com\"\n        ]\n      },\n      \"miniWhiteList\" : {\n        \"uploadWhiteList\" : [\n\n        ],\n        \"requestWhiteList\" : [\n          \"https://api.dongcaibaoxian.com\"\n        ],\n        \"downloadWhiteList\" : [\n          \"https://j5.dfcfw.com\"\n        ]\n      },\n      \"WealthName\" : null,\n      \"WealthIcon\" : null,\n      \"showType\" : 1,\n      \"description\" : \"\U57fa\U91d1\U5e72\U8d27\U3001\U884c\U60c5\U89e3\U8bfb\Uff0c\U8da3\U5473\U8f7b\U677e\U542c\U3002\"\n    },\n    \"productList\" : [\n      {\n        \"id\" : 158553,\n        \"description\" : \"fix: \U5b89\U5353\U4fa7\U6ed1\U8fd4\U56de\U4fee\U6539\",\n        \"version\" : \"1.1.3\",\n        \"envVersion\" : \"release\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.fund.eastmoney.com/resource/uploadzip/63738435428532228213756853.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T15:17:42+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : \"6.4.6\",\n        \"md5\" : \"f791df1ef79a0c38f84acddad7b84f17\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T15:17:42+08:00\"\n      }\n    ],\n    \"CompanyBaseSetting\" : {\n      \"DownloadUrl\" : \"https://j5.dfcfw.com/\",\n      \"RequestUrl\" : \"https://api.dongcaibaoxian.com\",\n      \"requestWhiteList\" : [\n        \"https://api.dongcaibaoxian.com\"\n      ],\n      \"UploadUrl\" : null,\n      \"uploadWhiteList\" : [\n\n      ],\n      \"downloadWhiteList\" : [\n        \"https://j5.dfcfw.com\"\n      ]\n    }\n  },\n  \"resultCode\" : 0,\n  \"resultMessage\" : \"\U6210\U529f\"\n}` }}</pre> -->
    
    </div>
    <!-- pre标签要在一行内写完  否则开头和结尾会有多余的空格 -->
    <pre v-else
      class="content"
      :style="{
        color: colorConfig.defaultColor,
      }"
      >{{ selectItem.content }}</pre
    >
    <div class="bottom-wrap" :style="{
        'background-color': colorConfig.bgColor,
    }">
        <div
        class="bottom-title-wrap"
        v-for="(item, index) in bottomOptions"
        :key="index"
        :style="{
          'background-color': item.highlight ? colorConfig.highlightColor : '',
          color: item.selected
            ? colorConfig.selectColor
            : colorConfig.defaultColor,
        }"
        @click="clickBottomOption(item)"
      >
        <div :class="`iconfont ${item.icon}`"></div>
      </div>
    </div>
  </div>
</template>
<script>
import JSTool from "../base/JSTool.js";
import LayoutConfig from "../data/LayoutConfig.js";
import Color from "../data/Color.js";
import HtmlWindow from "../base/HtmlWindow.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      layoutConfig: {},
      colorConfig: {},
      contentPercentH: "",
      highlight: false,
      secItem: null,
      items: [],
      lastSelectIdx: 0,
      selectItem: {},
      timer: null,
      bottomOptions: []
    };
  },
  created() {
    this.layoutConfig = LayoutConfig;
    this.colorConfig = Color;
    this.configBottomOptionItems();
  },
  computed: {},
  mounted() {
    this.getContentH();
    window.addEventListener(
      "resize",
      () => {
        this.getContentH();
      },
      false
    );
  },
  methods: {
    getContentH() {
      const bodyRect = HtmlWindow.client();
      const windowH = bodyRect.height;
      const otherH = this.layoutConfig.optionH;
      this.contentH = windowH - otherH - 10;
      this.contentPercentH =
        ((this.contentH * 1.0) / (windowH * 1.0)) * 100 + "%";
      return this.contentPercentH;
    },
    reloadItems(secItem) {
      const items = secItem.detailItems;
      if (!JSTool.isArray(items)) return;
      if (secItem != this.secItem) {
        this.selectItem = {content: '载入中...', contentHtml: '载入中...'}
      }
      this.secItem = secItem;
      clearTimeout(this.timer);
      // 然后又创建一个新的 setTimeout, 这样就能保证interval 间隔内如果时间持续触发，就不会执行 fn 函数
      this.timer = setTimeout(() => {
        this.items = items;
        this.clickIndex(this.lastSelectIdx);
        this.$nextTick(() => {});
      }, 150);
    },
    clickIndex(index) {
      if (index >= this.items.length) {
        index = 0;
      }
      this.items.forEach((el) => {
        el.selected = false;
      });
      this.items[index].selected = true;
      this.lastSelectIdx = index;
      this.selectItem = this.items[index];
    },
    configBottomOptionItems(){
      this.bottomOptions = [
        {
          icon: "icon-copy",
          highlight: false,
          click: () => {
            if (this.secItem) {
              this.secItem.pasteboardCopy(this.secItem);
            }
          },
        },
      ]
    },
    clickBottomOption(item) {
      item.highlight = true;
      setTimeout(() => {
        item.highlight = false;
      }, 200);
      item.click();
    },
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.detail {
  margin: 0px;
  padding: 0px;
  position: fixed;
  right: 10px;
  // background-color: cyan;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}
.option-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
  // background-color: cyan;
}
.title-wrap {
  // height: 100%;
  margin: 5px 0px;
  padding: 0px 5px;
  // background-color: orange;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.content {
  margin: 1%;
  padding: 0px;
  width: 98%;
  height: 100%;
  font-family: normal;
  white-space: pre-wrap;
  white-space: -moz-pre-wrap;
  white-space: -pre-wrap;
  white-space: -o-pre-wrap;
  word-wrap: break-word;
  overflow-x: scroll;
  overflow-y: auto;
}
.content-html{
  margin: 1%;
  padding: 0px;
  width: 98%;
  height: 100%;
  // font-family: normal;
  // white-space: pre-line;
  // word-wrap: break-word;
  overflow-x: scroll;
  overflow-y: auto;
}
.bottom-wrap{
  margin: 0px;
  padding: 0px;
  width: 100%;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
}
.bottom-title-wrap {
  padding: 10px;
  margin: 0px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
</style>
