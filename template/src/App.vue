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
        // this.testRandomData()
        this.testNetworkData()
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
              contentHtml: `<span>描述${second}</span>`,
              selected: false,
            },
            {
              title: second,
              content: "描述" + second,
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
              useHtml: true,
              colItems: [
                {
                  title: "aa" + second,
                  titleHtml: `<body>        <p style=\"margin:0px;\">        <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?        </pre>        </p>        </body>        `,
                  percent: 0.7,
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: 'https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec',
                  titleHtml: `<body>        <p style=\"margin:0px;\">        <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        GET        </pre>        </p>        </body>        `,
                  percent: 0.15,
                  color: logTypeColor,
                  backgroundColor: "red",
                },
                {
                  title: page,
                  titleHtml: `<body>        <p style=\"margin:0px;\">        <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        200        </pre>        </p>        </body>        `,
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
              useHtml: true,
              contentHtml: `<body>    <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    URL:     </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    https://mp.1234567.com.cn/ConfigApplet/AppletApi/GetAppletPackageById?appId=4e11280eef6a4277aa855e98eb385bec    </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Method:     </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    GET    </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Status Code:     </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    200    </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Start Time:     </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    2021-12-18 22:49:15.460    </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    End Time:     </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    2021-12-18 22:49:16.188    </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Duration:     </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    728.383ms    </pre>    </p>    </body>`,
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
              useHtml: true,
              contentHtml: `<body>    <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Request Query (In URL):    </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">        </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    {\n  \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\"\n}    </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Request Query (In Body):    </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">        </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Request Query (In BodyStream):    </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">        </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>    </body>`,
              selected: false,
            },
            {
              title: '响应数据',
              content: `Response Data:\n{\n  \"datas\" : {\n    \"outsideTestList\" : [\n      {\n        \"id\" : 158553,\n        \"description\" : \"fix: \U5b89\U5353\U4fa7\U6ed1\U8fd4\U56de\U4fee\U6539\",\n        \"version\" : \"1.1.3\",\n        \"envVersion\" : \"trial\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/63738435428532228213756853.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T08:57:09+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : \"\",\n        \"md5\" : \"f791df1ef79a0c38f84acddad7b84f17\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T15:17:42+08:00\"\n      }\n    ],\n    \"insideTestList\" : [\n      {\n        \"id\" : 12850,\n        \"description\" : \"\",\n        \"version\" : \"1.0.0\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/6369188836445762501763538281.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2019-04-26T15:12:45+08:00\",\n        \"packSize\" : 0,\n        \"appVersion\" : null,\n        \"md5\" : \"dbaecab61ed575a48fcfec0e9b4733ed\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2019-04-26T15:12:45+08:00\"\n      },\n      {\n        \"id\" : 158552,\n        \"description\" : \"1\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/6373843530850078251838441440.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T08:55:09+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : null,\n        \"md5\" : \"f1ce5fcf9332bdad5d1fbf9ca57d1a88\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T08:55:09+08:00\"\n      },\n      {\n        \"id\" : 21814,\n        \"description\" : \"\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/636966463634352500508397342.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2019-06-20T16:52:44+08:00\",\n        \"packSize\" : 0,\n        \"appVersion\" : null,\n        \"md5\" : \"c250b152769761eb5bafef6924fa3a19\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2019-06-20T16:52:44+08:00\"\n      },\n      {\n        \"id\" : 171325,\n        \"description\" : \"111\",\n        \"version\" : \"11\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/637438234639198919428464905.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-12-17T17:37:44+08:00\",\n        \"packSize\" : 1711.97,\n        \"appVersion\" : null,\n        \"md5\" : \"2315f6985b042e87800f0589daad53f0\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-12-17T17:37:44+08:00\"\n      },\n      {\n        \"id\" : 79403,\n        \"description\" : \"\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/6371658350128087501243178509.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-02-06T10:58:21+08:00\",\n        \"packSize\" : 591.97000000000003,\n        \"appVersion\" : null,\n        \"md5\" : \"962d6f4321e29c5dc8e13671812a97ee\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-02-06T10:58:21+08:00\"\n      }\n    ],\n    \"AppletEntity\" : {\n      \"WealthId\" : null,\n      \"projectType\" : null,\n      \"status\" : 1,\n      \"url\" : null,\n      \"company\" : \"\U5929\U5929\U5c0f\U7a0b\U5e8f\",\n      \"companyNo\" : \"99fd97a920db491fbcaa3726ea0774ac\",\n      \"updateTime\" : \"2020-12-17T17:37:44+08:00\",\n      \"icon\" : \"https://j2.dfcfw.com/resource/uploadimg/86c9a39519d94df4a4e58199e741accd.png\",\n      \"appVersion\" : null,\n      \"isOfficial\" : 1,\n      \"version\" : null,\n      \"appName\" : \"\U57fa\U91d1FM\",\n      \"IsAllowCollect\" : false,\n      \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n      \"md5\" : null,\n      \"CompanyBaseSetting\" : {\n        \"DownloadUrl\" : \"https://j5.dfcfw.com/\",\n        \"RequestUrl\" : \"https://api.dongcaibaoxian.com\",\n        \"requestWhiteList\" : [\n          \"https://api.dongcaibaoxian.com\"\n        ],\n        \"UploadUrl\" : null,\n        \"uploadWhiteList\" : [\n\n        ],\n        \"downloadWhiteList\" : [\n          \"https://j5.dfcfw.com\"\n        ]\n      },\n      \"miniWhiteList\" : {\n        \"uploadWhiteList\" : [\n\n        ],\n        \"requestWhiteList\" : [\n          \"https://api.dongcaibaoxian.com\"\n        ],\n        \"downloadWhiteList\" : [\n          \"https://j5.dfcfw.com\"\n        ]\n      },\n      \"WealthName\" : null,\n      \"WealthIcon\" : null,\n      \"showType\" : 1,\n      \"description\" : \"\U57fa\U91d1\U5e72\U8d27\U3001\U884c\U60c5\U89e3\U8bfb\Uff0c\U8da3\U5473\U8f7b\U677e\U542c\U3002\"\n    },\n    \"productList\" : [\n      {\n        \"id\" : 158553,\n        \"description\" : \"fix: \U5b89\U5353\U4fa7\U6ed1\U8fd4\U56de\U4fee\U6539\",\n        \"version\" : \"1.1.3\",\n        \"envVersion\" : \"release\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.fund.eastmoney.com/resource/uploadzip/63738435428532228213756853.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T15:17:42+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : \"6.4.6\",\n        \"md5\" : \"f791df1ef79a0c38f84acddad7b84f17\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T15:17:42+08:00\"\n      }\n    ],\n    \"CompanyBaseSetting\" : {\n      \"DownloadUrl\" : \"https://j5.dfcfw.com/\",\n      \"RequestUrl\" : \"https://api.dongcaibaoxian.com\",\n      \"requestWhiteList\" : [\n        \"https://api.dongcaibaoxian.com\"\n      ],\n      \"UploadUrl\" : null,\n      \"uploadWhiteList\" : [\n\n      ],\n      \"downloadWhiteList\" : [\n        \"https://j5.dfcfw.com\"\n      ]\n    }\n  },\n  \"resultCode\" : 0,\n  \"resultMessage\" : \"\U6210\U529f\"\n}`,
              useHtml: true,
              contentHtml: `<p style=\"margin:0px;padding:0px;white-space: pre-wrap;white-space: -moz-pre-wrap;white-space: -pre-wrap;white-space: -o-pre-wrap;word-wrap: break-word;\"><span style=\"margin:0px;padding:0px;font-family: '.SFUI-Semibold'font-weight: bolder;font-style: normal;font-size: 15.00px;color: rgba(12.00, 200.00, 46.00, 1.00);\">Response Data:</span></p><pre style=\"margin:0px;padding:0px;font-family: '.SFUI-Regular'font-weight: normal;font-style: normal;font-size: 15.00px;color: rgba(0.00, 0.00, 0.00, 1.00);white-space: pre-wrap;white-space: -moz-pre-wrap;white-space: -pre-wrap;white-space: -o-pre-wrap;word-wrap: break-word;overflow-x: scroll;overflow-y: scroll;\">{\n  \"datas\" : {\n    \"outsideTestList\" : [\n      {\n        \"id\" : 158553,\n        \"description\" : \"fix: \U5b89\U5353\U4fa7\U6ed1\U8fd4\U56de\U4fee\U6539\",\n        \"version\" : \"1.1.3\",\n        \"envVersion\" : \"trial\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/63738435428532228213756853.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T08:57:09+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : \"\",\n        \"md5\" : \"f791df1ef79a0c38f84acddad7b84f17\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T15:17:42+08:00\"\n      }\n    ],\n    \"insideTestList\" : [\n      {\n        \"id\" : 12850,\n        \"description\" : \"\",\n        \"version\" : \"1.0.0\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/6369188836445762501763538281.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2019-04-26T15:12:45+08:00\",\n        \"packSize\" : 0,\n        \"appVersion\" : null,\n        \"md5\" : \"dbaecab61ed575a48fcfec0e9b4733ed\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2019-04-26T15:12:45+08:00\"\n      },\n      {\n        \"id\" : 158552,\n        \"description\" : \"1\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/6373843530850078251838441440.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T08:55:09+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : null,\n        \"md5\" : \"f1ce5fcf9332bdad5d1fbf9ca57d1a88\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T08:55:09+08:00\"\n      },\n      {\n        \"id\" : 21814,\n        \"description\" : \"\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/636966463634352500508397342.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2019-06-20T16:52:44+08:00\",\n        \"packSize\" : 0,\n        \"appVersion\" : null,\n        \"md5\" : \"c250b152769761eb5bafef6924fa3a19\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2019-06-20T16:52:44+08:00\"\n      },\n      {\n        \"id\" : 171325,\n        \"description\" : \"111\",\n        \"version\" : \"11\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.dfcfw.com/resource/uploadzip/637438234639198919428464905.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-12-17T17:37:44+08:00\",\n        \"packSize\" : 1711.97,\n        \"appVersion\" : null,\n        \"md5\" : \"2315f6985b042e87800f0589daad53f0\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-12-17T17:37:44+08:00\"\n      },\n      {\n        \"id\" : 79403,\n        \"description\" : \"\",\n        \"version\" : \"1\",\n        \"envVersion\" : \"develop\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://mptest.1234567.com.cn/PhpUpload/uploadzip/6371658350128087501243178509.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-02-06T10:58:21+08:00\",\n        \"packSize\" : 591.97000000000003,\n        \"appVersion\" : null,\n        \"md5\" : \"962d6f4321e29c5dc8e13671812a97ee\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-02-06T10:58:21+08:00\"\n      }\n    ],\n    \"AppletEntity\" : {\n      \"WealthId\" : null,\n      \"projectType\" : null,\n      \"status\" : 1,\n      \"url\" : null,\n      \"company\" : \"\U5929\U5929\U5c0f\U7a0b\U5e8f\",\n      \"companyNo\" : \"99fd97a920db491fbcaa3726ea0774ac\",\n      \"updateTime\" : \"2020-12-17T17:37:44+08:00\",\n      \"icon\" : \"https://j2.dfcfw.com/resource/uploadimg/86c9a39519d94df4a4e58199e741accd.png\",\n      \"appVersion\" : null,\n      \"isOfficial\" : 1,\n      \"version\" : null,\n      \"appName\" : \"\U57fa\U91d1FM\",\n      \"IsAllowCollect\" : false,\n      \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n      \"md5\" : null,\n      \"CompanyBaseSetting\" : {\n        \"DownloadUrl\" : \"https://j5.dfcfw.com/\",\n        \"RequestUrl\" : \"https://api.dongcaibaoxian.com\",\n        \"requestWhiteList\" : [\n          \"https://api.dongcaibaoxian.com\"\n        ],\n        \"UploadUrl\" : null,\n        \"uploadWhiteList\" : [\n\n        ],\n        \"downloadWhiteList\" : [\n          \"https://j5.dfcfw.com\"\n        ]\n      },\n      \"miniWhiteList\" : {\n        \"uploadWhiteList\" : [\n\n        ],\n        \"requestWhiteList\" : [\n          \"https://api.dongcaibaoxian.com\"\n        ],\n        \"downloadWhiteList\" : [\n          \"https://j5.dfcfw.com\"\n        ]\n      },\n      \"WealthName\" : null,\n      \"WealthIcon\" : null,\n      \"showType\" : 1,\n      \"description\" : \"\U57fa\U91d1\U5e72\U8d27\U3001\U884c\U60c5\U89e3\U8bfb\Uff0c\U8da3\U5473\U8f7b\U677e\U542c\U3002\"\n    },\n    \"productList\" : [\n      {\n        \"id\" : 158553,\n        \"description\" : \"fix: \U5b89\U5353\U4fa7\U6ed1\U8fd4\U56de\U4fee\U6539\",\n        \"version\" : \"1.1.3\",\n        \"envVersion\" : \"release\",\n        \"appId\" : \"4e11280eef6a4277aa855e98eb385bec\",\n        \"url\" : \"https://j2.fund.eastmoney.com/resource/uploadzip/63738435428532228213756853.zip\",\n        \"userId\" : \"\",\n        \"userName\" : \"\",\n        \"createTime\" : \"2020-10-16T15:17:42+08:00\",\n        \"packSize\" : 607.84000000000003,\n        \"appVersion\" : \"6.4.6\",\n        \"md5\" : \"f791df1ef79a0c38f84acddad7b84f17\",\n        \"tabBar\" : \"0\",\n        \"updateTime\" : \"2020-10-16T15:17:42+08:00\"\n      }\n    ],\n    \"CompanyBaseSetting\" : {\n      \"DownloadUrl\" : \"https://j5.dfcfw.com/\",\n      \"RequestUrl\" : \"https://api.dongcaibaoxian.com\",\n      \"requestWhiteList\" : [\n        \"https://api.dongcaibaoxian.com\"\n      ],\n      \"UploadUrl\" : null,\n      \"uploadWhiteList\" : [\n\n      ],\n      \"downloadWhiteList\" : [\n        \"https://j5.dfcfw.com\"\n      ]\n    }\n  },\n  \"resultCode\" : 0,\n  \"resultMessage\" : \"\U6210\U529f\"\n}</pre>`,
              selected: false,
            },
            {
              title: '请求头',
              content: `Request Headers: 
{
  "Content-Type" : "application/json"
}`,
              useHtml: true,
              contentHtml: `<body>    <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Request Headers:    </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">        </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    {\n  \"Content-Type\" : \"application/json\"\n}    </pre>    </p>    </body>`,
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
              useHtml: true,
              contentHtml: `<body>    <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    Response Headers:    </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">        </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    {\n  \"Content-Type\" : \"application/json; charset=utf-8\",\n  \"Access-Control-Allow-Origin\" : \"*\",\n  \"X-AspNet-Version\" : \"4.0.30319\",\n  \"Keep-Alive\" : \"timeout=5\",\n  \"X-Powered-By\" : \"ASP.NET\",\n  \"Server\" : \"Tengine\",\n  \"Access-Control-Allow-Methods\" : \"GET, POST, PUT, DELETE, OPTIONS\",\n  \"X-AspNetMvc-Version\" : \"5.2\",\n  \"Access-Control-Allow-Headers\" : \"Content-Type,X-Requested-With\",\n  \"Cache-Control\" : \"private\",\n  \"Date\" : \"Sat, 18 Dec 2021 14:49:21 GMT\",\n  \"Content-Length\" : \"4099\",\n  \"Connection\" : \"keep-alive\"\n}    </pre>    </p>    </body>`,
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
              useHtml: true,
              contentHtml: `<body>    <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">    \U5c0f\U7a0b\U5e8f\U4fe1\U606f:    </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">        </pre>    </p>        <p style=\"margin:0px;\">    <span style=\"font-family: '.SFUI-Semibold'; font-weight: bold; font-style: normal; font-size: 15.00px; color: #0CC82E;\">        </span>    <pre style=\"font-family: '.SFUI-Regular'; font-weight: normal; font-style: normal; font-size: 15.00px; color: #000000; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;\">    {\n  \"appName\" : \"App\",\n  \"appId\" : \"App\",\n  \"path\" : \"\"\n}    </pre>    </p>    </body>`,
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
