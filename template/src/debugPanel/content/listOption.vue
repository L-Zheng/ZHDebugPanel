<template>
  <div class="list-option">
    <div
      class="title-wrap"
      v-for="(item, index) in items"
      :key="index"
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
      required: false,
      default: function() {
        return [
          {
            title: 'a',
            click: e => {

            }
          }
        ];
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
      item.click(item)
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.list-option {
  position: fixed;
  bottom: 0px;
  left: 0px;
  opacity: 0.5;
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
  border-top: 1px solid #999;
}
.title-wrap {
  height: 100%;
  padding: 0px 5px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
</style>