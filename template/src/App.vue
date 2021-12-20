<template>
  <div class="main-wrap">
    <ToastPop ref="toastPop"></ToastPop>
    <Option ref="option" :items="optionItems" @clickOptionItem="clickOptionItem"></Option>
    <Detail ref="detail"></Detail>
    <Content :items="optionItems" ref="content"></Content>
    <Connect
      ref="connect" @clipboardPermiss="clipboardPermiss" @startConnect="startConnect"
    ></Connect>
  </div>
</template>

<script>
import Vue from "vue";
import qs from "qs";

import MySocket from "./debugPanel/base/Socket.js";
import JSTool from "./debugPanel/base/JSTool.js";
import ScrollOp from "./debugPanel/base/ScrollOp.js";
import Mouse from "./debugPanel/base/Mouse.js";
import DataTask from "./debugPanel/data/DataTask.js";
import ListConfig from "./debugPanel/data/ListConfig.js";
import ToastTool from "./debugPanel/base/ToastTool.js";

import ToastPop from "./debugPanel/toastPop/toastPop.vue";
import Option from "./debugPanel/option/option.vue";
import Content from "./debugPanel/content/content.vue";
import Connect from "./debugPanel/content/connect.vue";
import Detail from "./debugPanel/detail/detail.vue";
function preventDefault(e) {
  e.preventDefault();
}

var vm = {
  name: "app",
  components: {
    ToastPop,
    Option,
    Content,
    Connect,
    Detail,
  },
  props: {},
  data() {
    return {
      optionItems: [],
      socket: null,
      timerCount: 0
    };
  },
  created() {
    this.configVue();
    ScrollOp.listenScrollEvent();
    Mouse.listenMouseEvent();
    ToastTool.registerToast((title, clickOp = null, type = 'default') => {
      this.$refs.toastPop.show(title, clickOp, type);
    })
    this.optionItems = ListConfig.fetchItems();
  },
  computed: {},
  mounted() {
    const isLocalTest = false
    if (isLocalTest) {
      setTimeout(() => {
        this.clickOptionItem(this.optionItems[0]);
        this.startTimer();
      }, 1000)
      return;
    }
      this.$refs.connect.show()
    setTimeout(() => {
      this.clickOptionItem(this.optionItems[0]);
      // 建立socket连接 开始接收数据
      // this.startTimer();
      // this.startConnectSocket();
    }, 1000);
    // this.$refs.toastPop.show("啊啊啊啊啊啊");
  },
  methods: {
    configVue() {
      Vue.config.errorHandler = ((oriFunc) => {
        return function (err, vm, info) {
          /**发送至Vue*/
          if (oriFunc) oriFunc.call(null, err, vm, info);
          /**发送至WebView*/
          if (window.onerror) window.onerror.call(null, err);
        };
      })(Vue.config.errorHandler);
    },
    getUrlParamsFromUrl(url) {
      var curUrl = url;
      if (!url) {
        // tslint:disable-next-line: strict-type-predicates
        if (typeof location === "object") {
          curUrl = location.href;
        } else {
          return {};
        }
      }
      var param = {};
      var reg = /(\?[^\?\#]*)/gi;
      var result = curUrl.match(reg);
      if (result) {
        result.forEach(function (str) {
          str = str.slice(1);
          param = Object.assign({}, param, qs.parse(str));
        });
        return param;
      } else return param;
    },
    readFile() {
      const selectedFile =
        "/Users/em/Desktop/My/Develop/Code/ZHCode/GitHubCode/ZHDebugPanel/template/release/pages.json";

      const input = window.document.getElementById("file-input");
      input.addEventListener(
        "change",
        () => {
          console.log("input.files", input.files[0]);
          const reader = new FileReader();
          reader.readAsText(input.files[0], "utf8"); // input.files[0]为第一个文件
          reader.onload = () => {
            console.log(
              "reader.result",
              reader.result,
              JSTool.dataType(reader.result)
            );
            console.log(JSON.parse(reader.result));
          };
        },
        false
      );
    },
    clipboardPermiss(permission){
      if (!permission) {
          this.$refs.toastPop.show("剪切板权限被禁止, 自动填充失败");
      }
    },
    startConnect(socketUrl){
      console.log('socketUrl', socketUrl)
      this.startConnectSocket(socketUrl)
    },
    startConnectSocket(socketUrl) {
      // const urlParams = this.getUrlParamsFromUrl();
      // // console.log(urlParams);
      // const socketUrl = urlParams["socketUrl"];
      if (!socketUrl) return;

      const socket = new WebSocket(socketUrl);
      socket.addEventListener("open", (msg) => {
        console.log("socket opened");
        this.$refs.toastPop.show("连接成功");
        socket.send(
          JSON.stringify({
            msgType: -1,
            clientId: "h5Client",
          })
        );
      this.$refs.connect.hide()
      });
      socket.addEventListener("close", (msg) => {
        this.$refs.toastPop.show("连接失败或关闭");
        console.log('socket close', msg)
      });
      socket.addEventListener("error", (msg) => {
        this.$refs.toastPop.show("连接错误");
        console.log('socket error', msg)
      });
      socket.addEventListener("message", (msg) => {
        let receiveData = msg.data;
        if (!JSTool.isString(receiveData)) {
          return;
        }
        receiveData = JSON.parse(receiveData);
        const msgType = receiveData.msgType;
        if (msgType != 8) {
          return;
        }
        const msgSubType = receiveData.msgSubType;
        if (msgSubType != 1 && msgSubType != 2) {
          return
        }
        // 清除日志信息
        if (msgSubType == 2) {
          // 如果当前列表正在显示，刷新列表
          const listItems = ListConfig.fetchItems()
          listItems.forEach(el => {
            this.$refs.content.$refs[el.listId].autoDelete();
          });
          return
        }
        const listData = receiveData.data;
        const listId = listData.listId;
        const secItem = listData.msg;
        const appItem = listData.appItem;
        // console.log(listId, secItem);
        if (!listId || !JSTool.isString(listId)) {
          return;
        }
        secItem.clickRow = (secItemTemp) => {
          this.$refs.detail.reloadItems(secItemTemp);
        };
        secItem.pasteboardCopy = (secItemTemp) => {
          this.copyToPasteboard(secItemTemp)
        };
        if (listId == 'exception-list' || listId == 'sdkError-list') {
          let targetOptionItem = null;
          this.optionItems.forEach(element => {
            if (element.listId == listId) {
              targetOptionItem = element
            }
          });
          if (targetOptionItem && !targetOptionItem.selected) {
            this.$refs.toastPop.show(`${appItem.appName}, 检测到异常`, () => {
                this.$refs.option.clickTitle(targetOptionItem)
            }, 'error');
          }
        }
        // 追加数据
        this.addData(listId, appItem, secItem);
      });
      // socket.close()
      // socket.send()
      this.socket = socket;

      MySocket.registerSendEvent((data) => {
        this.socket.send(JSON.stringify(data));
      });
    },
    clickOptionItem(item) {
      if (item.selected) return;
      this.optionItems.forEach((el) => {
        el.selected = false;
      });
      item.selected = true;
      this.$refs.content.showList(item.listId);
    },
    startTimer() {
      setInterval(() => {
        if (this.timerCount > 10) {
          return
        }
        this.timerCount++;
        this.testRandomData()
        // this.testNetworkData()
      }, 400);
    },
    testRandomData(){
        const second = new Date().getSeconds();
        // 哪个应用的数据
        const appItem = {};
        appItem.appId = "App-" +  + parseInt(Math.random() * 1000) % 6;
        appItem.appName = appItem.appId;
        // 构造数据
        const page = 'page-' + parseInt(Math.random() * 1000) % 11
        const logType = parseInt(Math.random() * 1000) % 5 + 1
        const logTypeDesc = {
          1: 'log',
          2: 'info',
          3: 'debug',
          4: 'warning',
          5: 'error'
        }[logType]
        const logTypeColor = {
          1: '#000000',
          2: '#000000',
          3: '#000000',
          4: '#FFD700',
          5: '#DC143C'
        }[logType]
        const secItem = {
          filterItem: {
            appItem: appItem,
            page: page,
            outputItem: {
              type: logType
            }
          },
          enterMemoryTime: new Date().getTime(),
          open: true,
          colItems: [],
          rowItems: [
            {
              useHtml: true,
              colItems: [
                {
                  title: "aa" + second,
                  titleHtml: `<span>aa${second}</span>`,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: 'https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec',
                  titleHtml: `<span>https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec</span>`,
                  percent: 0.4,
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: page,
                  titleHtml: `<span>${page}</span>`,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
                {
                  title: appItem.appName,
                  titleHtml: `<span>${appItem.appName}</span>`,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
                {
                  title: logTypeDesc,
                  titleHtml: `<span>${logTypeDesc}</span>`,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
              ],
            },
          ],
          detailItems: [
            {
              title: second,
              content: 'https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec',
              useHtml: true,
              contentHtml: `<span>https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
              你好
              </span>`,
              selected: false,
            },
            {
              title: second,
              content: "描述" + second,
              useHtml: true,
              contentHtml: `<span>描述${second}</span>`,
              selected: false,
            },
            {
              title: second,
              content: "描述" + second,
              useHtml: true,
              contentHtml: `<span>描述${second}</span>`,
              selected: false,
            },
          ],
          clickRow: (secItem) => {
            this.$refs.detail.reloadItems(secItem);
          },
          pasteboardCopy: (secItemTemp) => {
            this.copyToPasteboard(secItemTemp)
          }
        };
        // 追加数据
        this.addData("log-list", appItem, secItem);
    },
    testNetworkData(){
        const second = new Date().getSeconds();
        // 哪个应用的数据
        const appItem = {};
        appItem.appId = "App-" +  + parseInt(Math.random() * 1000) % 6;
        appItem.appName = appItem.appId;
        // 构造数据
        const page = 'page-' + parseInt(Math.random() * 1000) % 11
        const logType = parseInt(Math.random() * 1000) % 5 + 1
        const logTypeDesc = {
          1: 'log',
          2: 'info',
          3: 'debug',
          4: 'warning',
          5: 'error'
        }[logType]
        const logTypeColor = {
          1: '#000000',
          2: '#000000',
          3: '#000000',
          4: '#FFD700',
          5: '#DC143C'
        }[logType]
        const secItem = {
          filterItem: {
            appItem: appItem,
            page: page,
            outputItem: {
              type: logType
            }
          },
          enterMemoryTime: new Date().getTime(),
          open: true,
          colItems: [],
          rowItems: [
            {
              colItems: [
                {
                  title: "aa" + second,
                  titleHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-col-0-1639288107135695-783-228 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
p.p2-col-0-1639288107135695-783-228 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
span.s1-col-0-1639288107135695-783-228 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-col-0-1639288107135695-783-228"><span class="s1-col-0-1639288107135695-783-228">https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletP</span></p>
<p class="p2-col-0-1639288107135695-783-228"><span class="s1-col-0-1639288107135695-783-228">...&#x70B9;&#x51FB;&#x5C55;&#x5F00;</span></p>
</body>
</html>`,
                  percent: 0.7,
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: 'https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec',
                  titleHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-col-1-1639288107148727-736-316 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
span.s1-col-1-1639288107148727-736-316 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-col-1-1639288107148727-736-316"><span class="s1-col-1-1639288107148727-736-316">GET</span></p>
</body>
</html>`,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: page,
                  titleHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-col-2-1639288107155670-909-463 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
span.s1-col-2-1639288107155670-909-463 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-col-2-1639288107155670-909-463"><span class="s1-col-2-1639288107155670-909-463">200</span></p>
</body>
</html>`,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "blue",
                },
              ],
            },
          ],
          detailItems: [
            {
              title: '概要',
              content: `URL: https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec
Method: GET
Status Code: 200
Start Time: 2021-12-12 14:05:30.809
End Time: 2021-12-12 14:05:31.134
Duration: 324.284ms`,
              contentHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-detail-0-1639288107162159-412-655 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
p.p2-detail-0-1639288107162159-412-655 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
span.s1-detail-0-1639288107162159-412-655 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0cc82e}
span.s2-detail-0-1639288107162159-412-655 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
span.s3-detail-0-1639288107162159-412-655 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px}
span.s4-detail-0-1639288107162159-412-655 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000}
</style>
</head>
<body>
<p class="p1-detail-0-1639288107162159-412-655"><span class="s1-detail-0-1639288107162159-412-655">URL: </span><span class="s2-detail-0-1639288107162159-412-655">https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec</span></p>
<p class="p2-detail-0-1639288107162159-412-655"><span class="s3-detail-0-1639288107162159-412-655">Method: </span><span class="s4-detail-0-1639288107162159-412-655">GET</span></p>
<p class="p2-detail-0-1639288107162159-412-655"><span class="s3-detail-0-1639288107162159-412-655">Status Code: </span><span class="s4-detail-0-1639288107162159-412-655">200</span></p>
<p class="p1-detail-0-1639288107162159-412-655"><span class="s1-detail-0-1639288107162159-412-655">Start Time: </span><span class="s2-detail-0-1639288107162159-412-655">2021-12-12 13:48:26.812</span></p>
<p class="p1-detail-0-1639288107162159-412-655"><span class="s1-detail-0-1639288107162159-412-655">End Time: </span><span class="s2-detail-0-1639288107162159-412-655">2021-12-12 13:48:27.103</span></p>
<p class="p2-detail-0-1639288107162159-412-655"><span class="s3-detail-0-1639288107162159-412-655">Duration: </span><span class="s4-detail-0-1639288107162159-412-655">291.110ms</span></p>
</body>
</html>`,
              selected: false,
            },
            {
              title: '请求参数',
              content: `Request Query (In URL): 
{
  "appId" : "4e11280eef6a4277aa855e98eb385bec"
}
Request Query (In Body): 

Request Query (In BodyStream): 

`,
              contentHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-detail-1-1639288107180414-771-625 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
p.p2-detail-1-1639288107180414-771-625 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
p.p3-detail-1-1639288107180414-771-625 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e; min-height: 17.9px}
span.s1-detail-1-1639288107180414-771-625 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px}
span.s2-detail-1-1639288107180414-771-625 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-detail-1-1639288107180414-771-625"><span class="s1-detail-1-1639288107180414-771-625">Request Query (In URL):<span class="Apple-converted-space">&nbsp;</span></span></p>
<p class="p2-detail-1-1639288107180414-771-625"><span class="s2-detail-1-1639288107180414-771-625">{</span></p>
<p class="p2-detail-1-1639288107180414-771-625"><span class="s2-detail-1-1639288107180414-771-625"><span class="Apple-converted-space">&nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec"</span></p>
<p class="p2-detail-1-1639288107180414-771-625"><span class="s2-detail-1-1639288107180414-771-625">}</span></p>
<p class="p1-detail-1-1639288107180414-771-625"><span class="s1-detail-1-1639288107180414-771-625">Request Query (In Body):<span class="Apple-converted-space">&nbsp;</span></span></p>
<p class="p3-detail-1-1639288107180414-771-625"><span class="s1-detail-1-1639288107180414-771-625"></span><br></p>
<p class="p1-detail-1-1639288107180414-771-625"><span class="s1-detail-1-1639288107180414-771-625">Request Query (In BodyStream):<span class="Apple-converted-space">&nbsp;</span></span></p>
</body>
</html>`,
              selected: false,
            },
            {
              title: '响应数据',
              content: `Response Data: 
{
  "datas" : {
    "outsideTestList" : [
      {
        "id" : 158553,
        "description" : "fix: 安卓侧滑返回修改",
        "version" : "1.1.3",
        "envVersion" : "trial",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://j2.dfcfw.com/resource/uploadzip/63738435428532228213756853.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2020-10-16T08:57:09+08:00",
        "packSize" : 607.84000000000003,
        "appVersion" : "",
        "md5" : "f791df1ef79a0c38f84acddad7b84f17",
        "tabBar" : "0",
        "updateTime" : "2020-10-16T15:17:42+08:00"
      }
    ],
    "insideTestList" : [
      {
        "id" : 12850,
        "description" : "",
        "version" : "1.0.0",
        "envVersion" : "develop",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://mptest.1234567.com.cn/PhpUpload/uploadzip/6369188836445762501763538281.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2019-04-26T15:12:45+08:00",
        "packSize" : 0,
        "appVersion" : null,
        "md5" : "dbaecab61ed575a48fcfec0e9b4733ed",
        "tabBar" : "0",
        "updateTime" : "2019-04-26T15:12:45+08:00"
      },
      {
        "id" : 158552,
        "description" : "1",
        "version" : "1",
        "envVersion" : "develop",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://j2.dfcfw.com/resource/uploadzip/6373843530850078251838441440.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2020-10-16T08:55:09+08:00",
        "packSize" : 607.84000000000003,
        "appVersion" : null,
        "md5" : "f1ce5fcf9332bdad5d1fbf9ca57d1a88",
        "tabBar" : "0",
        "updateTime" : "2020-10-16T08:55:09+08:00"
      },
      {
        "id" : 21814,
        "description" : "",
        "version" : "1",
        "envVersion" : "develop",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://mptest.1234567.com.cn/PhpUpload/uploadzip/636966463634352500508397342.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2019-06-20T16:52:44+08:00",
        "packSize" : 0,
        "appVersion" : null,
        "md5" : "c250b152769761eb5bafef6924fa3a19",
        "tabBar" : "0",
        "updateTime" : "2019-06-20T16:52:44+08:00"
      },
      {
        "id" : 171325,
        "description" : "111",
        "version" : "11",
        "envVersion" : "develop",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://j2.dfcfw.com/resource/uploadzip/637438234639198919428464905.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2020-12-17T17:37:44+08:00",
        "packSize" : 1711.97,
        "appVersion" : null,
        "md5" : "2315f6985b042e87800f0589daad53f0",
        "tabBar" : "0",
        "updateTime" : "2020-12-17T17:37:44+08:00"
      },
      {
        "id" : 79403,
        "description" : "",
        "version" : "1",
        "envVersion" : "develop",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://mptest.1234567.com.cn/PhpUpload/uploadzip/6371658350128087501243178509.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2020-02-06T10:58:21+08:00",
        "packSize" : 591.97000000000003,
        "appVersion" : null,
        "md5" : "962d6f4321e29c5dc8e13671812a97ee",
        "tabBar" : "0",
        "updateTime" : "2020-02-06T10:58:21+08:00"
      }
    ],
    "AppletEntity" : {
      "WealthId" : null,
      "projectType" : null,
      "status" : 1,
      "url" : null,
      "company" : "天天小程序",
      "companyNo" : "99fd97a920db491fbcaa3726ea0774ac",
      "updateTime" : "2020-12-17T17:37:44+08:00",
      "icon" : "https://j2.dfcfw.com/resource/uploadimg/86c9a39519d94df4a4e58199e741accd.png",
      "appVersion" : null,
      "isOfficial" : 1,
      "version" : null,
      "appName" : "基金FM",
      "IsAllowCollect" : false,
      "appId" : "4e11280eef6a4277aa855e98eb385bec",
      "md5" : null,
      "CompanyBaseSetting" : {
        "DownloadUrl" : "https://j5.dfcfw.com/",
        "RequestUrl" : "https://api.dongcaibaoxian.com",
        "requestWhiteList" : [
          "https://api.dongcaibaoxian.com"
        ],
        "UploadUrl" : null,
        "uploadWhiteList" : [

        ],
        "downloadWhiteList" : [
          "https://j5.dfcfw.com"
        ]
      },
      "miniWhiteList" : {
        "uploadWhiteList" : [

        ],
        "requestWhiteList" : [
          "https://api.dongcaibaoxian.com"
        ],
        "downloadWhiteList" : [
          "https://j5.dfcfw.com"
        ]
      },
      "WealthName" : null,
      "WealthIcon" : null,
      "showType" : 1,
      "description" : "基金干货、行情解读，趣味轻松听。"
    },
    "productList" : [
      {
        "id" : 158553,
        "description" : "fix: 安卓侧滑返回修改",
        "version" : "1.1.3",
        "envVersion" : "release",
        "appId" : "4e11280eef6a4277aa855e98eb385bec",
        "url" : "https://j2.fund.eastmoney.com/resource/uploadzip/63738435428532228213756853.zip",
        "userId" : "",
        "userName" : "",
        "createTime" : "2020-10-16T15:17:42+08:00",
        "packSize" : 607.84000000000003,
        "appVersion" : "6.4.6",
        "md5" : "f791df1ef79a0c38f84acddad7b84f17",
        "tabBar" : "0",
        "updateTime" : "2020-10-16T15:17:42+08:00"
      }
    ],
    "CompanyBaseSetting" : {
      "DownloadUrl" : "https://j5.dfcfw.com/",
      "RequestUrl" : "https://api.dongcaibaoxian.com",
      "requestWhiteList" : [
        "https://api.dongcaibaoxian.com"
      ],
      "UploadUrl" : null,
      "uploadWhiteList" : [

      ],
      "downloadWhiteList" : [
        "https://j5.dfcfw.com"
      ]
    }
  },
  "resultCode" : 0,
  "resultMessage" : "成功"
}`,
              contentHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-detail-2-1639289160423403-103-265 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
p.p2-detail-2-1639289160423403-103-265 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
p.p3-detail-2-1639289160423403-103-265 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000; min-height: 17.9px}
span.s1-detail-2-1639289160423403-103-265 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px}
span.s2-detail-2-1639289160423403-103-265 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-detail-2-1639289160423403-103-265"><span class="s1-detail-2-1639289160423403-103-265">Response Data:<span class="Apple-converted-space">&nbsp;</span></span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265">{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; </span>"datas" : {</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>"outsideTestList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 158553,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "fix: &#x5B89;&#x5353;&#x4FA7;&#x6ED1;&#x8FD4;&#x56DE;&#x4FEE;&#x6539;",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "1.1.3",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "trial",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://j2.dfcfw.com/resource/uploadzip/63738435428532228213756853.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2020-10-16T08:57:09+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 607.84000000000003,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "f791df1ef79a0c38f84acddad7b84f17",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2020-10-16T15:17:42+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>}</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>"insideTestList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 12850,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "1.0.0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "develop",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://mptest.1234567.com.cn/PhpUpload/uploadzip/6369188836445762501763538281.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2019-04-26T15:12:45+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 0,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "dbaecab61ed575a48fcfec0e9b4733ed",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2019-04-26T15:12:45+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 158552,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "1",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "1",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "develop",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://j2.dfcfw.com/resource/uploadzip/6373843530850078251838441440.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2020-10-16T08:55:09+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 607.84000000000003,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "f1ce5fcf9332bdad5d1fbf9ca57d1a88",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2020-10-16T08:55:09+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 21814,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "1",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "develop",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://mptest.1234567.com.cn/PhpUpload/uploadzip/636966463634352500508397342.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2019-06-20T16:52:44+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 0,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "c250b152769761eb5bafef6924fa3a19",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2019-06-20T16:52:44+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 171325,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "111",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "11",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "develop",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://j2.dfcfw.com/resource/uploadzip/637438234639198919428464905.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2020-12-17T17:37:44+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 1711.97,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "2315f6985b042e87800f0589daad53f0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2020-12-17T17:37:44+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 79403,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "1",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "develop",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://mptest.1234567.com.cn/PhpUpload/uploadzip/6371658350128087501243178509.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2020-02-06T10:58:21+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 591.97000000000003,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "962d6f4321e29c5dc8e13671812a97ee",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2020-02-06T10:58:21+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>}</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>"AppletEntity" : {</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"WealthId" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"projectType" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"status" : 1,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"url" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"company" : "&#x5929;&#x5929;&#x5C0F;&#x7A0B;&#x5E8F;",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"companyNo" : "99fd97a920db491fbcaa3726ea0774ac",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"updateTime" : "2020-12-17T17:37:44+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"icon" : "https://j2.dfcfw.com/resource/uploadimg/86c9a39519d94df4a4e58199e741accd.png",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"appVersion" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"isOfficial" : 1,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"version" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"appName" : "&#x57FA;&#x91D1;FM",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"IsAllowCollect" : false,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"md5" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"CompanyBaseSetting" : {</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"DownloadUrl" : "https://j5.dfcfw.com/",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"RequestUrl" : "https://api.dongcaibaoxian.com",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"requestWhiteList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </span>"https://api.dongcaibaoxian.com"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"UploadUrl" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"uploadWhiteList" : [</span></p>
<p class="p3-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"></span><br></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"downloadWhiteList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </span>"https://j5.dfcfw.com"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>]</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"miniWhiteList" : {</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"uploadWhiteList" : [</span></p>
<p class="p3-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"></span><br></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"requestWhiteList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </span>"https://api.dongcaibaoxian.com"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"downloadWhiteList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </span>"https://j5.dfcfw.com"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>]</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"WealthName" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"WealthIcon" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"showType" : 1,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"description" : "&#x57FA;&#x91D1;&#x5E72;&#x8D27;&#x3001;&#x884C;&#x60C5;&#x89E3;&#x8BFB;&#xFF0C;&#x8DA3;&#x5473;&#x8F7B;&#x677E;&#x542C;&#x3002;"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>"productList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>{</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"id" : 158553,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"description" : "fix: &#x5B89;&#x5353;&#x4FA7;&#x6ED1;&#x8FD4;&#x56DE;&#x4FEE;&#x6539;",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"version" : "1.1.3",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"envVersion" : "release",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appId" : "4e11280eef6a4277aa855e98eb385bec",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"url" : "https://j2.fund.eastmoney.com/resource/uploadzip/63738435428532228213756853.zip",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userId" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"userName" : "",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"createTime" : "2020-10-16T15:17:42+08:00",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"packSize" : 607.84000000000003,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"appVersion" : "6.4.6",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"md5" : "f791df1ef79a0c38f84acddad7b84f17",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"tabBar" : "0",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"updateTime" : "2020-10-16T15:17:42+08:00"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>}</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>"CompanyBaseSetting" : {</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"DownloadUrl" : "https://j5.dfcfw.com/",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"RequestUrl" : "https://api.dongcaibaoxian.com",</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"requestWhiteList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"https://api.dongcaibaoxian.com"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"UploadUrl" : null,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"uploadWhiteList" : [</span></p>
<p class="p3-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"></span><br></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>],</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>"downloadWhiteList" : [</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; &nbsp; </span>"https://j5.dfcfw.com"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; &nbsp; </span>]</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; &nbsp; </span>}</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; </span>},</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; </span>"resultCode" : 0,</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265"><span class="Apple-converted-space">&nbsp; </span>"resultMessage" : "&#x6210;&#x529F;"</span></p>
<p class="p2-detail-2-1639289160423403-103-265"><span class="s2-detail-2-1639289160423403-103-265">}</span></p>
</body>
</html>`,
              selected: false,
            },
            {
              title: '请求头',
              content: `Request Headers: 
{
  "Content-Type" : "application/json"
}`,
              contentHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-detail-3-1639288107488959-69-710 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
p.p2-detail-3-1639288107488959-69-710 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
span.s1-detail-3-1639288107488959-69-710 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px}
span.s2-detail-3-1639288107488959-69-710 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-detail-3-1639288107488959-69-710"><span class="s1-detail-3-1639288107488959-69-710">Request Headers:<span class="Apple-converted-space">&nbsp;</span></span></p>
<p class="p2-detail-3-1639288107488959-69-710"><span class="s2-detail-3-1639288107488959-69-710">{</span></p>
<p class="p2-detail-3-1639288107488959-69-710"><span class="s2-detail-3-1639288107488959-69-710"><span class="Apple-converted-space">&nbsp; </span>"Content-Type" : "application/json"</span></p>
<p class="p2-detail-3-1639288107488959-69-710"><span class="s2-detail-3-1639288107488959-69-710">}</span></p>
</body>
</html>`,
              selected: false,
            },
            {
              title: '响应头',
              content: `Response Headers: 
{
  "Content-Type" : "application/json; charset=utf-8",
  "Access-Control-Allow-Origin" : "*",
  "X-AspNet-Version" : "4.0.30319",
  "Keep-Alive" : "timeout=5",
  "X-Powered-By" : "ASP.NET",
  "Server" : "Tengine",
  "Access-Control-Allow-Methods" : "GET, POST, PUT, DELETE, OPTIONS",
  "X-AspNetMvc-Version" : "5.2",
  "Access-Control-Allow-Headers" : "Content-Type,X-Requested-With",
  "Cache-Control" : "private",
  "Date" : "Sun, 12 Dec 2021 06:05:31 GMT",
  "Content-Length" : "4099",
  "Connection" : "keep-alive"
}`,
              contentHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-detail-4-1639288107504191-755-92 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
p.p2-detail-4-1639288107504191-755-92 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
span.s1-detail-4-1639288107504191-755-92 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px}
span.s2-detail-4-1639288107504191-755-92 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-detail-4-1639288107504191-755-92"><span class="s1-detail-4-1639288107504191-755-92">Response Headers:<span class="Apple-converted-space">&nbsp;</span></span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92">{</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Content-Type" : "application/json; charset=utf-8",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Access-Control-Allow-Origin" : "*",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"X-AspNet-Version" : "4.0.30319",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Keep-Alive" : "timeout=5",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"X-Powered-By" : "ASP.NET",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Server" : "Tengine",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Access-Control-Allow-Methods" : "GET, POST, PUT, DELETE, OPTIONS",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"X-AspNetMvc-Version" : "5.2",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Access-Control-Allow-Headers" : "Content-Type,X-Requested-With",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Cache-Control" : "private",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Date" : "Sun, 12 Dec 2021 05:48:27 GMT",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Content-Length" : "4099",</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92"><span class="Apple-converted-space">&nbsp; </span>"Connection" : "keep-alive"</span></p>
<p class="p2-detail-4-1639288107504191-755-92"><span class="s2-detail-4-1639288107504191-755-92">}</span></p>
</body>
</html>`,
              selected: false,
            },
            {
              title: '小程序',
              content: `小程序信息: 
{
  "appName" : "App",
  "appId" : "App",
  "path" : ""
}`,
              contentHtml: `<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1-detail-5-1639288107529343-888-946 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #0cc82e}
p.p2-detail-5-1639288107529343-888-946 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
span.s1-detail-5-1639288107529343-888-946 {font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px}
span.s2-detail-5-1639288107529343-888-946 {font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px}
</style>
</head>
<body>
<p class="p1-detail-5-1639288107529343-888-946"><span class="s1-detail-5-1639288107529343-888-946">&#x5C0F;&#x7A0B;&#x5E8F;&#x4FE1;&#x606F;:<span class="Apple-converted-space">&nbsp;</span></span></p>
<p class="p2-detail-5-1639288107529343-888-946"><span class="s2-detail-5-1639288107529343-888-946">{</span></p>
<p class="p2-detail-5-1639288107529343-888-946"><span class="s2-detail-5-1639288107529343-888-946"><span class="Apple-converted-space">&nbsp; </span>"appName" : "App",</span></p>
<p class="p2-detail-5-1639288107529343-888-946"><span class="s2-detail-5-1639288107529343-888-946"><span class="Apple-converted-space">&nbsp; </span>"appId" : "App",</span></p>
<p class="p2-detail-5-1639288107529343-888-946"><span class="s2-detail-5-1639288107529343-888-946"><span class="Apple-converted-space">&nbsp; </span>"path" : ""</span></p>
<p class="p2-detail-5-1639288107529343-888-946"><span class="s2-detail-5-1639288107529343-888-946">}</span></p>
</body>
</html>`,
              selected: false,
            },
          ],
          clickRow: (secItem) => {
            this.$refs.detail.reloadItems(secItem);
          },
          pasteboardCopy: (secItemTemp) => {
            this.copyToPasteboard(secItemTemp)
          }
        };
        // 追加数据
        this.addData("log-list", appItem, secItem);
    },
    addData(listId, appItem, secItem) {
      let listMap = null;
      const items = this.optionItems;
      items.forEach((el) => {
        if (el.listId == listId) {
          listMap = el;
        }
      });
      if (!listMap) return;

      // 追加到全局数据管理
      const appDataItem = DataTask.fetchAppDataItem(appItem);
      if (appDataItem) {
        secItem.appDataItem = appDataItem;
        DataTask.addAndCleanItems(
          listMap.itemsFunc(appDataItem),
          secItem,
          listMap.limitCount,
          listMap.removePercent
        );
        // console.log(DataTask.fetchAppDataItem(appItem).logItems);
        // console.log(DataTask.fetchAllAppDataItems());

        // 如果当前列表正在显示，刷新列表
        this.$refs.content.$refs[listId].addSecItem(
          secItem,
          listMap.limitCount,
          listMap.removePercent
        );
      }
    },
    copyToPasteboard(secItemTemp){
      const detailItems = secItemTemp.detailItems;
      let res = "";
      detailItems.forEach((element) => {
        res += "\n\n" + element.title + ":\n" + element.content;
      });
      // res = res.replace(/\\/g, '')
      // 使用yarn serve调试状态下  此api不可用
      navigator.clipboard.writeText(res).then(
        function () {
          /* clipboard successfully set */
        },
        function () {
          /* clipboard write failed */
        }
      );
      this.$refs.toastPop.show("复制成功");
    }
  },
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
