<template>
  <div class="option">
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
      <span>{{ item.title }}</span>
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
      default: function() {
        return [];
      }
    }
  },
  data() {
    return {};
  },
  created() {},
  computed: {},
  mounted() {},
  methods: {
    clickTitle(item) {
      this.$emit("clickOptionItem", item)
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.option {
  position: fixed;
  top: 0px;
  left: 0px;
  width: 100%;
  height: 40px;
  margin: 0px;
  padding: 0px;
  background-color: #EFEFF4;
  overflow-x: auto;
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
  border-bottom: 1px solid #999;
}
.title-wrap {
  height: 100%;
  padding: 0px 5px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
</style>