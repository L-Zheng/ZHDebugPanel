<template>
  <div class="detail">
    <div class="option-wrap">
      <div
        class="title-wrap"
        v-for="(item, idx) in items"
        :key="idx"
        @click="clickIndex(idx)"
        :style="{
          color: item.selected ? '#0CC82E' : 'black',
        }"
      >
        <div>{{item.title}}</div>
      </div>
    </div>
    <span class="content">{{selectItem.content}}</span>
  </div>
</template>
<script>
import JSTool from "../base/JSTool.js";
var vm = {
  name: "app",
  components: {},
  props: {},
  data() {
    return {
      items: [],
      lastSelectIdx: 0,
      selectItem: {}
    };
  },
  created() {},
  computed: {},
  mounted() {},
  methods: {
    reloadItems(items) {
      if (!JSTool.isArray(items)) return;
      JSTool.debounce(() => {
        this.items = items;
        this.clickIndex(this.lastSelectIdx);
        this.$nextTick(() => {});
      }, 10);
    },
    clickIndex(index) {
      if (index >= this.items.length) {
        return;
      }
      this.items.forEach(el => {
        el.selected = false;
      });
      this.items[index].selected = true;
      this.lastSelectIdx = index;
      this.selectItem = this.items[index]
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.detail {
  margin: 0px;
  padding: 0px;
  position: fixed;
  right: 0px;
  top: 40px;
  width: 35%;
  height: 100%;
  // background-color: cyan;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  border: 1px solid #999;
}
.option-wrap {
  margin: 0px;
  padding: 0px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
  border-bottom: 1px solid #999;
  // background-color: cyan;
}
.title-wrap {
  height: 100%;
  margin: 5px 0px;
  padding: 0px 5px;
  // background-color: orange;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.content{
  margin: 5px;
}
</style>
