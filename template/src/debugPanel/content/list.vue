<template>
  <div class="list-wrap">
    <div class="content">
      <div
        class="row"
        v-for="(item, index) in items"
        :key="index"
        :id="'row-id-' + index"
        @click="clickTitle(item)"
      >
        <div>{{ item.title }}</div>
        <div class="row-line"></div>
      </div>
    </div>
  </div>
</template>
<script>
import ScrollOp from "../base/ScrollOp.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      items: []
    };
  },
  created() {
    this.startTimer();
  },
  computed: {},
  mounted() {},
  methods: {
    startTimer() {
      setInterval(() => {
        this.addItem({
          title: new Date().toString()
        });
      }, 1000);
    },
    addItem(item) {
      // 防抖与节流 
      // https://blog.csdn.net/zuorishu/article/details/93630578
      this.items.push(item);
      this.$nextTick(() => {
        const domId = "row-id-" + (this.items.length - 1);
        ScrollOp.scrollDomToBottomById(domId);
      });
    },
    clickTitle(item) {
      this.items.forEach(el => {
        el.selected = false;
      });
      item.selected = true;
      item.click(item);
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.list-wrap {
  margin: 0px;
  padding: 0px;
  width: 60%;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}
.content {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
}
.row {
  width: 100%;
  padding: 5px 0px 5px 5px;
}
.row-line {
  margin-top: 1px;
  height: 1px;
  width: 100%;
  background-color: orange;
}
</style>