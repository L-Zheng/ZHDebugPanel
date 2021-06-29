<template>
  <div class="wrap">
      <div
        class="title-wrap"
        v-for="(item, index) in items"
        :key="index"
        :style="{
          'background-color': item.selected ? 'white' : '',
          color: item.selected ? '#0CC82E' : 'black',
        }"
        @click="clickTitle(item)"
      >
        <div>{{ item.title }}</div>
      </div>
  </div>
</template>
<script>
var vm = {
  name: "app",
  components: {},
  props: {
    items: {
      type: Array,
      required: true,
      default: function () {
        return [];
      },
    },
  },
  data() {
    return {};
  },
  created() {},
  computed: {},
  mounted() {},
  methods: {
    clickTitle(item) {
      this.items.forEach((el) => {
        el.selected = false;
      });
      item.selected = true;
      item.click(item);
    },
  },
};
export default vm;
</script>


<style lang="scss" scoped>
.wrap {
  position: fixed;
  top: 0px;
  left: 0px;
  width: 100%;
  height: 40px;
  margin: 0px;
  padding: 0px;
  background-color: rgba(239, 239, 244, 1);
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
}
.title-wrap {
  height: 100%;
  padding: 0px 5px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
</style>