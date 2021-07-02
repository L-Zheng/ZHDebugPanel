<template>
  <div class="content">
    <!-- <List v-for="(item, idx) in items" :key="idx" :ref="item.listId"></List> -->
    <List ref="log-list"></List>
    <List ref="network-list"></List>
    <List ref="storage-list"></List>
    <List ref="memory-list"></List>
    <List ref="exception-list"></List>
    <List ref="im-list"></List>
    <List ref="sdkError-list"></List>
    <Detail ref="detail"></Detail>
    <ListOption></ListOption>
  </div>
</template>
<script>
import ListConfig from "../data/ListConfig.js";
import List from "../content/list.vue";
import Detail from "../content/detail.vue";
import ListOption from "../content/listOption.vue";
var vm = {
  name: "app",
  components: {
    List,
    Detail,
    ListOption
  },
  props: {},
  data() {
    return {
      items: []
    };
  },
  created() {
    this.items = ListConfig.fetchItems();
  },
  computed: {},
  mounted() {},
  methods: {
    showList(ref) {
      this.items.forEach(item => {
        const list = this.$refs[item.listId];
        if (list) {
          list.hide()
        }
      });
      this.$refs[ref].show();
    }
  }
};
export default vm;
</script>

<style lang="scss" scoped>
.content {
  margin: 40px 0px 0px 0px;
  padding: 0px;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  justify-content: space-between;
}
</style>
