<template>
  <div class="content-wrap">
    <List></List>
    <Detail></Detail>
  </div>
</template>
<script>
import List from "../content/list.vue";
import Detail from "../content/detail.vue";
var vm = {
  name: "app",
  components: {
      List,
      Detail
  },
  props: {},
  data() {
    return {
      items: [],
    };
  },
  created() {
  },
  computed: {},
  mounted() {},
  methods: {
  },
};
export default vm;
</script>

<style lang="scss" scoped>
.content-wrap {
  margin: 40px 0px 0px 0px;
  padding: 0px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  justify-content: space-between;
  background-color: orange;
}
</style>
