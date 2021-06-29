<template>
  <div class="detail-wrap">
  </div>
</template>
<script>
var vm = {
  name: "app",
  components: {
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
.detail-wrap {
  margin: 0px;
  padding: 0px;
  width: 40%;
  height: 150px;
  background-color: cyan;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
}
</style>
