<template>
</template>

<script>
export default {
  props: ['slot-key'],
  mounted () {
    // console.log(this.themeConfig)
    console.log(this.$site)
    // console.log(transformer)
    // console.log(lastUpdated)
      // this.$page.lastUpdated = '12313'
  }
};
</script>
